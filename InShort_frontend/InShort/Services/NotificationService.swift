import Foundation
import UserNotifications
import Combine

class NotificationService {
    static let shared = NotificationService()

    let profileDidChangePublisher = PassthroughSubject<Void, Never>()

    private init() {}

    func requestPermissions() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]

        do {
            let granted = try await center.requestAuthorization(options: options)
            return granted
        } catch {
            print("Error requesting notification permissions: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Single Bill Notifications

    func scheduleBillUpdateNotification(for bill: Bill) {
        // Placeholder for future local notification logic
        print("Scheduling notification for bill: \(bill.title)")
    }

    // MARK: - Digest Notifications

    func scheduleDailyDigestNotification(at time: Date) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily-digest"])
        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        scheduleDigest(identifier: "daily-digest", trigger: trigger, title: "Today in Congress", isWeekly: false)
    }

    func scheduleWeeklyDigestNotification(at time: Date) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["weekly-digest"])
        var components = Calendar.current.dateComponents([.hour, .minute], from: time)
        components.weekday = 2 // Monday
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        scheduleDigest(identifier: "weekly-digest", trigger: trigger, title: "Weekly Congress Roundup", isWeekly: true)
    }

    private func scheduleDigest(identifier: String, trigger: UNNotificationTrigger, title: String, isWeekly: Bool) {
        Task {
            let bills = try? await BillService.shared.fetchBills()
            let profile = try? await UserService.shared.fetchProfile()
            guard let interests = profile?.interests, let all = bills else { return }
            let filtered = all.filter { bill in
                interests.contains(where: { bill.title.contains($0) || bill.summary.contains($0) })
            }
            let top5 = (filtered + all).sorted { $0.lastUpdated ?? Date.distantPast > $1.lastUpdated ?? Date.distantPast }
                .uniqued(by: \.id).prefix(5)

            let body = top5.map { "• \($0.title)" }.joined(separator: "\n")
            scheduleNotification(identifier: identifier, title: title, body: body, trigger: trigger)
        }
    }

    private func scheduleNotification(identifier: String, title: String, body: String, trigger: UNNotificationTrigger) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = ["digest": identifier]

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling \(identifier): \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Handle Taps

    func handleNotification(response: UNNotificationResponse) {
        let userInfo = response.notification.request.content.userInfo
        if let billId = userInfo["billId"] as? String {
            print("Notification tapped for bill: \(billId)")
        } else if let digest = userInfo["digest"] as? String {
            print("Digest notification tapped: \(digest)")
        }
    }
}

// Helper to remove duplicates preserving order
extension Sequence {
    func uniqued<T: Hashable>(by keyPath: KeyPath<Element, T>) -> [Element] {
        var seen = Set<T>()
        return filter { seen.insert($0[keyPath: keyPath]).inserted }
    }
}
