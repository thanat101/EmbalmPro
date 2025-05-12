import StoreKit
import SwiftUI
import Network

@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    @Published var isSubscribed = false
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var actionableError: SubscriptionError?
    @Published var isInitialized = false
    @Published var isOffline = false
    @Published var showTroubleshooting = false
    
    // Add preview mode property
    static var previewMode = false
    
    private let productID = "com.pfeifer.embalmpro.annualsubscription"
    private var updateListenerTask: Task<Void, Error>?
    private var networkMonitor: NWPathMonitor?
    
    internal init() {
        // Check if we're in preview mode
        if Self.previewMode {
            isSubscribed = true
            isInitialized = true
            return
        }
        
        updateListenerTask = listenForTransactions()
        setupNetworkMonitoring()
        Task {
            await loadProducts()
            await checkSubscriptionStatus()
            isInitialized = true
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
        networkMonitor?.cancel()
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor = NWPathMonitor()
        networkMonitor?.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isOffline = path.status != .satisfied
                if self?.isOffline == true {
                    self?.errorMessage = "You appear to be offline. Please check your internet connection."
                } else {
                    // Clear network-related error message if we're back online
                    if self?.errorMessage?.contains("offline") == true {
                        self?.errorMessage = nil
                    }
                }
            }
        }
        let queue = DispatchQueue(label: "NetworkMonitor")
        networkMonitor?.start(queue: queue)
    }
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached { [weak self] in
            guard let self = self else { return }
            for await result in StoreKit.Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await self.updateSubscriptionStatus(transaction)
                    await transaction.finish()
                } catch {
                    await MainActor.run {
                        self.handleError(error)
                    }
                }
            }
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    func loadProducts() async {
        if isOffline {
            errorMessage = "You're offline. Please connect to the internet and try again."
            return
        }
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            actionableError = nil
        }
        
        do {
            let loadedProducts = try await Product.products(for: [productID])
            
            await MainActor.run {
                products = loadedProducts
                isLoading = false
                
                if loadedProducts.isEmpty {
                    let error = SubscriptionError(
                        message: "No subscription products were found. This could be a temporary issue with the App Store.",
                        primaryActionTitle: "Try Again",
                        primaryAction: { Task { await self.loadProducts() } },
                        secondaryActionTitle: "Contact Support",
                        secondaryAction: { self.contactSupport() }
                    )
                    self.actionableError = error
                }
            }
        } catch {
            await MainActor.run {
                handleError(error)
                isLoading = false
            }
        }
    }
    
    func checkSubscriptionStatus() async {
        do {
            guard let result = await StoreKit.Transaction.latest(for: productID) else {
                await MainActor.run {
                    isSubscribed = false
                }
                return
            }
            
            let transaction = try checkVerified(result)
            await updateSubscriptionStatus(transaction)
        } catch {
            await MainActor.run {
                handleError(error)
                isSubscribed = false
            }
        }
    }
    
    private func updateSubscriptionStatus(_ transaction: StoreKit.Transaction) async {
        await MainActor.run {
            isSubscribed = transaction.revocationDate == nil && !transaction.isUpgraded
            
            // Clear error messages if the subscription is now active
            if isSubscribed {
                errorMessage = nil
                actionableError = nil
            }
        }
    }
    
    func purchase(maxRetries: Int = 2) async {
        if isOffline {
            errorMessage = "You're offline. Please connect to the internet and try again."
            return
        }
        
        // First try to reload products if none are available
        if products.isEmpty {
            await loadProducts()
        }
        
        // Check again if products were loaded
        if products.isEmpty {
            await MainActor.run {
                // Create an actionable error that will be displayed to the user
                actionableError = SubscriptionError(
                    message: "Unable to connect to the App Store. This could be due to network issues or the subscription product may not be available yet.",
                    primaryActionTitle: "Reload Products",
                    primaryAction: { Task { await self.loadProducts() } },
                    secondaryActionTitle: "Contact Support",
                    secondaryAction: { self.contactSupport() }
                )
                
                // Show the error sheet by setting an error message
                errorMessage = "Unable to connect to the App Store."
            }
            return
        }
        
        guard let product = products.first else {
            return  // This should never happen since we checked above, but keeping it as safety
        }
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            actionableError = nil
        }
        
        var attempts = 0
        var shouldRetry = false
        
        repeat {
            attempts += 1
            shouldRetry = false
            
            do {
                let result = try await product.purchase()
                switch result {
                case .success(let verification):
                    let transaction = try checkVerified(verification)
                    await updateSubscriptionStatus(transaction)
                    await transaction.finish()
                case .userCancelled:
                    // User cancelled, no need to show error
                    break
                case .pending:
                    await MainActor.run {
                        errorMessage = "Your purchase is pending approval. You'll be notified once it's approved."
                    }
                @unknown default:
                    await MainActor.run {
                        handleError(StoreError.unknown)
                    }
                }
            } catch {
                if let error = error as? StoreError,
                   (error == .networkError || error == .temporaryIssue),
                   attempts <= maxRetries {
                    // Network error or temporary issue - retry
                    shouldRetry = true
                    // Wait before retrying
                    try? await Task.sleep(nanoseconds: UInt64(1_000_000_000 * attempts))
                } else {
                    await MainActor.run {
                        handleError(error)
                    }
                }
            }
        } while shouldRetry
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    func restorePurchases() async {
        if isOffline {
            errorMessage = "You're offline. Please connect to the internet and try again."
            return
        }
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            actionableError = nil
        }
        
        do {
            try await AppStore.sync()
            await checkSubscriptionStatus()
            
            // If still not subscribed after restore, show a message
            if !isSubscribed {
                await MainActor.run {
                    actionableError = SubscriptionError(
                        message: "No active subscription was found associated with your Apple ID.",
                        primaryActionTitle: "Subscribe Now",
                        primaryAction: { Task { await self.purchase() } },
                        secondaryActionTitle: "Show Troubleshooting Tips",
                        secondaryAction: { self.showTroubleshooting = true }
                    )
                }
            }
        } catch {
            await MainActor.run {
                handleError(error)
            }
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    func handleError(_ error: Error) {
        let friendlyMessage = friendlyErrorMessage(for: error)
        errorMessage = friendlyMessage.message
        
        // Create actionable error based on error type
        if let storeError = error as? StoreError {
            switch storeError {
            case .failedVerification:
                actionableError = SubscriptionError(
                    message: friendlyMessage.message,
                    primaryActionTitle: "Restore Purchases",
                    primaryAction: { Task { await self.restorePurchases() } },
                    secondaryActionTitle: "Contact Support",
                    secondaryAction: { self.contactSupport() }
                )
            case .networkError:
                actionableError = SubscriptionError(
                    message: friendlyMessage.message,
                    primaryActionTitle: "Try Again",
                    primaryAction: { Task { await self.purchase() } },
                    secondaryActionTitle: "Check Network",
                    secondaryAction: { self.checkNetwork() }
                )
            default:
                actionableError = SubscriptionError(
                    message: friendlyMessage.message,
                    primaryActionTitle: "Try Again",
                    primaryAction: { Task { await self.purchase() } },
                    secondaryActionTitle: "Show Troubleshooting Tips",
                    secondaryAction: { self.showTroubleshooting = true }
                )
            }
        } else if let skError = error as? SKError {
            // Handle SK specific errors
            switch skError.code {
            case .paymentCancelled:
                // Don't show actionable error for user cancellations
                actionableError = nil
            case .paymentNotAllowed:
                actionableError = SubscriptionError(
                    message: friendlyMessage.message,
                    primaryActionTitle: "Check Settings",
                    primaryAction: { self.openSettings() },
                    secondaryActionTitle: "Show Troubleshooting Tips",
                    secondaryAction: { self.showTroubleshooting = true }
                )
            default:
                actionableError = SubscriptionError(
                    message: friendlyMessage.message,
                    primaryActionTitle: "Try Again",
                    primaryAction: { Task { await self.purchase() } },
                    secondaryActionTitle: "Show Troubleshooting Tips",
                    secondaryAction: { self.showTroubleshooting = true }
                )
            }
        } else {
            // Generic error
            actionableError = SubscriptionError(
                message: friendlyMessage.message,
                primaryActionTitle: "Try Again",
                primaryAction: { Task { await self.purchase() } },
                secondaryActionTitle: "Contact Support",
                secondaryAction: { self.contactSupport() }
            )
        }
    }
    
    func friendlyErrorMessage(for error: Error) -> (message: String, technical: String) {
        // Get the original technical error message
        let technicalMessage = error.localizedDescription
        
        // Return a user-friendly message based on error type
        if let storeError = error as? StoreError {
            switch storeError {
            case .failedVerification:
                return ("We couldn't verify your purchase with the App Store. This may be temporary.", technicalMessage)
            case .networkError:
                return ("Network connection issue. Please check your internet and try again.", technicalMessage)
            case .temporaryIssue:
                return ("The App Store is experiencing temporary issues. Please try again later.", technicalMessage)
            case .unknown:
                return ("An unknown error occurred with your purchase. Please try again.", technicalMessage)
            }
        } else if let skError = error as? SKError {
            switch skError.code {
            case .paymentCancelled:
                return ("Purchase was cancelled.", technicalMessage)
            case .paymentInvalid:
                return ("There was a problem with the payment information. Please check your App Store payment method.", technicalMessage)
            case .paymentNotAllowed:
                return ("This device is not authorized to make purchases. Please check your device settings and restrictions.", technicalMessage)
            case .storeProductNotAvailable:
                return ("This subscription is not available in your region or App Store account.", technicalMessage)
            case .cloudServiceNetworkConnectionFailed:
                return ("Cannot connect to the App Store. Please check your internet connection and try again.", technicalMessage)
            default:
                return ("App Store error: \(skError.localizedDescription). Please try again later.", technicalMessage)
            }
        }
        
        // Generic error handling
        if technicalMessage.lowercased().contains("network") {
            return ("Network connection issue. Please check your internet and try again.", technicalMessage)
        } else if technicalMessage.lowercased().contains("cancel") {
            return ("Purchase was cancelled.", technicalMessage)
        } else {
            return ("Something went wrong. Please try again or contact support if the problem persists.", technicalMessage)
        }
    }
    
    // Helper functions for actions
    func contactSupport() {
        if let url = URL(string: "mailto:support@embalmpro.tech") {
            UIApplication.shared.open(url)
        }
    }
    
    func openSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
    
    func checkNetwork() {
        if let url = URL(string: "App-prefs:root=WIFI") {
            UIApplication.shared.open(url)
        }
    }
}

// Enhanced error types
enum StoreError: Error {
    case failedVerification
    case networkError
    case temporaryIssue
    case unknown
}

// Action-oriented error structure
struct SubscriptionError {
    let message: String
    let primaryActionTitle: String
    let primaryAction: () -> Void
    let secondaryActionTitle: String?
    let secondaryAction: (() -> Void)?
}

#if DEBUG
// Preview helper
extension SubscriptionManager {
    static var preview: SubscriptionManager {
        let manager = SubscriptionManager()
        manager.isSubscribed = true
        manager.isInitialized = true
        return manager
    }
}
#endif

