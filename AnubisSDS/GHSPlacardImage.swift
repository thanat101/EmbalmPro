import SwiftUI

/// Shows the GHS placard from the asset catalog when available; uses a small fallback icon on device when the image is not in the bundle.
/// Use this everywhere hazard symbols appear so size and behavior stay uniform.
struct GHSPlacardImage: View {
    let name: String
    /// Uniform size used across FluidDetailView, SDSDetailView, and View Entire SDS. Change here to resize everywhere.
    static let standardSize: CGFloat = 40
    var size: CGFloat = GHSPlacardImage.standardSize
    
    var body: some View {
        if let uiImage = UIImage(named: name) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        } else {
            Image(systemName: "exclamationmark.triangle.fill")
                .resizable()
                .scaledToFit()
                .foregroundColor(.orange)
                .frame(width: size, height: size)
        }
    }
}
