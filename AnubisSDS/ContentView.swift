import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    var body: some View {
        if horizontalSizeClass == .regular { // iPad
            // iPad Layout
            NavigationView {
                // Sidebar
                List {
                    Button(action: { selectedTab = 0 }) {
                        Label("Fluids", systemImage: "flask.fill")
                    }
                    .foregroundColor(selectedTab == 0 ? .blue : .primary)
                    
                    Button(action: { selectedTab = 1 }) {
                        Label("Case Analysis", systemImage: "figure")
                    }
                    .foregroundColor(selectedTab == 1 ? .blue : .primary)
                    
                    Button(action: { selectedTab = 2 }) {
                        Label("CH₂O", systemImage: "function")
                    }
                    .foregroundColor(selectedTab == 2 ? .blue : .primary)
                    
                    Button(action: { selectedTab = 3 }) {
                        Label("SDS", systemImage: "doc.text")
                    }
                    .foregroundColor(selectedTab == 3 ? .blue : .primary)
                    
                    Button(action: { selectedTab = 4 }) {
                        Label("Favorites", systemImage: "star.fill")
                    }
                    .foregroundColor(selectedTab == 4 ? .blue : .primary)
                }
                .navigationTitle("AnubisSDS")
                .listStyle(SidebarListStyle())
                
                // Detail View
                Group {
                    switch selectedTab {
                    case 0: FluidsView()
                    case 1: CaseView()
                    case 2: CH2OView()
                    case 3: SDSView()
                    case 4: FavoritesView()
                    default: FluidsView()
                    }
                }
            }
            .onChange(of: selectedTab) { _ in
                NotificationCenter.default.post(name: NSNotification.Name("ResetNavigation"), object: nil)
            }
        } else { // iPhone
            // iPhone Layout (your existing TabView)
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
