import PhotosUI
import SwiftUI

/// 新增／編輯餐廳
struct RestaurantFormView: View {
    private let store = RestaurantStore.shared
    @Environment(\.dismiss) private var dismiss

    @State private var draft: Restaurant
    @State private var pickerItem: PhotosPickerItem?
    @State private var showRevisitPicker = false
    @State private var alertInfo: AlertInfo?
    private let isEditing: Bool

    init(restaurant: Restaurant?) {
        _draft = State(initialValue: restaurant ?? Restaurant())
        isEditing = restaurant != nil
    }

    var body: some View {
        Form {
            basicSection
            hoursSection
            reviewSection
            photoSection
            noteSection
        }
        .scrollContentBackground(.hidden)
        .themedBackground()
        .navigationTitle(isEditing ? "編輯餐廳" : "新增餐廳")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("儲存", action: save)
            }
        }
        // 開店時間一定要早於打烊時間
        .onChange(of: draft.openTime) { _, newValue in
            if draft.closeTime <= newValue { draft.closeTime = newValue + 0.5 }
        }
        .onChange(of: draft.closeTime) { _, newValue in
            if draft.openTime >= newValue { draft.openTime = newValue - 0.5 }
        }
        // 選到照片後轉成圖片資料
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task { await loadPhoto(item) }
        }
        .infoAlert($alertInfo)
    }

    // MARK: 基本資料
    private var basicSection: some View {
        Section("基本資料") {
            TextField("餐廳名稱", text: $draft.name)
            TextField("地點", text: $draft.address)
            Picker("料理類別", selection: $draft.cuisine) {
                ForEach(Cuisine.allCases) { cuisine in
                    Label(cuisine.rawValue, systemImage: cuisine.symbol).tag(cuisine)
                }
            }
        }
    }

    // MARK: 營業時間
    private var hoursSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("營業日（點選切換）")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    ForEach(Weekday.allCases) { day in
                        weekdayChip(day)
                    }
                }
            }
            .padding(.vertical, 4)

            VStack(alignment: .leading) {
                LabeledContent("開店時間", value: timeText(draft.openTime))
                Slider(value: $draft.openTime, in: 0...23.5, step: 0.5)
            }
            VStack(alignment: .leading) {
                LabeledContent("打烊時間", value: timeText(draft.closeTime))
                Slider(value: $draft.closeTime, in: 0.5...24, step: 0.5)
            }
        } header: {
            Text("營業時間")
        } footer: {
            Text("\(draft.openDaysText)　\(draft.hoursText)")
        }
    }

    private func weekdayChip(_ day: Weekday) -> some View {
        let isOn = draft.openDays.contains(day)
        return Text(day.shortName)
            .font(.subheadline.bold())
            .frame(maxWidth: .infinity, minHeight: 38)
            .foregroundStyle(isOn ? Color.white : Color.primary)
            .background(
                isOn ? Color.accentColor : Color(.tertiarySystemFill),
                in: RoundedRectangle(cornerRadius: 10)
            )
            .onTapGesture {
                withAnimation(.snappy) {
                    if isOn {
                        _ = draft.openDays.remove(day)
                    } else {
                        _ = draft.openDays.insert(day)
                    }
                }
            }
            .accessibilityLabel("週\(day.shortName)")
            .accessibilityAddTraits(.isButton)
            .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    // MARK: 我的評價
    private var reviewSection: some View {
        Section("我的評價") {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("好吃程度")
                    Spacer()
                    RatingStars(rating: draft.rating)
                    Text(String(format: "%.1f", draft.rating))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Slider(value: $draft.rating, in: 1...5, step: 0.5)
            }

            Stepper(
                "人均預算：$\(draft.budget)",
                value: $draft.budget,
                in: 0...5000,
                step: 50
            )

            Toggle("加入最愛", systemImage: "heart.fill", isOn: $draft.isFavorite)

            DatePicker(
                "造訪日期",
                selection: $draft.visitDate,
                in: ...Date.now,
                displayedComponents: .date
            )

            DisclosureGroup(
                "想再訪的日期（\(draft.revisitDates.count)）",
                isExpanded: $showRevisitPicker
            ) {
                MultiDatePicker(
                    "想再訪的日期",
                    selection: $draft.revisitDates,
                    in: Date.now...
                )
            }
        }
    }

    // MARK: 照片
    private var photoSection: some View {
        Section("餐廳照片（選填）") {
            if let data = draft.photoData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .frame(maxWidth: .infinity)
                    .transition(.scale.combined(with: .opacity))
            }

            PhotosPicker(selection: $pickerItem, matching: .images) {
                Label(
                    draft.photoData == nil ? "選擇照片" : "更換照片",
                    systemImage: "photo.on.rectangle"
                )
            }

            if draft.photoData != nil {
                Button(role: .destructive) {
                    withAnimation {
                        draft.photoData = nil
                        pickerItem = nil
                    }
                } label: {
                    Label("移除照片", systemImage: "trash")
                }
            }
        }
    }

    // MARK: 心得
    private var noteSection: some View {
        Section("心得筆記") {
            TextEditor(text: $draft.note)
                .frame(minHeight: 120)
                .overlay(alignment: .topLeading) {
                    if draft.note.isEmpty {
                        Text("寫下好吃的菜色、推薦的點餐…")
                            .foregroundStyle(.tertiary)
                            .padding(.top, 8)
                            .padding(.leading, 5)
                            .allowsHitTesting(false)
                    }
                }
        }
    }

    // MARK: 動作
    private func loadPhoto(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data),
              let jpeg = image.resized(maxSide: 1200).jpegData(compressionQuality: 0.7)
        else { return }
        withAnimation { draft.photoData = jpeg }
    }

    private func save() {
        draft.name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !draft.name.isEmpty else {
            alertInfo = AlertInfo(title: "請輸入餐廳名稱", message: "名稱是必填欄位。")
            return
        }
        guard !draft.openDays.isEmpty else {
            alertInfo = AlertInfo(title: "請選擇營業日", message: "至少要選擇一天。")
            return
        }

        store.upsert(draft)
        alertInfo = AlertInfo(
            title: isEditing ? "更新成功" : "新增成功",
            message: "「\(draft.name)」已儲存到收藏。"
        ) {
            dismiss()
        }
    }
}
