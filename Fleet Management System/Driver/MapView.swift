import SwiftUI
import MapKit
import CoreLocation
import UserNotifications

// MARK: - View Model
class MapViewModel: NSObject, ObservableObject {
    // Camera settings
    let navigationAltitude: Double = 800  // Navigation mode - closer view
    let normalAltitude: Double = 1200     // Normal mode - slightly zoomed out
    private let routeOverviewAltitude: Double = 2000  // Route overview - see the whole route
    let defaultPitch: Double = 0
    
    // Timers
    private var routeUpdateTimer: Timer?
    var navigationUpdateTimer: Timer?
    
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 28.6139, longitude: 77.2090),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @Published var mapType: MKMapType = .standard
    @Published var route: MKRoute?
    @Published var pickupRoute: MKRoute?
    @Published var isNavigating = false
    @Published var remainingDistance: Double = 0
    @Published var remainingTime: TimeInterval = 0
    @Published var estimatedArrivalTime: Date?
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var userHeading: Double = 0
    @Published var pickupDistance: Double = 0
    @Published var pickupTime: TimeInterval = 0
    @Published var currentTrip: Trip?
    @Published var isNearPickup: Bool = false
    @Published var nextManeuver: String = ""
    @Published var distanceToNextManeuver: Double = 0
    @Published var upcomingDirections: [(instruction: String, distance: Double)] = []
    @Published var nextDirectionAnnotation: NextDirectionAnnotation?
    @Published var hasReachedPickup: Bool = false
    @Published var hasReachedDestination: Bool = false
    @Published var isInNavigationMode: Bool = false
    @Published var currentStepIndex: Int = 0
    @Published var navigationAnnouncements: String = ""
    
    // Geofencing overlays
    @Published var pickupGeofenceOverlay: MKCircle?
    @Published var destinationGeofenceOverlay: MKCircle?
    private let geofenceRadius: Double = 100 // 100 meters radius for geofence
    
    private var locationManager: CLLocationManager?
    private var currentRoute: MKRoute?
    private var pickupRegion: CLCircularRegion?
    private var destinationRegion: CLCircularRegion?
    private let announcementThreshold: Double = 200 // meters
    private let rerounteThreshold: Double = 50 // meters
    
    @Published var showingPickupRoute: Bool = true
    
    // Camera control
    @Published var shouldUpdateCamera: Bool = false
    
    @Published var currentLocationAddress: String = "Current Location"
    @Published var pickupLocationAddress: String = ""
    @Published var destinationLocationAddress: String = ""
    
    private let geocoder = CLGeocoder()
    
    private let tripViewModel = IFEDataController.shared
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    override init() {
        super.init()
        setupNotificationHandler()
    }
    
    private func setupNotificationHandler() {
        notificationCenter.delegate = self
    }
    
    private func convertCoordinateToAddress(_ coordinate: CLLocationCoordinate2D, completion: @escaping (String) -> Void) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Reverse geocoding error: \(error.localizedDescription)")
                    completion("\(coordinate.latitude), \(coordinate.longitude)")
                    return
                }
                
                if let placemark = placemarks?.first {
                    let address = [
                        placemark.name,
                        placemark.thoroughfare,
                        placemark.subThoroughfare,
                        placemark.locality,
                        placemark.subLocality,
                        placemark.administrativeArea,
                        placemark.postalCode
                    ]
                        .compactMap { $0 }
                        .joined(separator: " ")
                    completion(address)
                } else {
                    completion("\(coordinate.latitude), \(coordinate.longitude)")
                }
            }
        }
    }
    
    func updateAddresses() {
        if let userLocation = userLocation {
            convertCoordinateToAddress(userLocation) { [weak self] address in
                self?.currentLocationAddress = address
            }
        }
        
        if let trip = currentTrip {
            let pickupCoordinates = parseCoordinates(trip.pickupLocation)
            convertCoordinateToAddress(pickupCoordinates) { [weak self] address in
                self?.pickupLocationAddress = address
            }
            
            let destinationCoordinates = parseCoordinates(trip.destination)
            convertCoordinateToAddress(destinationCoordinates) { [weak self] address in
                self?.destinationLocationAddress = address
            }
        }
    }
    
    func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.distanceFilter = 5 // Update location more frequently (every 5 meters)
        locationManager?.headingFilter = 5 // Update heading every 5 degrees
        locationManager?.requestWhenInUseAuthorization()
        locationManager?.startUpdatingLocation()
        locationManager?.startUpdatingHeading()
        
        // Request region monitoring authorization
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            locationManager?.requestAlwaysAuthorization()
            
            // Check if we have a current trip and setup geofencing
            if let trip = currentTrip {
                setupGeofencing(for: trip)
            }
        } else {
            print("Region monitoring is not available on this device")
            scheduleNotification(
                title: "Geofencing Unavailable",
                body: "Your device doesn't support geofencing. Some features may be limited."
            )
        }
        
        // Request notification permission
        requestNotificationPermission()
        
        // Start route update timer
        routeUpdateTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.updateRoutes()
        }
    }
    
    private func checkCurrentGeofenceStatus() {
        guard let locationManager = locationManager,
              let userLocation = userLocation else { return }
        
        print("Checking geofence status at location: \(userLocation)")
        
        // Check pickup region
        if let pickupRegion = pickupRegion {
            let isInPickup = pickupRegion.contains(userLocation)
            print("Is in pickup region: \(isInPickup)")
            if isInPickup != hasReachedPickup {
                DispatchQueue.main.async {
                    self.hasReachedPickup = isInPickup
                    if isInPickup {
                        self.scheduleNotification(
                            title: "Arrived at Pickup",
                            body: "You have reached the pickup location. You can start navigation.",
                            sound: true
                        )
                        print("User entered pickup region")
                    } else {
                        self.scheduleNotification(
                            title: "Left Pickup Location",
                            body: "You have left the pickup location. Please return to start navigation.",
                            sound: true
                        )
                        print("User left pickup region")
                    }
                }
            }
        }
        
        // Check destination region
        if let destinationRegion = destinationRegion {
            let isInDestination = destinationRegion.contains(userLocation)
            print("Is in destination region: \(isInDestination)")
            if isInDestination != hasReachedDestination {
                DispatchQueue.main.async {
                    self.hasReachedDestination = isInDestination
                    if isInDestination {
                        self.scheduleNotification(
                            title: "Arrived at Destination",
                            body: "You have reached the destination. You can end navigation.",
                            sound: true
                        )
                        print("User entered destination region")
                    } else {
                        self.scheduleNotification(
                            title: "Left Destination",
                            body: "You have left the destination area. Please return to complete the trip.",
                            sound: true
                        )
                        print("User left destination region")
                    }
                }
            }
        }
    }
    
    private func updateRoutes() {
        guard let trip = currentTrip else { return }
        calculateRoute(for: trip)
        calculateRouteToPickup(for: trip)
    }
    
    func setCurrentTrip(_ trip: Trip) {
        currentTrip = trip
        updateRoutes()
        setupGeofencing(for: trip)
        updateAddresses()
    }
    
    deinit {
        routeUpdateTimer?.invalidate()
        navigationUpdateTimer?.invalidate()
    }
    
    func centerOnUserLocation() {
        guard let location = userLocation else { return }
        
        shouldUpdateCamera = true
        
        // Use camera-based centering instead of region
        let camera = MKMapCamera()
        camera.centerCoordinate = location
        camera.pitch = defaultPitch
        camera.altitude = isNavigating ? navigationAltitude : normalAltitude
        camera.heading = isNavigating ? userHeading : 0
        
        // Notify view to update camera
        objectWillChange.send()
        
        // Reset the flag after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.shouldUpdateCamera = false
        }
    }
    
    func calculateRoute(for trip: Trip) {
        let request = MKDirections.Request()
        request.source = MKMapItem.forCurrentLocation()
        
        let destinationPlacemark = MKPlacemark(coordinate: parseCoordinates(trip.destination))
        request.destination = MKMapItem(placemark: destinationPlacemark)
        
        let directions = MKDirections(request: request)
        directions.calculate { [weak self] response, error in
            guard let self = self,
                  let route = response?.routes.first else {
                print("Failed to calculate route: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            DispatchQueue.main.async {
                self.route = route
                self.currentRoute = route
                self.currentStepIndex = 0
                self.updateNextManeuver()
                
                // Don't automatically zoom to show entire route
                // Let the user control the view with centerOnUserLocation
                if let location = self.userLocation {
                    self.centerOnUserLocation()
                }
            }
        }
    }
    
    func calculateRouteToPickup(for trip: Trip) {
        guard let userLocation = userLocation else { return }
        let pickupCoordinates = parseCoordinates(trip.pickupLocation)
        
        // Safety check for valid coordinates
        guard pickupCoordinates.latitude != 0 && pickupCoordinates.longitude != 0 else {
            print("Invalid pickup coordinates")
            return
        }
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: pickupCoordinates))
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        directions.calculate { [weak self] response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error calculating pickup route: \(error.localizedDescription)")
                return
            }
            
            if let route = response?.routes.first {
                DispatchQueue.main.async {
                    self.pickupRoute = route
                    self.pickupDistance = route.distance
                    self.pickupTime = route.expectedTravelTime
                    self.showingPickupRoute = true
                }
            }
        }
    }
    
    func startNavigation() {
        isNavigating = true
        isInNavigationMode = true
        currentStepIndex = 0
        showingPickupRoute = false
        
        // Recalculate route from current location to destination
        if let trip = currentTrip {
            calculateRouteToDestination(from: userLocation!, for: trip)
        }
        
        centerOnUserLocation()
        
        // Invalidate existing timer if any
        navigationUpdateTimer?.invalidate()
        
        // Start frequent navigation updates
        navigationUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateNavigationState()
        }
    }
    
    func calculateRouteToDestination(from source: CLLocationCoordinate2D, for trip: Trip) {
        let destinationCoordinates = parseCoordinates(trip.destination)
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: source))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destinationCoordinates))
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        directions.calculate { [weak self] response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error calculating route: \(error.localizedDescription)")
                return
            }
            
            if let route = response?.routes.first {
                DispatchQueue.main.async {
                    self.route = route
                    self.currentRoute = route
                    self.currentStepIndex = 0
                    self.updateNextManeuver()
                }
            }
        }
    }
    
    func stopNavigation() {
        guard hasReachedDestination else {
            scheduleNotification(
                title: "Cannot End Navigation",
                body: "You must be within the destination area to end navigation"
            )
            return
        }
        
        // Clean up map and stop navigation
        cleanupMap()
        isNavigating = false
        isInNavigationMode = false
        navigationUpdateTimer?.invalidate()
        navigationUpdateTimer = nil
        
        // Post notification to show post-trip inspection
        NotificationCenter.default.post(
            name: NSNotification.Name("ShowPostTripInspection"),
            object: nil,
            userInfo: ["trip": currentTrip as Any]
        )
    }
    
    private func updateNavigationState() {
        guard let route = currentRoute,
              let userLocation = userLocation else { return }
        
        let userPoint = MKMapPoint(userLocation)
        
        // Check if we need to recalculate route (off route)
        if checkIfRerouteNeeded(userPoint: userPoint) {
            updateRoutes()
            return
        }
        
        // Update current step and next maneuver
        updateCurrentNavigationStep(userPoint: userPoint)
        
        // Check if announcement needed
        checkAndPrepareAnnouncement()
    }
    
    private func checkIfRerouteNeeded(userPoint: MKMapPoint) -> Bool {
        guard let route = currentRoute else { return false }
        
        // Find closest point on route
        var closestDistance = Double.infinity
        let points = route.polyline.points()
        let pointCount = route.polyline.pointCount
        
        for i in 0..<pointCount {
            let routePoint = points[i]
            let distance = routePoint.distance(to: userPoint)
            if distance < closestDistance {
                closestDistance = distance
            }
        }
        
        return closestDistance > rerounteThreshold
    }
    
    private func updateCurrentNavigationStep(userPoint: MKMapPoint) {
        guard let route = currentRoute else { return }
        
        var minDistance = Double.infinity
        var closestStepIndex = currentStepIndex
        
        // Find the closest step
        for (index, step) in route.steps.enumerated() {
            if index < currentStepIndex { continue }
            
            let stepPoints = step.polyline.points()
            let stepPointCount = step.polyline.pointCount
            
            guard stepPointCount > 0 else { continue }
            
            let distance = stepPoints[0].distance(to: userPoint)
            if distance < minDistance {
                minDistance = distance
                closestStepIndex = index
            }
        }
        
        if closestStepIndex != currentStepIndex {
            currentStepIndex = closestStepIndex
            updateNextManeuver()
        }
    }
    
    private func checkAndPrepareAnnouncement() {
        guard let route = currentRoute,
              currentStepIndex < route.steps.count else { return }
        
        let currentStep = route.steps[currentStepIndex]
        
        if distanceToNextManeuver <= announcementThreshold {
            let announcement = "\(currentStep.instructions) in \(Int(distanceToNextManeuver)) meters"
            if announcement != navigationAnnouncements {
                navigationAnnouncements = announcement
                // Here you could integrate text-to-speech if desired
                print("Navigation announcement: \(announcement)")
            }
        }
    }
    
    private func updateNextManeuver() {
        guard let route = currentRoute,
              let userLocation = userLocation,
              currentStepIndex < route.steps.count else { return }
        
        let currentStep = route.steps[currentStepIndex]
        let userPoint = MKMapPoint(userLocation)
        
        // Calculate distance to the start of current step
        let stepPoints = currentStep.polyline.points()
        let stepPointCount = currentStep.polyline.pointCount
        
        guard stepPointCount > 0 else { return }
        
        let distance = stepPoints[0].distance(to: userPoint)
        
        // Check if we've passed the current maneuver
        if distance < 20 && currentStepIndex + 1 < route.steps.count { // 20 meters threshold
            // Move to next step
            currentStepIndex += 1
            let nextStep = route.steps[currentStepIndex]
            
            DispatchQueue.main.async {
                // Update the maneuver info
                self.nextManeuver = nextStep.instructions
                self.distanceToNextManeuver = nextStep.polyline.points()[0].distance(to: userPoint)
                
                // Update the next direction annotation
                self.nextDirectionAnnotation = NextDirectionAnnotation(
                    coordinate: nextStep.polyline.points()[0].coordinate,
                    title: "Next Turn",
                    subtitle: "\(nextStep.instructions) in \(Int(self.distanceToNextManeuver))m"
                )
            }
        } else {
            DispatchQueue.main.async {
                self.nextManeuver = currentStep.instructions
                self.distanceToNextManeuver = distance
                
                // Update the next direction annotation
                self.nextDirectionAnnotation = NextDirectionAnnotation(
                    coordinate: stepPoints[0].coordinate,
                    title: "Next Turn",
                    subtitle: "\(currentStep.instructions) in \(Int(distance))m"
                )
            }
        }
    }
    
    private func parseCoordinates(_ locationString: String) -> CLLocationCoordinate2D {
        let components = locationString.split(separator: ",").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
        guard components.count == 2 else {
            return CLLocationCoordinate2D(latitude: 0, longitude: 0)
        }
        return CLLocationCoordinate2D(latitude: components[0], longitude: components[1])
    }
    
    private func updateNavigationMetrics(route: MKRoute) {
        // Safety check for valid route
        guard route.distance > 0 && route.expectedTravelTime > 0 else { return }
        
        remainingDistance = route.distance
        remainingTime = route.expectedTravelTime
        estimatedArrivalTime = Date().addingTimeInterval(route.expectedTravelTime)
    }
    
    private func setupGeofencing(for trip: Trip) {
        // Remove existing regions if any
        if let locationManager = locationManager {
            locationManager.monitoredRegions.forEach { locationManager.stopMonitoring(for: $0) }
        }
        
        // Create pickup region
        let pickupCoordinates = parseCoordinates(trip.pickupLocation)
        print("Setting up pickup geofence at coordinates: \(pickupCoordinates)")
        pickupRegion = CLCircularRegion(
            center: pickupCoordinates,
            radius: geofenceRadius,
            identifier: "pickup_\(trip.tripID)"
        )
        pickupRegion?.notifyOnEntry = true
        pickupRegion?.notifyOnExit = true
        
        // Create destination region
        let destinationCoordinates = parseCoordinates(trip.destination)
        print("Setting up destination geofence at coordinates: \(destinationCoordinates)")
        destinationRegion = CLCircularRegion(
            center: destinationCoordinates,
            radius: geofenceRadius,
            identifier: "destination_\(trip.tripID)"
        )
        destinationRegion?.notifyOnEntry = true
        destinationRegion?.notifyOnExit = true
        
        // Create circle overlays for visualization
        DispatchQueue.main.async {
            print("Creating geofence circle overlays")
            self.pickupGeofenceOverlay = MKCircle(center: pickupCoordinates, radius: self.geofenceRadius)
            self.destinationGeofenceOverlay = MKCircle(center: destinationCoordinates, radius: self.geofenceRadius)
            print("Geofence circle overlays created")
        }
        
        // Start monitoring regions if available
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            if let pickupRegion = pickupRegion {
                locationManager?.startMonitoring(for: pickupRegion)
                print("Started monitoring pickup region")
            }
            if let destinationRegion = destinationRegion {
                locationManager?.startMonitoring(for: destinationRegion)
                print("Started monitoring destination region")
            }
        } else {
            print("Region monitoring is not available on this device")
            scheduleNotification(
                title: "Geofencing Unavailable",
                body: "Your device doesn't support geofencing. Some features may be limited."
            )
        }
    }
    
    func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        
        // First, remove any existing notification categories
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
        
        // Create notification category with actions
        let startNavigationAction = UNNotificationAction(
            identifier: "START_NAVIGATION",
            title: "Start Navigation",
            options: .foreground
        )
        
        let endNavigationAction = UNNotificationAction(
            identifier: "END_NAVIGATION",
            title: "End Navigation",
            options: .foreground
        )
        
        let category = UNNotificationCategory(
            identifier: "GEOFENCE_NOTIFICATION",
            actions: [startNavigationAction, endNavigationAction],
            intentIdentifiers: [],
            options: []
        )
        
        center.setNotificationCategories([category])
        
        // Request authorization
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Error requesting notification permission: \(error.localizedDescription)")
            } else {
                print("Notification permission denied")
            }
        }
    }
    
    func scheduleNotification(title: String, body: String, sound: Bool = true) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = sound ? .default : nil
        content.badge = 1
        
        // Add category identifier for handling notification actions
        content.categoryIdentifier = "GEOFENCE_NOTIFICATION"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Notification scheduled successfully")
            }
        }
    }
    
    func cleanupMap() {
        // Clean up map
        route = nil
        pickupRoute = nil
        pickupGeofenceOverlay = nil
        destinationGeofenceOverlay = nil
        currentRoute = nil
        isNavigating = false
        isInNavigationMode = false
        currentTrip = nil
        hasReachedPickup = false
        hasReachedDestination = false
        currentStepIndex = 0
        navigationAnnouncements = ""
        upcomingDirections = []
        nextDirectionAnnotation = nil
        remainingDistance = 0
        remainingTime = 0
        estimatedArrivalTime = nil
        pickupDistance = 0
        pickupTime = 0
        nextManeuver = ""
        distanceToNextManeuver = 0
        showingPickupRoute = true
        
        // Stop location updates
        locationManager?.stopUpdatingLocation()
        locationManager?.stopUpdatingHeading()
        
        // Invalidate timers
        routeUpdateTimer?.invalidate()
        navigationUpdateTimer?.invalidate()
        
        // Post notification to dismiss the navigation info card
        NotificationCenter.default.post(
            name: NSNotification.Name("DismissNavigationInfoCard"),
            object: nil
        )
    }
}

// MARK: - Location Manager Delegate
extension MapViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        print("Location updated: \(location.coordinate)")
        
        DispatchQueue.main.async {
            self.userLocation = location.coordinate
            
            // Always check geofence status on location update
            self.checkCurrentGeofenceStatus()
            
            // Update current location address using reverse geocoding
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Reverse geocoding error: \(error.localizedDescription)")
                        self?.currentLocationAddress = "Current Location"
                        return
                    }
                    
                    if let placemark = placemarks?.first {
                        let address = [
                            placemark.name,
                            placemark.thoroughfare,
                            placemark.subThoroughfare,
                            placemark.locality,
                            placemark.subLocality,
                            placemark.administrativeArea,
                            placemark.postalCode
                        ]
                            .compactMap { $0 }
                            .joined(separator: " ")
                        self?.currentLocationAddress = address
                    } else {
                        self?.currentLocationAddress = "Current Location"
                    }
                }
            }
            
            // Update user heading if we have course information
            if location.course >= 0 {
                self.userHeading = location.course
            }
            
            // Only update navigation info if we're navigating
            if self.isNavigating {
                self.updateNextManeuver()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        DispatchQueue.main.async {
            self.userHeading = newHeading.trueHeading
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager error: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let circularRegion = region as? CLCircularRegion else { return }
        
        DispatchQueue.main.async {
            if circularRegion.identifier.starts(with: "pickup") {
                self.hasReachedPickup = true
                self.scheduleNotification(
                    title: "Arrived at Pickup",
                    body: "You have reached the pickup location. You can now start navigation.",
                    sound: true
                )
                print("Driver has reached pickup location")
            } else if circularRegion.identifier.starts(with: "destination") {
                self.hasReachedDestination = true
                self.scheduleNotification(
                    title: "Arrived at Destination",
                    body: "You have reached the destination. You can now end navigation.",
                    sound: true
                )
                print("Driver has reached destination")
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        guard let circularRegion = region as? CLCircularRegion else { return }
        
        DispatchQueue.main.async {
            if circularRegion.identifier.starts(with: "pickup") {
                self.hasReachedPickup = false
                self.scheduleNotification(
                    title: "Left Pickup Location",
                    body: "You have left the pickup location. Please return to start navigation.",
                    sound: true
                )
                print("Driver has left pickup location")
            } else if circularRegion.identifier.starts(with: "destination") {
                self.hasReachedDestination = false
                self.scheduleNotification(
                    title: "Left Destination",
                    body: "You have left the destination area. Please return to complete the trip.",
                    sound: true
                )
                print("Driver has left destination")
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("Region monitoring failed: \(error.localizedDescription)")
        self.scheduleNotification(
            title: "Geofencing Error",
            body: "Failed to monitor location: \(error.localizedDescription). Please check your location settings.",
            sound: true
        )
    }
}

// MARK: - Map View
struct MapView: View {
    @StateObject var viewModel = MapViewModel()
    @StateObject private var tripViewModel = IFEDataController.shared
    @Binding var selectedTab: Int
    @Environment(\.dismiss) private var dismiss
    @State private var cardOffset: CGFloat = 100
    @State private var cardExpanded: Bool = true
    @State private var preInspectionCompletedTrips: Set<UUID> = []
    @State private var tripsRequiringMaintenance: Set<UUID> = []
    @State private var showingTripOverview = false
    @State private var selectedTrip: Trip?
    @State private var showingPostTripInspection = false
    @State private var showNavigationInfoCard = true
    @State private var hasCompletedPreInspection = false
    @State private var vehicleStatusTimer: Timer?
    @State private var vehicle: Vehicle?
    
    // Add constants for card positions
    private let expandedOffset: CGFloat = 90
    private let minimizedOffset: CGFloat = 200
    private let tabBarHeight: CGFloat = 49
    private let bottomSafeArea: CGFloat = UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0
    
    var activeTrip: Trip? {
        tripViewModel.tripsForDriver.first { trip in
            trip.status == .inProgress || 
            (preInspectionCompletedTrips.contains(trip.id) && 
             trip.status == .scheduled && 
             !tripsRequiringMaintenance.contains(trip.id))
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                MapViewRepresentable(viewModel: viewModel)
                    .edgesIgnoringSafeArea(.all)
                
                // Turn by turn view at the top
                if viewModel.isNavigating {
                    TurnByTurnView(viewModel: viewModel)
                }
                
                // Map Controls
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            viewModel.centerOnUserLocation()
                        }) {
                            Image(systemName: "location.circle.fill")
                                .font(.title)
                                .foregroundColor(.primaryGradientStart)
                                .padding()
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(radius: 3)
                        }
                        
                        Button(action: {
                            switch viewModel.mapType {
                            case .standard:
                                viewModel.mapType = .satellite
                            case .satellite:
                                viewModel.mapType = .hybrid
                            case .hybrid:
                                viewModel.mapType = .standard
                            default:
                                viewModel.mapType = .standard
                            }
                        }) {
                            Image(systemName: "map")
                                .font(.title)
                                .foregroundColor(.primaryGradientStart)
                                .padding()
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(radius: 3)
                        }
                    }
                    .padding()
                    
                    Spacer()
                }
                
                // Navigation Info Card
                if let trip = activeTrip, showNavigationInfoCard {
                    VStack(spacing: 0) {
                        // Handle bar and controls
                        HStack {
                            Button(action: {
                                withAnimation(.spring()) {
                                    cardExpanded.toggle()
                                    cardOffset = cardExpanded ? expandedOffset : minimizedOffset
                                }
                            }) {
                                Image(systemName: cardExpanded ? "chevron.down" : "chevron.up")
                                    .font(.title3)
                                    .foregroundColor(.gray)
                                    .padding(8)
                                    .background(Color.white)
                                    .clipShape(Circle())
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        
                        NavigationInfoCard(
                            trip: trip,
                            viewModel: viewModel,
                            showingPostTripInspection: $showingPostTripInspection,
                            hasCompletedPreInspection: $hasCompletedPreInspection
                        )
                    }
                    .background(Color.white)
                    .cornerRadius(20, corners: [.topLeft, .topRight])
                    .shadow(radius: 5)
                    .offset(y: cardOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newOffset = cardOffset + value.translation.height
                                if newOffset >= expandedOffset && newOffset <= minimizedOffset {
                                    cardOffset = newOffset
                                }
                            }
                            .onEnded { value in
                                withAnimation(.spring()) {
                                    if value.translation.height > 50 {
                                        cardExpanded = false
                                        cardOffset = minimizedOffset
                                    } else if value.translation.height < -50 {
                                        cardExpanded = true
                                        cardOffset = expandedOffset
                                    } else {
                                        cardOffset = cardExpanded ? expandedOffset : minimizedOffset
                                    }
                                }
                            }
                    )
                } else {
                    EmptyTripCard(selectedTab: $selectedTab)
                        .padding()
                        .padding(.bottom, bottomSafeArea)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "xmark")
                                .foregroundColor(.primaryGradientStart)
                        }
                        .font(.subheadline)
                        .padding(8)
                        .background(Color.white)
                        .cornerRadius(16)
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $showingTripOverview) {
            if let trip = selectedTrip {
                TripOverviewView(
                    task: trip,
                    selectedTab: $selectedTab,
                    isInDestinationGeofence: viewModel.hasReachedDestination
                )
            }
        }
        .sheet(isPresented: $showingPostTripInspection) {
            if let trip = activeTrip {
                PostTripInspectionChecklistView(trip: trip) { inspectionItems, note in
                    let hasAnyFailure = inspectionItems.values.contains(false)
                    
                    // Handle post-trip inspection completion
                    IFEDataController.shared.addPostTripInspectionForTrip(
                        by: trip.id,
                        inspection: inspectionItems,
                        note: note
                    )
                    
                    if hasAnyFailure {
                        Task {
                            // Assign maintenance task
                            await assignMaintenanceTaskForFailedItems(
                                inspectionItems: inspectionItems,
                                note: note,
                                trip: trip,
                                isPreTrip: false
                            )
                            
                            // Update vehicle status
                            if let vehicle = await IFEDataController.shared.getRegisteredVehicle(by: trip.assignedVehicleID) {
                                self.vehicle = vehicle
                            }
                        }
                    }
                    
                    // Dismiss both sheets
                    showingPostTripInspection = false
                    dismiss()
                }
            }
        }
        .onAppear {
            viewModel.setupLocationManager()
            if let trip = activeTrip {
                viewModel.setCurrentTrip(trip)
                checkPreInspectionStatus(for: trip)
            }
            
            // Start vehicle status monitoring
            startVehicleStatusMonitoring()
            
            // Add notification observer for dismissing navigation info card
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("DismissNavigationInfoCard"),
                object: nil,
                queue: .main
            ) { _ in
                withAnimation {
                    showNavigationInfoCard = false
                }
            }
        }
        .onDisappear {
            // Stop vehicle status monitoring
            stopVehicleStatusMonitoring()
            
            // Remove notification observer
            NotificationCenter.default.removeObserver(
                self,
                name: NSNotification.Name("DismissNavigationInfoCard"),
                object: nil
            )
        }
        .task {
            await checkPreInspections()
        }
    }
    
    private func startVehicleStatusMonitoring() {
        // Create a timer that checks vehicle status every 5 seconds
        vehicleStatusTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            Task {
                await checkVehicleStatus()
            }
        }
    }
    
    private func stopVehicleStatusMonitoring() {
        vehicleStatusTimer?.invalidate()
        vehicleStatusTimer = nil
    }
    
    private func checkVehicleStatus() async {
        guard let trip = activeTrip else { return }
        
        if let vehicle = await IFEDataController.shared.getRegisteredVehicle(by: trip.assignedVehicleID) {
            self.vehicle = vehicle
            
            if vehicle.status == .assigned {
                // Vehicle is back to assigned status, remove from maintenance set
                DispatchQueue.main.async {
                    tripsRequiringMaintenance.remove(trip.id)
                    
                    // Only start navigation if pre-trip inspection is complete and not already navigating
                    if hasCompletedPreInspection && !viewModel.isNavigating {
                        viewModel.startNavigation()
                        if let userLocation = viewModel.userLocation {
                            viewModel.calculateRouteToDestination(from: userLocation, for: trip)
                        }
                    }
                }
            } else if vehicle.status == .underMaintenance {
                // Vehicle is under maintenance, add to maintenance set
                DispatchQueue.main.async {
                    tripsRequiringMaintenance.insert(trip.id)
                }
            }
        }
    }
    
    private func checkPreInspectionStatus(for trip: Trip) {
        Task {
            if let inspection = await IFEDataController.shared.getTripInspectionForTrip(by: trip.id) {
                hasCompletedPreInspection = !inspection.preInspection.isEmpty
                if hasCompletedPreInspection {
                    // Check if vehicle is under maintenance
                    if let vehicle = await IFEDataController.shared.getRegisteredVehicle(by: trip.assignedVehicleID) {
                        self.vehicle = vehicle
                        if vehicle.status == .underMaintenance {
                            tripsRequiringMaintenance.insert(trip.id)
                        } else {
                            // Start navigation immediately if pre-inspection is completed and vehicle is not under maintenance
                            viewModel.startNavigation()
                            if let userLocation = viewModel.userLocation {
                                viewModel.calculateRouteToDestination(from: userLocation, for: trip)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func checkPreInspections() async {
        for trip in tripViewModel.tripsForDriver {
            if let inspection = await IFEDataController.shared.getTripInspectionForTrip(by: trip.id) {
                let hasAnyFailure = inspection.preInspection.values.contains(false)
                let hasCompletedPreInspection = !inspection.preInspection.isEmpty
                
                if hasCompletedPreInspection {
                    preInspectionCompletedTrips.insert(trip.id)
                    if hasAnyFailure {
                        tripsRequiringMaintenance.insert(trip.id)
                    }
                }
            }
        }
    }
    
    private func assignMaintenanceTaskForFailedItems(inspectionItems: [TripInspectionItem: Bool], note: String, trip: Trip, isPreTrip: Bool) async {
        // Filter failed items
        let failedItems = inspectionItems.filter { !$0.value }
        guard !failedItems.isEmpty else { return }
        
        // Create issue note using TripInspection.issueDescription
        let issueDescriptions = failedItems.map { item in
            "\(item.key.rawValue): \(TripInspection.issueDescription[item.key] ?? "Issue detected.")"
        }.joined(separator: "\n")
        
        let inspectionType = isPreTrip ? "Pre-Trip" : "Post-Trip"
        let fullIssueNote = "\(inspectionType) Inspection Failures:\n\(issueDescriptions)\n\nAdditional Note: \(note)"
        
        // Get the vehicle's current coordinate
        guard let vehicle = await IFEDataController.shared.getRegisteredVehicle(by: trip.assignedVehicleID) else {
            print("Failed to fetch vehicle for maintenance task assignment")
            return
        }
        
        // Find the nearest service center
        guard let nearestServiceCenter = await findNearestServiceCenter(to: vehicle.currentCoordinate) else {
            print("No available service center found")
            return
        }
        
        // Debug: Log service center details
        print("Nearest Service Center ID: \(nearestServiceCenter.id)")
        
        // Fetch the maintenance personnel metadata for this service center
        guard let personnelMetaData = await IFEDataController.shared.getMaintenancePersonnelMetaData(ofCenter: nearestServiceCenter.id) else {
            print("No maintenance personnel metadata found for service center \(nearestServiceCenter.id)")
            return
        }
        
        // Verify active status
        guard personnelMetaData.activeStatus else {
            print("Maintenance personnel for service center \(nearestServiceCenter.id) is inactive (ID: \(personnelMetaData.id))")
            return
        }
        
        // Debug: Log personnel details
        print("Assigned Personnel: ID: \(personnelMetaData.id), Name: \(personnelMetaData.fullName), Active: \(personnelMetaData.activeStatus)")
        
        // Assign the maintenance task
        let assignedBy = IFEDataController.shared.user?.id ?? trip.assignedByFleetManagerID
        guard let task = await IFEDataController.shared.assignNewMaintenanceTask(
            by: assignedBy,
            to: personnelMetaData.id,
            for: trip.assignedVehicleID,
            ofType: isPreTrip ? .preInspectionMaintenance : .postInspectionMaintenance,
            fullIssueNote
        ) else {
            print("Failed to assign maintenance task")
            return
        }
        
        print("Maintenance task assigned: \(task)")
    }
    
    private func findNearestServiceCenter(to coordinate: String) async -> ServiceCenter? {
        let components = coordinate.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
        guard components.count == 2,
              let latitude = Double(components[0]),
              let longitude = Double(components[1]) else {
            print("Invalid vehicle coordinate format")
            return nil
        }
        
        let vehicleLocation = CLLocation(latitude: latitude, longitude: longitude)
        let serviceCenters = IFEDataController.shared.serviceCenters
        
        var nearestServiceCenter: ServiceCenter?
        var shortestDistance: CLLocationDistance = .greatestFiniteMagnitude
        
        for center in serviceCenters {
            guard let centerCoords = parseCoordinates(center.coordinate) else {
                continue
            }
            
            let centerLocation = CLLocation(latitude: centerCoords.latitude, longitude: centerCoords.longitude)
            let distance = vehicleLocation.distance(from: centerLocation)
            
            if distance < shortestDistance {
                shortestDistance = distance
                nearestServiceCenter = center
            }
        }
        
        return nearestServiceCenter
    }
    
    private func parseCoordinates(_ coordinate: String) -> (latitude: Double, longitude: Double)? {
        let components = coordinate.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
        guard components.count == 2,
              let latitude = Double(components[0]),
              let longitude = Double(components[1]) else {
            return nil
        }
        return (latitude, longitude)
    }
}

// Add this extension for custom corner radius
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// Add this view before MapView
struct TurnByTurnView: View {
    @ObservedObject var viewModel: MapViewModel
    
    var body: some View {
        if viewModel.isNavigating && !viewModel.nextManeuver.isEmpty {
            VStack(spacing: 0) {
                // Main instruction
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.nextManeuver)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("\(Int(viewModel.distanceToNextManeuver))m")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    Spacer()
                }
                .padding()
                .background(Color.black.opacity(0.8))
                
                // Progress bar
                GeometryReader { geometry in
                    let progress = min(1.0, max(0.0, 1.0 - (viewModel.distanceToNextManeuver / 500.0)))
                    Rectangle()
                        .fill(Color.green)
                        .frame(width: geometry.size.width * progress, height: 3)
                }
                .frame(height: 3)
            }
            .cornerRadius(12)
            .shadow(radius: 5)
            .padding(.horizontal)
            .padding(.top, 50)
        }
    }
}

struct EmptyTripCard: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "map.circle")
                .font(.system(size: 60))
                .foregroundColor(.primaryGradientStart.opacity(0.8))
            
            VStack(spacing: 8) {
                Text("No Active Trip")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryGradientStart)
                
                Text("Start a trip from your dashboard to see navigation details")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button(action: {
                 // Switch to Dashboard tab
            }) {
                Text("View Dashboard")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.primaryGradientStart)
                    .cornerRadius(12)
            }
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 5)
    }
}

// MARK: - Map View Representable
struct MapViewRepresentable: UIViewRepresentable {
    @ObservedObject var viewModel: MapViewModel
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        
        // Configure for navigation-style tracking
        mapView.userTrackingMode = .followWithHeading
        mapView.isRotateEnabled = true
        mapView.isPitchEnabled = true
        mapView.showsCompass = true
        mapView.mapType = viewModel.mapType
        
        // Set initial camera
        let camera = MKMapCamera()
        camera.pitch = viewModel.defaultPitch
        camera.altitude = viewModel.normalAltitude
        mapView.camera = camera
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update map type
        mapView.mapType = viewModel.mapType
        
        // Update route overlays and geofencing circles without changing the camera
        let currentOverlays = mapView.overlays
        let currentAnnotations = mapView.annotations.filter { !($0 is MKUserLocation) }
        
        // Remove existing overlays
        mapView.removeOverlays(currentOverlays)
        
        // Show geofencing circles if we have a trip
        if let _ = viewModel.currentTrip {
            if let pickupCircle = viewModel.pickupGeofenceOverlay {
                print("Adding pickup geofence circle to map")
                mapView.addOverlay(pickupCircle)
            }
            if let destinationCircle = viewModel.destinationGeofenceOverlay {
                print("Adding destination geofence circle to map")
                mapView.addOverlay(destinationCircle)
            }
        }
        
        // Add route overlays based on navigation state
        if viewModel.isNavigating {
            // Show only destination route during navigation
            if let route = viewModel.route {
                mapView.addOverlay(route.polyline)
            }
        } else {
            // Show pickup route when not navigating
            if viewModel.showingPickupRoute, let pickupRoute = viewModel.pickupRoute {
                mapView.addOverlay(pickupRoute.polyline)
            }
        }
        
        // Update annotations without changing the camera
        mapView.removeAnnotations(currentAnnotations)
        if let nextDirection = viewModel.nextDirectionAnnotation {
            mapView.addAnnotation(nextDirection)
        }
        
        // Only update camera when explicitly requested
        if viewModel.shouldUpdateCamera, let location = viewModel.userLocation {
            let camera = mapView.camera
            camera.centerCoordinate = location
            camera.pitch = viewModel.defaultPitch
            camera.altitude = viewModel.isNavigating ? viewModel.navigationAltitude : viewModel.normalAltitude
            camera.heading = viewModel.isNavigating ? viewModel.userHeading : camera.heading
            
            // Use smooth animation for camera updates
            UIView.animate(withDuration: 0.3) {
                mapView.setCamera(camera, animated: false)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewRepresentable
        
        init(_ parent: MapViewRepresentable) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let circle = overlay as? MKCircle {
                print("Rendering circle overlay")
                let renderer = MKCircleRenderer(circle: circle)
                if overlay === parent.viewModel.pickupGeofenceOverlay {
                    print("Rendering pickup geofence circle")
                    renderer.fillColor = UIColor.orange.withAlphaComponent(0.5)
                    renderer.strokeColor = UIColor.orange.withAlphaComponent(0.8)
                } else if overlay === parent.viewModel.destinationGeofenceOverlay {
                    print("Rendering destination geofence circle")
                    renderer.fillColor = UIColor.green.withAlphaComponent(0.5)
                    renderer.strokeColor = UIColor.green.withAlphaComponent(0.8)
                }
                renderer.lineWidth = 2
                return renderer
            } else if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                if polyline === parent.viewModel.pickupRoute?.polyline {
                    renderer.strokeColor = .orange
                } else {
                    renderer.strokeColor = .systemBlue
                }
                renderer.lineWidth = 6
                renderer.lineCap = .round
                renderer.lineJoin = .round
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation {
                let identifier = "UserLocation"
                var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                
                if view == nil {
                    view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    view?.canShowCallout = true
                    
                    // Create a circular overlay for the user's location
                    let circle = UIView(frame: CGRect(x: -10, y: -10, width: 20, height: 20))
                    circle.layer.cornerRadius = 10
                    circle.backgroundColor = UIColor(Color.primaryGradientStart)
                    view?.addSubview(circle)
                }
                return view
            } else if let nextDirection = annotation as? NextDirectionAnnotation {
                let identifier = "NextDirection"
                var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                
                if view == nil {
                    view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    view?.canShowCallout = true
                }
                
                // Create a custom view for the next direction
                let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
                containerView.backgroundColor = .clear
                
                // Add a background circle
                let circleView = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
                circleView.layer.cornerRadius = 20
                circleView.backgroundColor = UIColor.white
                circleView.layer.borderWidth = 2
                circleView.layer.borderColor = UIColor.green.cgColor
                containerView.addSubview(circleView)
                
                // Add the arrow icon
                let imageView = UIImageView(frame: CGRect(x: 8, y: 8, width: 24, height: 24))
                imageView.image = UIImage(systemName: "arrow.triangle.turn.up.right.circle.fill")?.withTintColor(.green, renderingMode: .alwaysOriginal)
                containerView.addSubview(imageView)
                
                view?.image = containerView.asImage()
                return view
            }
            
            return nil
        }
        
        func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
            // Remove automatic camera updates
            // Only update through the focus button now
        }
    }
}

// Add this extension to UIView to convert view to image
extension UIView {
    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}

// MARK: - Navigation Info Card
struct NavigationInfoCard: View {
    let trip: Trip
    @ObservedObject var viewModel: MapViewModel
    @Binding var showingPostTripInspection: Bool
    @Binding var hasCompletedPreInspection: Bool
    @State private var showingPreTripInspection = false
    @State private var vehicle: Vehicle?
    @State private var requiresMaintenance = false
    @State private var hasCompletedPostInspection = false
    @State private var inspectionCheckTimer: Timer?
    @Environment(\.dismiss) private var dismiss
    private let tabBarHeight: CGFloat = 49
    private let bottomSafeArea: CGFloat = UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0
    
    var body: some View {
        VStack(spacing: 16) {
            // Route information
            VStack(alignment: .leading, spacing: 8) {
                Text("Active Trip #\(trip.tripID)")
                    .font(.headline)
                    .foregroundColor(.primaryGradientStart)
                
                // Route addresses
                VStack(alignment: .leading, spacing: 4) {
                    if viewModel.isNavigating {
                        // Show destination route addresses
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "location.fill")
                                .foregroundColor(.gray)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("From: Current Location")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text("(\(viewModel.currentLocationAddress))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .lineLimit(2)
                                Text("To: Destination")
                                    .font(.subheadline)
                                    .foregroundColor(.primaryGradientStart)
                                Text("(\(viewModel.destinationLocationAddress))")
                                    .font(.caption)
                                    .foregroundColor(.primaryGradientStart)
                                    .lineLimit(2)
                            }
                        }
                    } else if viewModel.showingPickupRoute {
                        // Show pickup route addresses
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "location.fill")
                                .foregroundColor(.orange)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("From: Current Location")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text("(\(viewModel.currentLocationAddress))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .lineLimit(2)
                                Text("To: Pickup Point")
                                    .font(.subheadline)
                                    .foregroundColor(.orange)
                                Text("(\(viewModel.pickupLocationAddress))")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                    .lineLimit(2)
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
                
                // Next Direction Card - Always show when navigating
                if viewModel.isNavigating {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "arrow.turn.up.right.circle.fill")
                                .foregroundColor(.primaryGradientStart)
                            Text("Next Direction")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primaryGradientStart)
                        }
                        
                        if !viewModel.nextManeuver.isEmpty {
                            Text(viewModel.nextManeuver)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.textPrimary)
                            
                            Text("In \(Int(viewModel.distanceToNextManeuver))m")
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)
                        } else {
                            Text("Calculating next direction...")
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                
                // Route Details
                if let route = viewModel.route {
                    HStack {
                        Label("\(route.distance / 1000, specifier: "%.1f") km", systemImage: "arrow.up.right")
                        Spacer()
                        Label("\(Int(route.expectedTravelTime / 60)) min", systemImage: "clock")
                    }
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                }
                
                // Pickup Route Details
                if viewModel.pickupRoute != nil && !viewModel.isNavigating {
                    HStack {
                        Label("Pickup: \(viewModel.pickupDistance / 1000, specifier: "%.1f") km", systemImage: "location.circle")
                        Spacer()
                        Label("\(Int(viewModel.pickupTime / 60)) min", systemImage: "clock")
                    }
                    .font(.subheadline)
                    .foregroundColor(.orange)
                    
                    if !viewModel.hasReachedPickup {
                        Text("Enter the pickup area (orange circle) to start navigation")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            // Navigation controls
            HStack(spacing: 12) {
                if viewModel.isNavigating && vehicle?.status == .assigned{
                    Button(action: {
                        if viewModel.hasReachedDestination {
                            // Clean up map and stop navigation
                            viewModel.cleanupMap()
                            viewModel.isNavigating = false
                            viewModel.isInNavigationMode = false
                            viewModel.navigationUpdateTimer?.invalidate()
                            viewModel.navigationUpdateTimer = nil
                            
                            // Show post-trip inspection
                            showingPostTripInspection = true
                        }
                    }) {
                        Text("End Navigation")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.hasReachedDestination ? Color.red : Color.gray)
                            .cornerRadius(12)
                    }
                    .disabled(!viewModel.hasReachedDestination || vehicle?.status == .underMaintenance)
                } else if !hasCompletedPreInspection {
                    Button(action: {
                        showingPreTripInspection = true
                    }) {
                        Text("Start Navigation")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.hasReachedPickup ? Color.primaryGradientStart : Color.gray)
                            .cornerRadius(12)
                    }
                    .disabled(!viewModel.hasReachedPickup)
                }
                
                if !viewModel.isNavigating && !hasCompletedPreInspection {
                    Button(action: {
                        viewModel.calculateRouteToPickup(for: trip)
                    }) {
                        Text("Show Pickup Route")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .cornerRadius(12)
                    }
                }
            }
            
            // Vehicle status and maintenance info
            if let vehicle = vehicle {
                if vehicle.status == .underMaintenance {
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "wrench.fill")
                                .foregroundColor(.orange)
                            Text("Vehicle is under maintenance")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                        
                        Text("Trip will start automatically when maintenance is completed")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 8)
                }
                else {
                    
                }
            }
            
            // Geofencing status indicators
            if viewModel.hasReachedPickup || viewModel.hasReachedDestination {
                VStack(spacing: 8) {
                    if viewModel.hasReachedPickup {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("In pickup area")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    if viewModel.hasReachedDestination {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("In destination area")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, tabBarHeight + bottomSafeArea + 20)
        .sheet(isPresented: $showingPreTripInspection) {
            PreTripInspectionChecklistView(trip: trip) { inspectionItems, note in
                let hasAnyFailure = inspectionItems.values.contains(false)
                hasCompletedPreInspection = !inspectionItems.isEmpty
                requiresMaintenance = hasAnyFailure
                
                IFEDataController.shared.addPreTripInspectionForTrip(
                    by: trip.id,
                    inspection: inspectionItems,
                    note: note
                )
                
                if hasAnyFailure {
                    Task {
                        // Assign maintenance task
                        await assignMaintenanceTaskForFailedItems(
                            inspectionItems: inspectionItems,
                            note: note,
                            trip: trip,
                            isPreTrip: true
                        )
                        
                        // Update vehicle status
                        if let vehicle = await IFEDataController.shared.getRegisteredVehicle(by: trip.assignedVehicleID) {
                            self.vehicle = vehicle
                        }
                    }
                } else {
                    viewModel.startNavigation()
                }
            }
        }
        .task {
            if let vehicle = await IFEDataController.shared.getRegisteredVehicle(by: trip.assignedVehicleID) {
                self.vehicle = vehicle
            }
            
            if let inspection = await IFEDataController.shared.getTripInspectionForTrip(by: trip.id) {
                hasCompletedPreInspection = !inspection.preInspection.isEmpty
                requiresMaintenance = inspection.preInspection.values.contains(false)
            }
        }
        .onAppear {
            // Start checking post-trip inspection status
            startInspectionCheckTimer()
        }
        .onDisappear {
            // Stop checking post-trip inspection status
            stopInspectionCheckTimer()
        }
    }
    
    private func startInspectionCheckTimer() {
        // Invalidate existing timer if any
        inspectionCheckTimer?.invalidate()
        
        // Create a new timer that checks every second
        inspectionCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task {
                await checkPostTripInspectionStatus()
            }
        }
    }
    
    private func stopInspectionCheckTimer() {
        inspectionCheckTimer?.invalidate()
        inspectionCheckTimer = nil
    }
    
    private func checkPostTripInspectionStatus() async {
        if let inspection = await IFEDataController.shared.getTripInspectionForTrip(by: trip.id) {
            let hasCompletedPostInspection = !inspection.postInspection.isEmpty
            if self.hasCompletedPostInspection != hasCompletedPostInspection {
                DispatchQueue.main.async {
                    self.hasCompletedPostInspection = hasCompletedPostInspection
                }
            }
        }
    }
    
    private func assignMaintenanceTaskForFailedItems(inspectionItems: [TripInspectionItem: Bool], note: String, trip: Trip, isPreTrip: Bool) async {
        // Filter failed items
        let failedItems = inspectionItems.filter { !$0.value }
        guard !failedItems.isEmpty else { return }
        
        // Create issue note using TripInspection.issueDescription
        let issueDescriptions = failedItems.map { item in
            "\(item.key.rawValue): \(TripInspection.issueDescription[item.key] ?? "Issue detected.")"
        }.joined(separator: "\n")
        
        let inspectionType = isPreTrip ? "Pre-Trip" : "Post-Trip"
        let fullIssueNote = "\(inspectionType) Inspection Failures:\n\(issueDescriptions)\n\nAdditional Note: \(note)"
        
        // Get the vehicle's current coordinate
        guard let vehicle = await IFEDataController.shared.getRegisteredVehicle(by: trip.assignedVehicleID) else {
            print("Failed to fetch vehicle for maintenance task assignment")
            return
        }
        
        // Find the nearest service center
        guard let nearestServiceCenter = await findNearestServiceCenter(to: vehicle.currentCoordinate) else {
            print("No available service center found")
            return
        }
        
        // Debug: Log service center details
        print("Nearest Service Center ID: \(nearestServiceCenter.id)")
        
        // Fetch the maintenance personnel metadata for this service center
        guard let personnelMetaData = await IFEDataController.shared.getMaintenancePersonnelMetaData(ofCenter: nearestServiceCenter.id) else {
            print("No maintenance personnel metadata found for service center \(nearestServiceCenter.id)")
            return
        }
        
        // Verify active status
        guard personnelMetaData.activeStatus else {
            print("Maintenance personnel for service center \(nearestServiceCenter.id) is inactive (ID: \(personnelMetaData.id))")
            return
        }
        
        // Debug: Log personnel details
        print("Assigned Personnel: ID: \(personnelMetaData.id), Name: \(personnelMetaData.fullName), Active: \(personnelMetaData.activeStatus)")
        
        // Assign the maintenance task
        let assignedBy = IFEDataController.shared.user?.id ?? trip.assignedByFleetManagerID
        guard let task = await IFEDataController.shared.assignNewMaintenanceTask(
            by: assignedBy,
            to: personnelMetaData.id,
            for: trip.assignedVehicleID,
            ofType: isPreTrip ? .preInspectionMaintenance : .postInspectionMaintenance,
            fullIssueNote
        ) else {
            print("Failed to assign maintenance task")
            return
        }
        
        print("Maintenance task assigned: \(task)")
    }
    
    private func findNearestServiceCenter(to coordinate: String) async -> ServiceCenter? {
        let components = coordinate.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
        guard components.count == 2,
              let latitude = Double(components[0]),
              let longitude = Double(components[1]) else {
            print("Invalid vehicle coordinate format")
            return nil
        }
        
        let vehicleLocation = CLLocation(latitude: latitude, longitude: longitude)
        let serviceCenters = IFEDataController.shared.serviceCenters
        
        var nearestServiceCenter: ServiceCenter?
        var shortestDistance: CLLocationDistance = .greatestFiniteMagnitude
        
        for center in serviceCenters {
            guard let centerCoords = parseCoordinates(center.coordinate) else {
                continue
            }
            
            let centerLocation = CLLocation(latitude: centerCoords.latitude, longitude: centerCoords.longitude)
            let distance = vehicleLocation.distance(from: centerLocation)
            
            if distance < shortestDistance {
                shortestDistance = distance
                nearestServiceCenter = center
            }
        }
        
        return nearestServiceCenter
    }
    
    private func parseCoordinates(_ coordinate: String) -> (latitude: Double, longitude: Double)? {
        let components = coordinate.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
        guard components.count == 2,
              let latitude = Double(components[0]),
              let longitude = Double(components[1]) else {
            return nil
        }
        return (latitude, longitude)
    }
}

// Add this class after the MapViewModel class
class NextDirectionAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?
    
    init(coordinate: CLLocationCoordinate2D, title: String?, subtitle: String?) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        super.init()
    }
}

#Preview {
    MapView(selectedTab: .constant(0))
}

extension MapViewModel: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let actionIdentifier = response.actionIdentifier
        
        switch actionIdentifier {
        case "START_NAVIGATION":
            if hasReachedPickup {
                startNavigation()
            }
        case "END_NAVIGATION":
            if hasReachedDestination {
                stopNavigation()
            }
        default:
            break
        }
        
        completionHandler()
    }
}

// Add PreTripInspectionChecklistView back to MapView.swift
struct PreTripInspectionChecklistView: View {
    let trip: Trip
    @Environment(\.dismiss) private var dismiss
    let onSave: ([TripInspectionItem: Bool], String) -> Void

    @State private var inspectionItems: [TripInspectionItem: Bool] = Dictionary(
        uniqueKeysWithValues: TripInspectionItem.allCases.map { ($0, false) }
    )
    @State private var preTripNote: String = ""
    
    private var isAnyItemChecked: Bool {
        inspectionItems.values.contains(true)
    }
    
    @State private var allGood: Bool = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    CheckboxView(
                        title: "All Good",
                        isChecked: Binding(
                            get: { allGood },
                            set: { newValue in
                                allGood = newValue
                                // Update all items when "All Good" is toggled
                                for item in TripInspectionItem.allCases {
                                    inspectionItems[item] = newValue
                                }
                                print("All Good toggled: \(allGood), inspectionItems: \(inspectionItems)")
                            }
                        )
                    )
                }
                
                Section(header: Text("Pre-Trip Inspection Checklist")) {
                    ForEach(TripInspectionItem.allCases, id: \.self) { item in
                        CheckboxView(
                            title: item.rawValue,
                            isChecked: Binding(
                                get: { inspectionItems[item] ?? false },
                                set: { newValue in
                                    inspectionItems[item] = newValue
                                    // Recalculate allGood based on all items
                                    allGood = inspectionItems.values.allSatisfy { $0 }
                                    print("Item \(item.rawValue) toggled: \(newValue), inspectionItems: \(inspectionItems)")
                                }
                            )
                        )
                    }
                }
                
                Section(header: Text("Description (Optional)")) {
                    TextEditor(text: $preTripNote)
                        .frame(minHeight: 100)
                        .overlay(
                            Group {
                                if preTripNote.isEmpty {
                                    Text("Enter the issue in vehicle")
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 8)
                                }
                            },
                            alignment: .topLeading
                        )
                        .onChange(of: preTripNote) { newValue in
                            print("Pre-Trip Note updated: \(newValue)")
                        }
                }
            }
            .navigationTitle("Pre-Trip Inspection")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        print("Cancel pressed, passing: inspectionItems: [:], note: ''")
                        onSave([:], "") // Pass empty dictionary to indicate cancellation
                        dismiss()
                    }
                    .foregroundColor(.primaryGradientStart)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        print("Save pressed, passing: inspectionItems: \(inspectionItems), note: \(preTripNote)")
                        
                        onSave(inspectionItems, preTripNote) // Pass current state
                        dismiss()
                    }
                    .disabled(!isAnyItemChecked)
                    .foregroundColor(isAnyItemChecked ? .primaryGradientStart : .gray)
                }
            }
        }
    }
} 
