import SwiftUI
import UIKit

struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    @FocusState private var isFocused: Bool
    @Environment(\.dismissSearch) private var dismissSearch
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .focused($isFocused)
                .submitLabel(.search)
                .onSubmit {
                    isFocused = false
                }
                .onChange(of: text) { newValue in
                    if newValue.isEmpty {
                        isFocused = false
                    }
                }
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                    isFocused = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal)
        .background(Color(.systemBackground))
    }
}

// Environment key for dismissing search
private struct DismissSearchKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

extension EnvironmentValues {
    var dismissSearch: () -> Void {
        get { self[DismissSearchKey.self] }
        set { self[DismissSearchKey.self] = newValue }
    }
}

// View modifier to dismiss keyboard on tap outside
struct KeyboardDismissModifier: ViewModifier {
    @Environment(\.dismissSearch) private var dismissSearch
    
    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .onTapGesture {
                dismissSearch()
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { _ in
                        dismissSearch()
                    }
            )
    }
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        self.modifier(KeyboardDismissModifier())
    }
}

// Use traditional PreviewProvider instead of #Preview macro
struct SearchBar_Previews: PreviewProvider {
    static var previews: some View {
        SearchBar(text: .constant(""), placeholder: "Search...")
            .padding()
            .previewLayout(.sizeThatFits)
    }
} 