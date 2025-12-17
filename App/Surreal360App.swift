import SwiftUI
import UIKit
import UserNotifications

@main
struct Surreal360App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appCoordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup {
            AppCoordinatorView(coordinator: appCoordinator)
                .onAppear {
                    // Initialize VoIP push after app launches
                    initializeVoIPPush()
                }
        }
    }

    private func initializeVoIPPush() {
        // Register for VoIP push notifications when user is authenticated
        Task { @MainActor in
            if appCoordinator.isAuthenticated {
                appCoordinator.container.voipPushService.start()
            }
        }
    }
}

// MARK: - App Delegate for Push Notifications

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error)")
            }
        }
        // Note: VoIP push registration occurs in the main app struct (Surreal360App)
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        print("APNs Device Token: \(token)")
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }
}

struct AppCoordinatorView: View {
    @ObservedObject var coordinator: AppCoordinator

    var body: some View {
        Group {
            if coordinator.isLoading {
                SplashScreenView()
            } else if coordinator.isAuthenticated {
                DashboardView()
                    .environmentObject(coordinator.container)
            } else {
                SignInView(container: coordinator.container)
                    .environmentObject(coordinator.container)
            }
        }
        .onAppear {
            coordinator.checkAuthenticationStatus()
        }
    }
}

// MARK: - Splash Screen

struct SplashScreenView: View {
    var body: some View {
        ZStack {
            Color.blue.ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "globe")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.white)

                Text("Surreal360")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
            }
        }
    }
}

// NOTE: SignInView and DashboardView are now imported from their respective feature modules
// - Features/Authentication/Views/SignInView.swift
// - Features/Dashboard/Views/DashboardView.swift
// Make sure these files are added to your Xcode project target

