import SwiftUI

struct SubscriptionErrorView: View {
    let error: SubscriptionError
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // Icon
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            // Title
            Text("Subscription Issue")
                .font(.headline)
                .fontWeight(.bold)
            
            // Error message
            Text(error.message)
                .multilineTextAlignment(.center)
                .font(.body)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            // Primary action button
            Button(action: {
                dismiss()
                error.primaryAction()
            }) {
                Text(error.primaryActionTitle)
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            
            // Secondary action button (if available)
            if let secondaryAction = error.secondaryAction, let title = error.secondaryActionTitle {
                Button(action: {
                    dismiss()
                    secondaryAction()
                }) {
                    Text(title)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            
            // Dismiss button
            Button(action: {
                dismiss()
            }) {
                Text("Dismiss")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.top, 5)
        }
        .padding()
        .frame(width: min(UIScreen.main.bounds.width - 40, 400))
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 5)
    }
}

#Preview {
    SubscriptionErrorView(error: SubscriptionError(
        message: "Test error message",
        primaryActionTitle: "Try Again",
        primaryAction: {},
        secondaryActionTitle: "Dismiss",
        secondaryAction: {}
    ))
}

