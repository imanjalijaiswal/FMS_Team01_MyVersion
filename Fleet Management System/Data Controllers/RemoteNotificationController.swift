//
//  RemoteNotificationController.swift
//  Fleet Management System
//
//  Created by Devansh Seth on 02/04/25.
//

import UserNotifications
import Supabase

class IFERemoteNotificationController: IFENotifiable {
    private var client: SupabaseClient
    private var schema: String
    private var table: String
    private var userID: UUID?
    private var realtimeChannel: RealtimeChannelV2?
    
    required init(_ client: Supabase.SupabaseClient, schema: String = "public", table: String, userID: UUID?) {
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
        
        // Extract the "new" record from payload
        guard let newRecord = payload["new"] as? [String: Any] else {
            print("Failed to extract 'new' record from payload")
            return
        }
        
        // Convert dictionary to JSON data
        guard let jsonData = try? JSONSerialization.data(withJSONObject: newRecord) else {
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
    
    /// Subscribes to real-time updates from the specified database table.
    ///
    /// This function sets up a subscription to receive real-time data changes from the given database table (`table`) within the specified schema (`schema`).
    /// It listens specifically for `INSERT` actions and triggers the `handlePayload(_:)` function whenever a new record is added.
    /// The subscription is managed through the `realtimeChannel` property, and any existing subscription is canceled before establishing a new one.
    ///
    /// # Implementation Details
    /// - The function unsubscribes from any previous subscription to ensure no duplicate listeners.
    /// - It connects to a real-time channel using the combination of `schema` and `table`.
    /// - On receiving an insert action, it converts the record into a dictionary and passes it to `handlePayload(_:)`.
    ///
    /// # Example Usage
    /// ```swift
    /// Task {
    ///     await subscribe()
    /// }
    /// ```
    ///
    /// - Note: Uses weak self to prevent retain cycles and ensure memory safety.
    func subscribe() async {
        await unsubscribe()
        
        let channel = client
                .realtimeV2
                .channel("realtime:\(schema):\(table)")

        _ = channel.onPostgresChange(
            InsertAction.self,
            schema: schema,
            table: table,
            filter: nil
        ) { [weak self] action in
            print("Received new record: \(action.record)")
            guard let self = self else { return }
            

            // Convert the action record to a dictionary
            var payload: [String: Any] = [:]
            action.record.forEach { key, value in
                payload[key] = value.value
            }

            // Pass the record payload to the handler
            self.handlePayload(payload)
        }

        // Subscribe to the channel and store it
        await channel.subscribe()
        do {
            try await Task.sleep(nanoseconds: 500_000_000)
        } catch {
            print("Error while sleeping for 0.5 seconds for real time subscription.")
        }
        
        switch channel.status {
        case .subscribing: print("Subscribing to channel for real time notifications.")
        case .subscribed: print("Successfully subscribed to notification channel for real time updates.")
        default: break
        }
        
        self.realtimeChannel = channel
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
    func showPushNotification(_ notification: IFEPushNotification) {
        #if os(iOS)
        print(notification)
        
            let content = UNMutableNotificationContent()
            content.title = notification.title
            content.body = notification.message
            
            let request = UNNotificationRequest(identifier: notification.id.uuidString,
                                                content: content,
                                                trigger: UNTimeIntervalNotificationTrigger(timeInterval: 0.1,
                                                                                           repeats: false))
            
            UNUserNotificationCenter.current().add(request)
        #endif
    }
}
