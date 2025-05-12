import SwiftUI

public struct SearchBar: View {
    @Binding private var text: String
    private let placeholder: String
    
    public init(text: Binding<String>, placeholder: String) {
        self._text = text
        self.placeholder = placeholder
    }
    
    public var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppStyle.secondaryTextColor)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(AppStyle.Typography.body)
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppStyle.secondaryTextColor)
                }
            }
        }
        .padding(AppStyle.Spacing.small)
        .background(AppStyle.cardBackgroundColor)
        .cornerRadius(AppStyle.CornerRadius.medium)
    }
}

#Preview {
    SearchBar(text: .constant(""), placeholder: "Search...")
} 