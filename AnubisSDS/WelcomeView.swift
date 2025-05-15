import SwiftUI
import StoreKit

struct WelcomeView: View {
    @Binding var isPresented: Bool
    @AppStorage("dontShowWelcomeAgain") private var dontShowWelcomeAgain = false
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showUserGuide = false
    @State private var showErrorSheet = false
    @State private var showTroubleshooting = false
    @State private var showSubscriptionManagement = false
    @Environment(\.dismiss) private var dismiss
    
    private func dismissWelcome() {
        print("dismissWelcome called, isSubscribed: \(subscriptionManager.isSubscribed), dontShowWelcomeAgain: \(dontShowWelcomeAgain)")
        if subscriptionManager.isSubscribed {
            print("Dismissing welcome screen")
            isPresented = false
        } else {
            print("Cannot dismiss - not subscribed")
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    Text("Welcome to EmbalmPro")
                        .font(.title)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .padding(.top)
                        .foregroundColor(.primary)
                    
                    // Subscription Section
                    VStack(spacing: 15) {
                        Text("EmbalmPro requires a subscription to access the application.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 5)
                        
                        Text("Annual Subscription")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Start with a 7-day free trial")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        Text("Then $49.99/year for full access to all features")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if subscriptionManager.isLoading {
                            VStack {
                                ProgressView()
                                    .padding()
                                Text("Processing...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Button(action: {
                                #if targetEnvironment(simulator)
                                // In simulator, attempt to purchase using StoreKit testing
                                Task {
                                    await subscriptionManager.purchase()
                                    // Show error sheet if purchase failed
                                    if subscriptionManager.errorMessage != nil || subscriptionManager.actionableError != nil {
                                        await MainActor.run {
                                            showErrorSheet = true
                                        }
                                    }
                                }
                                #else
                                if subscriptionManager.isSubscribed {
                                    // On real device, show native subscription management
                                    showSubscriptionManagement = true
                                } else {
                                    Task {
                                        await subscriptionManager.purchase()
                                        // Show error sheet if purchase failed and set an error
                                        if subscriptionManager.errorMessage != nil || subscriptionManager.actionableError != nil {
                                            await MainActor.run {
                                                showErrorSheet = true
                                            }
                                        }
                                    }
                                }
                                #endif
                            }) {
                                Text(subscriptionManager.isSubscribed ? "Manage Subscription" : "Start Free Trial")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(subscriptionManager.isOffline ? Color.gray : Color.blue)
                                    .cornerRadius(10)
                            }
                            .disabled(subscriptionManager.isOffline)
                            .sheet(isPresented: $showSubscriptionManagement) {
                                if #available(iOS 16.0, *) {
                                    SubscriptionManagementView()
                                }
                            }
                            
                            Button(action: {
                                if subscriptionManager.isOffline {
                                    // Show network error
                                    showErrorSheet = true
                                } else {
                                    Task {
                                        await subscriptionManager.restorePurchases()
                                    }
                                }
                            }) {
                                Text("Restore Purchases")
                                    .font(.subheadline)
                                    .foregroundColor(subscriptionManager.isOffline ? .gray : .blue)
                            }
                            .disabled(subscriptionManager.isOffline)
                            
                            // Help button
                            Button(action: {
                                showTroubleshooting = true
                            }) {
                                HStack {
                                    Image(systemName: "questionmark.circle")
                                    Text("Having issues?")
                                }
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            }
                            .padding(.top, 5)
                        }
                        
                        if let errorMessage = subscriptionManager.errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(.red)
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                            
                            if subscriptionManager.actionableError != nil {
                                Button(action: {
                                    showErrorSheet = true
                                }) {
                                    Text("Show Options")
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(5)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(radius: 2)
                    
                    Text("EmbalmPro is intended as a reference tool and does not guarantee embalming outcomes. Each case presents unique challenges that require the embalmer's judgment, continuous assessment, and adaptation to achieve the desired results.")
                        .font(.subheadline)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .padding(.bottom)
                    
                    // Key Features Section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Key Features")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        FeatureRow(icon: "flask", title: "Fluids Tab", description: "Access comprehensive information about embalming fluids, including composition, usage guidelines, and safety data.")
                        
                        FeatureRow(icon: "figure", title: "Case Analysis Tab", description: "View case types with suggested solution strengths, fluid indexes, and recommended products.")
                        
                        FeatureRow(icon: "function", title: "CH₂O Calculator", description: "Calculate fluid amounts and dilution ratios based on fluid index or body weight using standard or protein-based approaches.")
                        
                        FeatureRow(icon: "doc.text", title: "SDS Tab", description: "Access Safety Data Sheets with searchable sections for included embalming fluids.")
                        
                        FeatureRow(icon: "star.fill", title: "Favorites", description: "Save your most-used fluids and calculations for quick access to your embalming room's specific chemicals.")
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(radius: 2)
                    
                    // Network Status Warning
                    if subscriptionManager.isOffline {
                        HStack {
                            Image(systemName: "wifi.slash")
                                .foregroundColor(.red)
                            Text("You appear to be offline. Connect to the internet to subscribe.")
                                .font(.subheadline)
                                .foregroundColor(.red)
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    // Credits & Legal Section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Credits & Legal")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Link("Privacy Policy", destination: URL(string: "https://embalmpro.tech/privacy_policy.html")!)
                        Link("Terms of Use", destination: URL(string: "https://embalmpro.tech/terms_of_use.html")!)
                        
                        Text("EmbalmPro™ is a registered trademark of CHBI, Inc. dba EmbalmPro")
                            .font(.caption)
                        Text("© 2025 CHBI, Inc. dba EmbalmPro. All rights reserved.")
                            .font(.caption)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(radius: 2)
                    
                    // Professional Experience
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Professional Experience")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("This application integrates knowledge from my experience as a licensed Embalmer and Funeral Director, summarizing industry standard techniques. It combines my mortuary school education and over 20 years of field experience as a licensed embalmer.")
                            .font(.subheadline)
                        
                        Text("Special thanks to Jay Moffet, Trade Embalmer, for his knowledge and embalming tips, and Dr. Cyril Wecht, my embalming lab professor, and to my wife, for tolerating this rather unusual passion.")
                            .font(.subheadline)
                            .italic()
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(radius: 2)
                    
                    // Reference Materials
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Reference Materials")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Reference works were consulted for consistency with industry standards. Books used for reference are listed below:")
                            .font(.subheadline)
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("• Frederick, J. F. (1987, March). The mathematics of embalming chemistry. The Dodge Magazine, 10-11, 30. The Dodge Company. (Reprinted from The Dodge Magazine, October 1968)")
                            Text("• Mayer, Robert G. (2005). Embalming: History, Theory, and Practice (4th ed.). McGraw-Hill Medical.")
                            Text("• Strub, C. G., & Frederick, L. G. (1989). Principles and practices of embalming (5th ed.). Professional Training Skills Inc. & Robertine Frederick.")
                        }
                        .font(.footnote)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(radius: 2)
                    
                    // Disclaimer
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Disclaimer")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Safety Data Sheet (SDS) content in this app is extracted from publicly available manufacturer documents and presented solely for informational and compliance purposes under OSHA regulations. While the SDS information consists primarily of factual, regulatory-mandated content, any proprietary branding, formatting, or commentary originally present has been removed. All trademarks and copyrights remain the property of their respective owners.")
                            .font(.subheadline)
                            .italic()
                        
                        Text("All registered trademarks for embalming fluids are used for informational purposes only. This app does not claim rights to these trademarks.")
                            .font(.subheadline)
                            .italic()
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(radius: 2)
                    
                    // User Guide Button
                    NavigationLink(destination: UserGuideView()) {
                        Text("View User Guide")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .frame(width: 160, height: 36)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    
                    // Get Started Button - Only show if subscribed
                    if subscriptionManager.isSubscribed {
                        Button(action: {
                            print("Get Started button tapped")
                            dismissWelcome()
                        }) {
                            Text("Get Started")
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .frame(width: 160, height: 36)
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                        .padding(.top, 10)
                        
                        // Don't show again toggle - Only show if subscribed
                        Toggle(isOn: Binding(
                            get: { dontShowWelcomeAgain },
                            set: { newValue in
                                print("Toggle changed to: \(newValue)")
                                dontShowWelcomeAgain = newValue
                            }
                        )) {
                            Text("Don't show this screen again")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            // Only show toolbar items if subscribed
            .toolbar {
                if subscriptionManager.isSubscribed {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Get Started") {
                            print("Toolbar Get Started tapped")
                            dismissWelcome()
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    if !isPresented {
                        Button("Back") {
                            dismiss()
                        }
                    }
                }
            }
            // Prevent dismissal if not subscribed
            .interactiveDismissDisabled(!subscriptionManager.isSubscribed)
            .sheet(isPresented: $showErrorSheet) {
                if let error = subscriptionManager.actionableError {
                    SubscriptionErrorView(error: error)
                } else if subscriptionManager.isOffline {
                    // Create a network error view
                    SubscriptionErrorView(error: SubscriptionError(
                        message: "You're currently offline. Please connect to the internet to complete subscription actions.",
                        primaryActionTitle: "Check Network Settings",
                        primaryAction: { subscriptionManager.checkNetwork() },
                        secondaryActionTitle: "Dismiss",
                        secondaryAction: nil
                    ))
                    .presentationDetents([.medium])
                } else if subscriptionManager.errorMessage != nil {
                    // Generic error case
                    SubscriptionErrorView(error: SubscriptionError(
                        message: subscriptionManager.errorMessage ?? "An error occurred",
                        primaryActionTitle: "Try Again",
                        primaryAction: {
                            Task {
                                await subscriptionManager.loadProducts()
                            }
                        },
                        secondaryActionTitle: "Dismiss",
                        secondaryAction: nil
                    ))
                    .presentationDetents([.medium])
                }
            }
            .sheet(isPresented: $showTroubleshooting) {
                SubscriptionTroubleshootingView()
            }
            .onChange(of: subscriptionManager.showTroubleshooting) { newValue in
                if newValue {
                    showTroubleshooting = true
                    subscriptionManager.showTroubleshooting = false
                }
            }
            .onAppear {
                print("WelcomeView appeared")
                print("Current dontShowWelcomeAgain value: \(dontShowWelcomeAgain)")
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#if os(iOS)
@available(iOS 16.0, *)
struct SubscriptionManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var subscriptionStatus: String = "Loading..."
    @State private var expirationDate: String = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Subscription Details")
                    .font(.headline)
                Text(subscriptionStatus)
                if !expirationDate.isEmpty {
                    Text("Expires: \(expirationDate)")
                }
                
                Button("Manage Subscription") {
                    Task {
                        await manageSubscription()
                    }
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadSubscriptionStatus()
            }
        }
    }
    
    private func loadSubscriptionStatus() async {
        if let result = await StoreKit.Transaction.latest(for: "com.pfeifer.embalmpro.annualsubscription") {
            switch result {
            case .verified(let transaction):
                subscriptionStatus = "Status: Active"
                expirationDate = transaction.expirationDate?.formatted() ?? "N/A"
            case .unverified:
                subscriptionStatus = "Unable to verify subscription"
            }
        } else {
            subscriptionStatus = "No active subscription found"
        }
    }
    
    private func manageSubscription() async {
        if let result = await StoreKit.Transaction.latest(for: "com.pfeifer.embalmpro.annualsubscription") {
            if case .verified(let transaction) = result {
                await transaction.finish()
                if let url = URL(string: "https://apps.apple.com/account/subscriptions?appId=com.pfeifer.embalmpro") {
                    await UIApplication.shared.open(url)
                }
            }
        }
    }
}
#endif

#Preview {
    WelcomeView(isPresented: .constant(true))
}

