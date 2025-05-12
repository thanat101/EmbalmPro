import Foundation

class FavoritesManager {
    static let shared = FavoritesManager()
    private let defaults = UserDefaults.standard
    private let favoritesKey = "favoriteFluids"
    
    private init() {}
    
    func addFavorite(fluidName: String) {
        var favorites = getFavorites()
        if !favorites.contains(fluidName) {
            favorites.append(fluidName)
            saveFavorites(favorites)
            NotificationCenter.default.post(name: NSNotification.Name("FavoritesChanged"), object: nil)
        }
    }
    
    func removeFavorite(fluidName: String) {
        var favorites = getFavorites()
        favorites.removeAll { $0 == fluidName }
        saveFavorites(favorites)
        NotificationCenter.default.post(name: NSNotification.Name("FavoritesChanged"), object: nil)
    }
    
    func isFavorite(fluidName: String) -> Bool {
        return getFavorites().contains(fluidName)
    }
    
    func getFavorites() -> [String] {
        return defaults.stringArray(forKey: favoritesKey) ?? []
    }
    
    private func saveFavorites(_ favorites: [String]) {
        defaults.set(favorites, forKey: favoritesKey)
    }
}
