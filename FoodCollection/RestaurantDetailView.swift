import SwiftUI

/// 餐廳詳細頁
struct RestaurantDetailView: View {
    private let store = RestaurantStore.shared
    let restaurantID: UUID
    @State private var editItem: FormItem?

    private var restaurant: Restaurant? { store.restaurant(id: restaurantID) }

    var body: some View {
        Group {
            if let restaurant {
                content(restaurant)
            } else {
                ContentUnavailableView("找不到這間餐廳", systemImage: "questionmark.circle")
            }
        }
        .themedBackground()
        .navigationTitle(restaurant?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("編輯", systemImage: "pencil") {
                    if let restaurant { editItem = FormItem(restaurant: restaurant) }
                }
            }
        }
        .navigationDestination(item: $editItem) {
            RestaurantFormView(restaurant: $0.restaurant)
        }
    }

    private func content(_ restaurant: Restaurant) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                if let data = restaurant.photoData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 240)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                }

                header(restaurant)
                infoCard(restaurant)

                if !restaurant.revisitList.isEmpty {
                    revisitCard(restaurant)
                }
                if !restaurant.note.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("心得筆記", systemImage: "square.and.pencil").font(.headline)
                        Text(restaurant.note)
                    }
                    .card()
                }
            }
            .padding()
        }
    }

    private func header(_ restaurant: Restaurant) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(restaurant.name).font(.title.bold())
                if restaurant.isFavorite {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.red)
                        .symbolEffect(.bounce, value: restaurant.isFavorite)
                }
                Spacer()
                if restaurant.isOpenNow {
                    Text("營業中")
                        .font(.caption.bold())
                        .foregroundStyle(.green)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.15), in: Capsule())
                }
            }
            Label(
                restaurant.address.isEmpty ? "未填寫地點" : restaurant.address,
                systemImage: "mappin.and.ellipse"
            )
            .foregroundStyle(.secondary)

            HStack {
                Label(restaurant.cuisine.rawValue, systemImage: restaurant.cuisine.symbol)
                    .font(.subheadline)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.2), in: Capsule())
                RatingStars(rating: restaurant.rating)
            }
        }
        .card()
    }

    private func infoCard(_ restaurant: Restaurant) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("營業資訊", systemImage: "clock.fill").font(.headline)

            HStack(spacing: 6) {
                ForEach(Weekday.allCases) { day in
                    let isOn = restaurant.openDays.contains(day)
                    Text(day.shortName)
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity, minHeight: 34)
                        .foregroundStyle(isOn ? Color.white : Color.secondary)
                        .background(
                            isOn ? Color.accentColor : Color(.tertiarySystemFill),
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                }
            }

            infoRow("營業時間", restaurant.hoursText)
            infoRow("人均預算", "$\(restaurant.budget)")
            infoRow("造訪日期", restaurant.visitDate.formatted(date: .abbreviated, time: .omitted))
        }
        .card()
    }

    private func infoRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(.secondary)
            Spacer()
            Text(value)
        }
    }

    private func revisitCard(_ restaurant: Restaurant) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("想再訪的日期", systemImage: "calendar.badge.clock").font(.headline)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], alignment: .leading) {
                ForEach(restaurant.revisitList, id: \.self) { date in
                    Text(date.formatted(.dateTime.year().month().day()))
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.accentColor.opacity(0.2), in: Capsule())
                }
            }
        }
        .card()
    }
}
