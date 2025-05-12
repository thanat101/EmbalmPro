import SwiftUI

struct TroubleshootingItem: View {
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

struct SubscriptionTroubleshootingView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    Text("Subscription Troubleshooting")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom)
                    
                    #if targetEnvironment(simulator)
                    GroupBox(label: Text("Testing in Simulator").font(.headline)) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("The Simulator cannot process real purchases. To test subscriptions:")
                                .font(.subheadline)
                                .padding(.bottom, 5)
                            
                            Text("1. Use a real device for testing real purchases")
                                .font(.subheadline)
                            Text("2. Enable StoreKit testing in Xcode:")
                                .font(.subheadline)
                            Text("   • Open Xcode")
                                .font(.subheadline)
                            Text("   • Go to Product > Scheme > Edit Scheme")
                                .font(.subheadline)
                            Text("   • Select 'Run' and check 'StoreKit Configuration'")
                                .font(.subheadline)
                            Text("   • Select your Configuration.storekit file")
                                .font(.subheadline)
                        }
                        .padding(.vertical)
                    }
                    .padding(.bottom)
                    #endif
                    
                    GroupBox(label: Text("Common Issues").font(.headline)) {
                        VStack(alignment: .leading, spacing: 12) {
                            TroubleshootingItem(icon: "wifi.slash", title: "Network Issues", description: "Make sure you have a stable internet connection before making purchases.")
                            
                            TroubleshootingItem(icon: "creditcard", title: "Payment Method", description: "Verify your Apple ID has a valid payment method in App Store settings.")
                            
                            TroubleshootingItem(icon: "lock.shield", title: "Restrictions", description: "Check if you have any purchase restrictions enabled in Screen Time settings.")
                            
                            TroubleshootingItem(icon: "person.crop.circle", title: "Apple ID", description: "Ensure you're signed into the correct Apple ID that made the purchase.")
                        }
                        .padding(.vertical)
                    }
                    .padding(.bottom)
                    
                    GroupBox(label: Text("Recommended Steps").font(.headline)) {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("1. Restart the app")
                            Text("2. Try the 'Restore Purchases' button")
                            Text("3. Sign out of the App Store and sign back in")
                            Text("4. Restart your device")
                            Text("5. Check for iOS updates")
                        }
                        .padding(.vertical)
                    }
                    .padding(.bottom)
                    
                    GroupBox {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Still having issues?")
                                .font(.headline)
                            
                            Button(action: {
                                subscriptionManager.contactSupport()
                            }) {
                                HStack {
                                    Image(systemName: "envelope")
                                    Text("Contact Support")
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                            }
                        }
                        .padding(.vertical)
                    }
                }
                .padding()
            }
            .navigationBarTitle("Troubleshooting", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SubscriptionTroubleshootingView()
} 