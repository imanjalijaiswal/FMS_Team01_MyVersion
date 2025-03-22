import SwiftUI
import MapKit

struct MapView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 52.2297, longitude: 21.0122),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                Map(coordinateRegion: $region)
                    .edgesIgnoringSafeArea(.all)
                
                // Back button
                VStack {
                    HStack {
                        
                        Spacer()
                        
                        Button(action: {}) {
                            Image(systemName: "arrow.clockwise")
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
                
                VStack(spacing: 0) {
                    // Location card
                    LocationCard()
                    
                    // Trip details card
                    TripDetailsCard()
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
}

struct LocationCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Warszawska 82, 96-515 Sochaczew")
                    .font(.subheadline)
                    .foregroundColor(.textPrimary)
                Spacer()
            }
            
            HStack(spacing: 4) {
                Text("55.9 km")
                Text("•")
                Text("You're")
                Text("1h 1m")
                Text("away")
            }
            .font(.caption)
            .foregroundColor(.textSecondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.statusOrange)
        .foregroundColor(.white)
        .cornerRadius(12)
    }
}

struct TripDetailsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Driver info
            HStack(spacing: 12) {
                Image("driver_avatar")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("David Russel")
                        .fontWeight(.medium)
                    Text("PO 123FF")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                Text("ONLINE")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.statusGreen.opacity(0.2))
                    .foregroundColor(.statusGreen)
                    .cornerRadius(4)
            }
            
            Text("Logged from Jan 4, 4:21 AM")
                .font(.caption)
                .foregroundColor(.textSecondary)
            
            Divider()
            
            // Solar Panel details
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Solar Panel")
                        .font(.headline)
                    HStack {
                        Text("Green Energy LTD")
                        Text("#GE73895")
                            .foregroundColor(.statusOrange)
                    }
                    .font(.subheadline)
                }
                
                Spacer()
                
                Text("ASSIGNED")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.statusOrange.opacity(0.2))
                    .foregroundColor(.statusOrange)
                    .cornerRadius(4)
            }
            
            HStack {
                Text("Today")
                Text("•")
                Text("Container, 54.1 lbs")
            }
            .font(.subheadline)
            .foregroundColor(.textSecondary)
            
            // Action buttons
            HStack(spacing: 12) {
                Button(action: {}) {
                    Text("Reject")
                        .font(.headline)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                }
                
                Button(action: {}) {
                    Text("Pickup Load")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primaryGradientStart)
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }
}

#Preview {
    TripsView()
} 
