//
//  AnubisSDSApp.swift
//  AnubisSDS
//
//  Created by Mark Pfeifer on 5/10/25.
//

import SwiftUI

@main
struct AnubisSDSApp: App {
    @AppStorage("dontShowWelcomeAgain") private var dontShowWelcomeAgain = false
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var isInitialized = false
    @State private var showWelcome = false
    @State private var shouldRestart = false
    
    init() {
        print("App launching")
        #if DEBUG
        if ProcessInfo.processInfo.environment["RESET_WELCOME_SCREEN"] == "true" {
            UserDefaults.standard.removeObject(forKey: "dontShowWelcomeAgain")
            print("Reset welcome screen values for testing")
        }
        #endif
        
        print("Initial dontShowWelcomeAgain value: \(dontShowWelcomeAgain)")
        
        // Set up notification observer for database updates
        NotificationCenter.default.addObserver(forName: NSNotification.Name("DatabaseUpdated"), object: nil, queue: .main) { _ in
            // Set a flag to restart the app
            UserDefaults.standard.set(true, forKey: "shouldRestartApp")
            // Exit the app
            exit(0)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if UserDefaults.standard.bool(forKey: "shouldRestartApp") {
                    RestartView()
                } else if !isInitialized {
                    InitializationView()
                } else if !subscriptionManager.isSubscribed {
                    ContentView()
                        .sheet(isPresented: .constant(true)) {
                            WelcomeView(isPresented: .constant(true))
                        }
                } else if dontShowWelcomeAgain {
                    ContentView()
                } else {
                    ContentView()
                        .sheet(isPresented: $showWelcome) {
                            WelcomeView(isPresented: $showWelcome)
                        }
                        .onAppear {
                            showWelcome = true
                        }
                }
            }
            .task {
                await subscriptionManager.checkSubscriptionStatus()
                isInitialized = true
            }
        }
    }
}

// MARK: - Supporting Views
private struct RestartView: View {
    var body: some View {
        EmptyView()
            .onAppear {
                UserDefaults.standard.set(false, forKey: "shouldRestartApp")
            }
    }
}

private struct InitializationView: View {
    var body: some View {
        EmptyView()
    }
}
