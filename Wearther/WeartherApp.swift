//
//  WeartherApp.swift
//  Wearther
//
//  Created by hato on 2025/11/07.
//

import SwiftUI
import FirebaseCore
import GoogleSignIn

class AppLifecycleHandler: NSObject, UIApplicationDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        print("Firebase has been configured!")
        return true
    }

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}

@main
struct WeartherApp: App {
    @UIApplicationDelegateAdaptor(AppLifecycleHandler.self) var delegate
    @StateObject private var authService = AuthService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
        }
    }
}
