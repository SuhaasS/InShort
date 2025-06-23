import SwiftUI
import SwiftData
import UserNotifications

@main
struct InShortApp: App {
    @State private var notificationsAuthorized = false
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @AppStorage("hasLaunchedBefore") private var hasLaunchedBefore = false
    @State private var showOnboarding = false
    @Environment(\.scenePhase) private var scenePhase

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Bill.self,
            UserProfile.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do { return try ModelContainer(for: schema, configurations: [config]) }
        catch { fatalError("Could not create ModelContainer: \(error)") }
    }()

    var body: some Scene {
    WindowGroup {
        
        
        MainTabView()
            .task {
                    AppLogger.log("App launched")

                notificationsAuthorized = await NotificationService.shared.requestPermissions()
                if notificationsAuthorized {
                        // Only schedule real digests in non-debug
                        #if !DEBUG
                        let defaults = UserDefaults.standard
                        let cadence = defaults.string(forKey: "notificationCadence") ?? "immediate"
                        let time = defaults.object(forKey: "notificationTime") as? Date ?? Date()
                        switch cadence {
                        case "daily":
                            NotificationService.shared.scheduleDailyDigestNotification(at: time)
                        case "weekly":
                            NotificationService.shared.scheduleWeeklyDigestNotification(at: time)
                        default:
                            break
                        }
                        #endif
                    }

                if DEBUG_USE_FAKE_DATA {
                    do {
                        let bills = try await BillService.shared.fetchBills()
                        if let bill = bills.first(where: { $0.isSubscribed }) ?? bills.first {
                            NotificationService.shared.scheduleBillUpdateNotification(for: bill)
                        }
                    } catch {
                            AppLogger.error("Error scheduling sample notification: \(error.localizedDescription)")
                    }
                }

                    if !hasLaunchedBefore {
                        hasLaunchedBefore = true
                        showOnboarding = true
                    }
                }
                .sheet(isPresented: $showOnboarding) {
                    OnboardingView()
            }
            .onOpenURL { url in
                DeepLinkManager.shared.handle(url: url)
            }
                .onChange(of: scenePhase) { newPhase in
                    switch newPhase {
                    case .active:
                        AppLogger.log("Scene phase: active")
                    case .inactive:
                        AppLogger.log("Scene phase: inactive")
                    case .background:
                        AppLogger.log("Scene phase: background")
                    default:
                        break
                    }
                }
    }
    .modelContainer(sharedModelContainer)
}

}

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss

    
    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to InShort")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("Understand legislation quickly and stay informed.")
                .multilineTextAlignment(.center)
            Button("Get Started") {
                dismiss()
                // Dismissed automatically
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}



class DeepLinkManager {
    static let shared = DeepLinkManager()

    func handle(url: URL) {
        print("Handling deep link: \(url)")

        // Example:
        // inshort://bill/HR1234
        let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        guard let host = url.host else { return }

        if host == "bill", let billID = url.pathComponents.dropFirst().first {
            print("Open bill with ID: \(billID)")
            // You could post a NotificationCenter event, or update a shared AppState
        }
    }
}


// App Delegate to handle notifications
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // Handle notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show the notification even when the app is in the foreground
        completionHandler([.banner, .sound, .badge])
    }

    // Handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        NotificationService.shared.handleNotification(response: response)
        completionHandler()
    }
}
