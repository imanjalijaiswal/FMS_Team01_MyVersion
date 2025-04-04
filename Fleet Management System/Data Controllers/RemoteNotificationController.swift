//
//  RemoteNotificationController.swift
//  Fleet Management System
//
//  Created by Devansh Seth on 02/04/25.
//

import UserNotifications
import Supabase

class IFERemoteNotificationController: NSObject, IFENotifiable {
    private var client: SupabaseClient
    private var schema: String
    private var table: String
    private var userID: UUID?
    private var realtimeChannel: RealtimeChannelV2?
    
    /// Instance of UNUserNotificationCenter used to manage local and remote notifications
    var notificationCenter = UNUserNotificationCenter.current()
    
    required init(_ client: SupabaseClient, schema: String = "public", table: String, userID: UUID?) {
        self.client = client
        self.schema = schema
        self.table = table
        self.userID = userID
    }
    
    /// Sends a push notification asynchronously using the specified notification object.
    ///
    /// This function constructs a `NotifyParams` structure containing the sender ID, recipient ID, title, and message extracted from the `IFEPushNotification` object.
    /// It then triggers the remote procedure call (RPC) to send the notification using the `client` object.
    /// In case of an error during the sending process, it logs the error and the notification details.
    ///
    /// - Parameter notification: An `IFEPushNotification` object containing the sender ID, recipient ID, title, message, and other metadata.
    ///
    /// # Example Usage
    /// ```swift
    /// let notification = IFEPushNotification(id: UUID(), senderID: senderID, recipientID: recipientID, title: "Alert", message: "Maintenance required", sentAt: .now)
    /// await sendNotification(notification)
    /// ```
    func sendNotification(_ notification: IFEPushNotification) async {
        struct NotifyParams: Codable {
            let p_sender_id: String
            let p_recipient_id: String
            let p_title: String
            let p_message: String
        }
        
        let params = NotifyParams(p_sender_id: notification.senderID.uuidString,
                                  p_recipient_id: notification.recipientID.uuidString,
                                  p_title: notification.title,
                                  p_message: notification.message)
        do {
            try await client
                .rpc("notify_user", params: params)
                .execute()
            print("Message sent successfully.")
        } catch {
            print("Error sending the notification:\n\(notification)\n\(error.localizedDescription)")
        }
    }
    
    /// Handles incoming push notification payload by decoding and displaying it.
    ///
    /// This function extracts a nested `"new"` record from the given payload dictionary, converts it to JSON data, and then decodes it into a `PayloadRecord` structure.
    /// After decoding, it transforms the record into an `IFEPushNotification` object and triggers the `showPushNotification` function to display the notification.
    /// If any step fails, the function logs an appropriate error message.
    ///
    /// - Parameter payload: A dictionary containing the push notification data.
    ///   The expected format is:
    ///   ```json
    ///   {
    ///     "new": {
    ///       "id": "UUID",
    ///       "sender_id": "UUID",
    ///       "recipient_id": "UUID",
    ///       "title": "String",
    ///       "message": "String",
    ///       "sent_at": "ISO8601 Timestamp"
    ///     }
    ///   }
    ///   ```
    ///
    /// # Example Usage
    /// ```swift
    /// let payload: [String: Any] = [
    ///     "new": [
    ///         "id": "550e8400-e29b-41d4-a716-446655440000",
    ///         "sender_id": "550e8400-e29b-41d4-a716-446655440001",
    ///         "recipient_id": "550e8400-e29b-41d4-a716-446655440002",
    ///         "title": "Maintenance Alert",
    ///         "message": "Vehicle requires immediate attention.",
    ///         "sent_at": "2025-04-01T12:00:00Z"
    ///     ]
    /// ]
    /// handlePayload(payload)
    /// ```
    ///
    /// - Note: Uses `ISO8601DateFormatter` to parse the timestamp string.
    func handlePayload(_ payload: [String : Any]) {
        struct PayloadRecord: Codable {
            let id: UUID
            let senderID: UUID
            let recipientID: UUID
            let title: String
            let message: String
            let sentAt: String
            
            enum CodingKeys: String, CodingKey {
                case id
                case senderID = "sender_id"
                case recipientID = "recipient_id"
                case title
                case message
                case sentAt = "sent_at"
            }
        }
        
        // Convert dictionary to JSON data
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload) else {
            print("Failed to serialize record to JSON")
            return
        }
        
        // Decode JSON to PayloadRecord
        guard let record = try? JSONDecoder().decode(PayloadRecord.self, from: jsonData) else {
            print("Failed to decode JSON to PayloadRecord")
            return
        }
        
        // Message is not for this user
        guard record.recipientID == userID else { return }
        
        // Convert PayloadRecord to IFEPushNotification
        let notification = IFEPushNotification(
            id: record.id,
            senderID: record.senderID,
            recipientID: record.recipientID,
            title: record.title,
            message: record.message,
            sentAt: ISO8601DateFormatter().date(from: record.sentAt) ?? Date()
        )
        
        // Show the notification
        showPushNotification(notification)
    }
    
    /// Subscribes to real-time notifications from the specified table and schema.
    ///
    /// This function sets up a real-time channel to listen for `INSERT` operations on the specified table.
    /// The channel is filtered by `recipient_id`, matching the current user's ID.
    /// It also handles automatic unsubscription before subscribing to avoid duplicate channels.
    ///
    /// - Asynchronous Function: The function operates asynchronously and uses real-time channels for updates.
    /// - Handles channel creation, subscription, and listening for changes in a separate task.
    /// - In case of failure to create or subscribe to the channel, it logs the issue for debugging purposes.
    ///
    /// # Real-time Subscription Flow
    /// 1. Unsubscribe from any existing channel.
    /// 2. Create a new real-time channel for the given schema and table.
    /// 3. Subscribe to the channel and wait for confirmation.
    /// 4. Log the subscription status to track the process.
    /// 5. Continuously listen for incoming changes and handle them via `handlePayload`.
    ///
    /// # Example Usage
    /// ```swift
    /// await subscribe()
    /// ```
    ///
    /// - Note: The function uses a short delay (0.5 seconds) to ensure the subscription stabilizes.
    /// - Uses `Task` for asynchronous listening to real-time changes.
    func subscribe() async {
        await unsubscribe()
        
        self.realtimeChannel = client
                .realtimeV2
                .channel("realtime:\(schema):\(table)")
        if realtimeChannel == nil {
            print("Unable to create realtime channel.")
        } else {
            print("Realtime channel successfully created.")
        }

        
        let changes = realtimeChannel?.postgresChange(InsertAction.self,
                                                      schema: schema,
                                                      table: table,
                                                      filter: .eq("recipient_id", value: userID ?? ""))

        
        await realtimeChannel?.subscribe()
        do {
            try await Task.sleep(nanoseconds: 500_000_000)
        } catch {
            print("Error while sleeping for 0.5 seconds for real time subscription.")
        }

        
        switch realtimeChannel?.status {
        case .subscribing: print("Subscribing to channel for real time notifications.")
        case .subscribed: print("Successfully subscribed to notification channel for real time updates.")
        default: print("Channel status: \(String(describing: realtimeChannel?.status))")
        }
        
        Task {
            if let changes {
                for await change in changes {
                    var payload: [String: Any] = [:]
                    change.record.forEach { key, value in
                        payload[key] = value.value
                    }
                    
                    self.handlePayload(payload)
                }
            } else {
                print("Found nil in changes while listening to real-time updates.")
            }
        }
    }
    
    /// Unsubscribes from the active real-time channel, if any.
    ///
    /// This function safely disconnects from the current real-time channel and removes the stored reference to it.
    /// If no active subscription exists, it simply logs a message and returns.
    ///
    /// # Implementation Details
    /// - Uses the stored `realtimeChannel` to perform the unsubscription asynchronously.
    /// - Sets `realtimeChannel` to `nil` after unsubscribing to ensure proper cleanup.
    ///
    /// # Example Usage
    /// ```swift
    /// Task {
    ///     await unsubscribe()
    /// }
    /// ```
    ///
    /// - Note: Ensures that no redundant unsubscribe calls are made if there is no active channel.
    func unsubscribe() async {
        guard let channel = realtimeChannel else {
            print("No active subscription to unsubscribe from.")
            return
        }

        // Unsubscribe from the channel
        await channel.unsubscribe()
        realtimeChannel = nil
        print("Unsubscribed from table \(table).")
    }
    
    /// Displays a local push notification on iOS devices.
    ///
    /// This function creates a local notification using the provided `IFEPushNotification` object.
    /// It configures the notification content with the title and message, and triggers it immediately.
    ///
    /// - Parameter notification: An `IFEPushNotification` object containing the notification details.
    ///
    /// # Implementation Details
    /// - Uses `UNUserNotificationCenter` to schedule the notification.
    /// - The notification is triggered with a minimal delay of 0.1 seconds to ensure immediate display.
    /// - Uses `UNTimeIntervalNotificationTrigger` to fire the notification once without repetition.
    ///
    /// # Example Usage
    /// ```swift
    /// let notification = IFEPushNotification(id: UUID(), senderID: senderID, recipientID: recipientID, title: "Alert", message: "Something happened!", sentAt: .now)
    /// showPushNotification(notification)
    /// ```
    ///
    /// - Note: This function is available only on iOS platforms.
    func showPushNotification(_ notification: IFEPushNotification,
                              sound: UNNotificationSound? = UNNotificationSound.default) {
        Task {
            let senderMetaData = await notification.getSenderMetaData()
            guard let senderMetaData else {
                print("Unable to fetch notification sender meta data.")
                return
            }
            
            var infoKey: String = "Message from"
            switch senderMetaData.role {
            case .driver: infoKey = "\(infoKey) Driver"
            case .fleetManager: infoKey = "\(infoKey) Fleet Manager"
            case .maintenancePersonnel: infoKey = "\(infoKey) Maintenance Personnel"
            }
            
            let content = UNMutableNotificationContent()
            content.title = notification.title
            content.body = """
            \(notification.message)
            """
            content.userInfo = [infoKey: senderMetaData.fullName]
            content.categoryIdentifier = "persistentNotification"
            content.sound = sound
            
            // Trigger after 1 seconds (for demonstration)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            
            // Create the request
            let request = UNNotificationRequest(identifier: notification.id.uuidString, content: content, trigger: trigger)
            
            do {
                try await UNUserNotificationCenter.current().add(request)
                print("Notification scheduled successfully.")
            } catch {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
    
    /// Requests permission to display notifications to the user.
    ///
    /// This function prompts the user to grant permission for displaying alerts, badges, and sounds through notifications.
    /// It handles the result by logging whether the permission was granted or denied, or if an error occurred.
    ///
    /// - Uses: `UNUserNotificationCenter` to request authorization with the specified options.
    /// - Parameters: None
    /// - Returns: Void
    ///
    /// # Example Usage
    /// ```swift
    /// requestNotificationPermission()
    /// ```
    ///
    /// - Note: This function should be called during app launch or when the user initiates notification-related features.
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Error requesting permission: \(error.localizedDescription)")
            } else {
                print(granted ? "Permission granted" : "Permission denied")
            }
        }
    }
    
    /// Registers a persistent notification category to ensure that notifications are not automatically dismissed by the system.
    ///
    /// This function sets up a notification category with the option `.customDismissAction`,
    /// which keeps the notification visible until explicitly dismissed by the user.
    /// It helps maintain critical or important alerts that should not disappear automatically.
    ///
    /// - Uses: `UNUserNotificationCenter` to configure the notification category.
    /// - Category Identifier: `"persistentNotification"`
    /// - Parameters: None
    /// - Returns: Void
    ///
    /// # Example Usage
    /// ```swift
    /// registerPersistentNotificationCategory()
    /// ```
    ///
    /// - Note: Use this function to register categories during app launch or when setting up notifications.
    func registerPersistentNotificationCategory() {
        let persistentCategory = UNNotificationCategory(
            identifier: "persistentNotification",
            actions: [],
            intentIdentifiers: [],
            options: [.customDismissAction]  // Prevent automatic dismissal
        )

        UNUserNotificationCenter.current().setNotificationCategories([persistentCategory])
        print("Notifications registered to persistent.")
    }
}

extension IFERemoteNotificationController: UNUserNotificationCenterDelegate {
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
        completionHandler()
    }
}
