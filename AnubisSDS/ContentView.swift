import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                FluidsView()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text("Fluids Database")
                                .font(AppStyle.Typography.headline)
                                .foregroundColor(AppStyle.textColor)
            }
                    }
            }
                    .tabItem {
                        Label("Fluids", systemImage: "flask.fill")
                    }
                    .tag(0)
                
            NavigationStack {
                CaseView()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text("Case Analysis")
                                .font(AppStyle.Typography.headline)
                                .foregroundColor(AppStyle.textColor)
                        }
                    }
            }
                    .tabItem {
                        Label("Case Analysis", systemImage: "figure")
                    }
                    .tag(1)
                
            NavigationStack {
                CH2OView()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text("CH₂O Calculator")
                                .font(AppStyle.Typography.headline)
                                .foregroundColor(AppStyle.textColor)
                        }
                    }
            }
                    .tabItem {
                        Label("CH₂O", systemImage: "function")
                    }
                    .tag(2)
                
            NavigationStack {
                SDSView()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text("SDS Database")
                                .font(AppStyle.Typography.headline)
                                .foregroundColor(AppStyle.textColor)
                        }
                    }
            }
                    .tabItem {
                        Label("SDS", systemImage: "doc.text")
                    }
                    .tag(3)
                
            NavigationStack {
                FavoritesView()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text("Favorites")
                                .font(AppStyle.Typography.headline)
                                .foregroundColor(AppStyle.textColor)
                        }
                    }
            }
                    .tabItem {
                        Label("Favorites", systemImage: "star.fill")
                    }
                    .tag(4)
        }
                    .id(selectedTab)
            .onChange(of: selectedTab) { _ in
                NotificationCenter.default.post(name: NSNotification.Name("ResetNavigation"), object: nil)
        }
    }
}

struct SearchView: View {
    var body: some View {
        NavigationView {
            Color.clear
                .navigationTitle("Search")
        }
    }
}

#Preview {
    ContentView()
}
