import SwiftUI

struct FilterButton: View {
    let title: String
    @Binding var selection: String
    let options: [String]
    @State private var showMenu = false
    
    var body: some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button(action: {
                    selection = option
                }) {
                    HStack {
                        Text(option)
                        if option == selection {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack {
                Text(title)
                    .font(AppStyle.Typography.caption)
                    .foregroundColor(AppStyle.textColor)
                
                Text(selection)
                    .font(AppStyle.Typography.caption)
                    .foregroundColor(AppStyle.accentColor)
                
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(AppStyle.accentColor)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
}

#Preview {
    VStack {
        FilterButton(
            title: "Manufacturer",
            selection: .constant("All"),
            options: ["All", "Option 1", "Option 2"]
        )
        
        FilterButton(
            title: "Type",
            selection: .constant("Option 1"),
            options: ["All", "Option 1", "Option 2"]
        )
    }
    .padding()
} 