import SwiftUI

/// Shows the GHS placard from the asset catalog when available; uses a small fallback icon on device when the image is not in the bundle.
struct GHSPlacardImage: View {
    let name: String
    var size: CGFloat = 24
    
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
