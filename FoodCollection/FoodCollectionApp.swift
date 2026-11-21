import SwiftUI

@main
struct FoodCollectionApp: App {
    @AppStorage("themeHex") private var themeHex = Theme.defaultHex

    var body: some Scene {
        WindowGroup {
            RestaurantListView()
                .tint(Color(hex: themeHex))
        }
    }
}
