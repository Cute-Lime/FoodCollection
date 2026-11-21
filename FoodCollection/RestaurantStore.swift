import Foundation
import Observation

/// 管理所有收藏的餐廳
@Observable
final class RestaurantStore {
    static let shared = RestaurantStore()

    private(set) var restaurants: [Restaurant] = []
    private let fileURL = URL.documentsDirectory.appending(path: "restaurants.json")

    init() { load() }

    func restaurant(id: UUID) -> Restaurant? {
        restaurants.first { $0.id == id }
    }

    func upsert(_ restaurant: Restaurant) {
        if let index = restaurants.firstIndex(where: { $0.id == restaurant.id }) {
            restaurants[index] = restaurant
        } else {
            restaurants.insert(restaurant, at: 0)
        }
        save()
    }

    func delete(_ restaurant: Restaurant) {
        restaurants.removeAll { $0.id == restaurant.id }
        save()
    }

    func toggleFavorite(_ restaurant: Restaurant) {
        guard let index = restaurants.firstIndex(where: { $0.id == restaurant.id }) else { return }
        restaurants[index].isFavorite.toggle()
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let list = try? JSONDecoder().decode([Restaurant].self, from: data)
        else { return }
        restaurants = list
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(restaurants) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
