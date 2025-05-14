import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                FluidsView()
                    .tabItem {
                        Label("Fluids", systemImage: "flask.fill")
                    }
                    .tag(0)
                    .id(selectedTab)
                
                CaseView()
                    .tabItem {
                        Label("Case Analysis", systemImage: "figure")
                    }
                    .tag(1)
                    .id(selectedTab)
                
                CH2OView()
                    .tabItem {
                        Label("CH₂O", systemImage: "function")
                    }
                    .tag(2)
                    .id(selectedTab)
                
                SDSView()
                    .tabItem {
                        Label("SDS", systemImage: "doc.text")
                    }
                    .tag(3)
                    .id(selectedTab)
                
                FavoritesView()
                    .tabItem {
                        Label("Favorites", systemImage: "star.fill")
                    }
                    .tag(4)
                    .id(selectedTab)
            }
            .onChange(of: selectedTab) { _ in
                NotificationCenter.default.post(name: NSNotification.Name("ResetNavigation"), object: nil)
            }
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
