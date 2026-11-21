import SwiftUI

/// 主頁：收藏的美食餐廳列表
struct RestaurantListView: View {
    private let store = RestaurantStore.shared
    @AppStorage("themeHex") private var themeHex = Theme.defaultHex

    @State private var formItem: FormItem?
    @State private var deleteTarget: Restaurant?
    @State private var alertInfo: AlertInfo?

    private var themeColor: Binding<Color> {
        Binding(
            get: { Color(hex: themeHex) },
            set: { themeHex = $0.hex }
        )
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.restaurants) { restaurant in
                    NavigationLink(value: restaurant) {
                        RestaurantRow(restaurant: restaurant)
                    }
                    .listRowBackground(Rectangle().fill(.regularMaterial))
                    .contextMenu {
                        Button("編輯", systemImage: "pencil") {
                            formItem = FormItem(restaurant: restaurant)
                        }
                        Button(
                            restaurant.isFavorite ? "取消最愛" : "加入最愛",
                            systemImage: restaurant.isFavorite ? "heart.slash" : "heart"
                        ) {
                            withAnimation { store.toggleFavorite(restaurant) }
                        }
                        Button("刪除", systemImage: "trash", role: .destructive) {
                            deleteTarget = restaurant
                        }
                    }
                }
            }
            .animation(.default, value: store.restaurants.map(\.id))
            .scrollContentBackground(.hidden)
            .themedBackground()
            .overlay {
                if store.restaurants.isEmpty {
                    ContentUnavailableView(
                        "還沒有收藏的餐廳",
                        systemImage: "fork.knife",
                        description: Text("點右上角的 + 新增第一間")
                    )
                }
            }
            .navigationTitle("美食收藏")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    ColorPicker("主題色", selection: themeColor, supportsOpacity: false)
                        .labelsHidden()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("新增餐廳", systemImage: "plus") {
                        formItem = FormItem(restaurant: nil)
                    }
                }
            }
            .navigationDestination(for: Restaurant.self) {
                RestaurantDetailView(restaurantID: $0.id)
            }
            .navigationDestination(item: $formItem) {
                RestaurantFormView(restaurant: $0.restaurant)
            }
            // 刪除確認
            .alert(
                "確定要刪除嗎？",
                isPresented: Binding(
                    get: { deleteTarget != nil },
                    set: { if !$0 { deleteTarget = nil } }
                ),
                presenting: deleteTarget
            ) { target in
                Button("刪除", role: .destructive) { delete(target) }
                Button("取消", role: .cancel) {}
            } message: { target in
                Text("將刪除「\(target.name)」，此動作無法復原。")
            }
            // 刪除成功
            .infoAlert($alertInfo)
        }
    }

    private func delete(_ restaurant: Restaurant) {
        withAnimation { store.delete(restaurant) }
        Task {
            try? await Task.sleep(for: .milliseconds(400))
            alertInfo = AlertInfo(
                title: "刪除成功",
                message: "已從收藏中移除「\(restaurant.name)」。"
            )
        }
    }
}

/// 列表的一列
struct RestaurantRow: View {
    let restaurant: Restaurant

    var body: some View {
        HStack(spacing: 12) {
            thumbnail
                .overlay(alignment: .bottom) {
                    if restaurant.isOpenNow {
                        Text("營業中")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green, in: Capsule())
                            .offset(y: 5)
                    }
                }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(restaurant.name).font(.headline)
                    if restaurant.isFavorite {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                Label(
                    restaurant.address.isEmpty ? "未填寫地點" : restaurant.address,
                    systemImage: "mappin.and.ellipse"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

                HStack(spacing: 8) {
                    RatingStars(rating: restaurant.rating).font(.caption2)
                    Text(restaurant.cuisine.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.2), in: Capsule())
                }
                Text("\(restaurant.openDaysText)  \(restaurant.hoursText)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let data = restaurant.photoData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        } else {
            Image(systemName: restaurant.cuisine.symbol)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 64, height: 64)
                .background(Color.accentColor.gradient, in: RoundedRectangle(cornerRadius: 14))
        }
    }
}

#Preview {
    RestaurantListView()
}
