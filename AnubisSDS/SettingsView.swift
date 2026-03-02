import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showResetWarning = false
    @State private var showFinalConfirmation = false
    @State private var resetSuccess = false
    @State private var resetError = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppStyle.Spacing.large) {
                Text("Settings")
                    .font(.largeTitle)
                    .bold()
                    .padding(.bottom, 10)
                
                // Database Reset Section
                VStack(alignment: .leading, spacing: AppStyle.Spacing.medium) {
                    Text("Database Management")
                        .font(AppStyle.Typography.title)
                        .foregroundColor(AppStyle.textColor)
                    
                    Text("Reset Database")
                        .font(AppStyle.Typography.headline)
                        .foregroundColor(AppStyle.textColor)
                    
                    Text("Resets Fluids and Conditions to the original reference data. Your Case Log entries are not affected.")
                        .font(AppStyle.Typography.body)
                        .foregroundColor(AppStyle.textColor)
                        .padding(.bottom, 5)
                    
                    Button(action: {
                        showResetWarning = true
                    }) {
                        Text("Reset Database")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(10)
                    }
                }
                .padding()
                .cardStyle()
            }
            .padding()
        }
        .navigationTitle("Settings")
        .alert("⚠️ Warning: Database Reset", isPresented: $showResetWarning) {
            Button("Cancel", role: .cancel) { }
            Button("Continue", role: .destructive) {
                showFinalConfirmation = true
            }
        } message: {
            Text("Fluids and Conditions will be restored to the original reference data. Your Case Log will be kept. Edits to fluid/condition data cannot be undone.")
        }
        .alert("⚠️ Final Confirmation", isPresented: $showFinalConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset Reference Data", role: .destructive) {
                performReset()
            }
        } message: {
            Text("Reset Fluids and Conditions to original? Case Log will not be changed.")
        }
        .alert("✅ Reset Complete", isPresented: $resetSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Reference data has been reset. Use the refresh button on the Fluids tab to see changes. Case Log was not modified.")
        }
        .alert("❌ Reset Failed", isPresented: $resetError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Failed to reset the database. Please try again or contact support if the problem persists.")
        }
    }
    
    private func performReset() {
        if DatabaseManager.shared.resetReferenceDataOnly() {
            resetSuccess = true
        } else {
            resetError = true
        }
    }
} 