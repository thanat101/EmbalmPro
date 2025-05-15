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
                    
                    Text("This will reset the database to its original state. All edits and changes will be permanently lost.")
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
            Text("This will reset the database to its original state. All your edits and changes will be permanently lost. This action cannot be undone.")
        }
        .alert("⚠️ Final Confirmation", isPresented: $showFinalConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset Database", role: .destructive) {
                performReset()
            }
        } message: {
            Text("Are you absolutely sure you want to reset the database? This will permanently delete all your edits and changes.")
        }
        .alert("✅ Reset Complete", isPresented: $resetSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("The database has been successfully reset to its original state.")
        }
        .alert("❌ Reset Failed", isPresented: $resetError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Failed to reset the database. Please try again or contact support if the problem persists.")
        }
    }
    
    private func performReset() {
        if DatabaseManager.shared.resetDatabase() {
            resetSuccess = true
        } else {
            resetError = true
        }
    }
} 