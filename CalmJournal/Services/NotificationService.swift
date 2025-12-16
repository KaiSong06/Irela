import UserNotifications

final class NotificationService {
    static let shared = NotificationService()
    
    private init() {}
    
    func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async {
                if granted {
                    self.scheduleDailyReminder()
                }
                completion(granted)
            }
        }
    }
    
    // One daily notification at 8pm
    func scheduleDailyReminder() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        
        let content = UNMutableNotificationContent()
        content.title = "Calm Journal"
        content.body = "Want to check in with yourself?"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = 20  // 8pm
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "daily_checkin", content: content, trigger: trigger)
        
        center.add(request)
    }
}

