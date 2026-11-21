import SwiftUI

/// 料理類別
enum Cuisine: String, CaseIterable, Identifiable, Codable {
    case japanese = "日式", korean = "韓式", chinese = "中式", western = "西式"
    case hotpot = "火鍋", dessert = "甜點", cafe = "咖啡廳", other = "其他"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .japanese: "fish.fill"
        case .korean: "flame.fill"
        case .chinese: "takeoutbag.and.cup.and.straw.fill"
        case .western: "fork.knife"
        case .hotpot: "cooktop.fill"
        case .dessert: "birthday.cake.fill"
        case .cafe: "cup.and.saucer.fill"
        case .other: "star.fill"
        }
    }
}

/// 星期
enum Weekday: Int, CaseIterable, Identifiable, Codable, Comparable {
    case monday = 1, tuesday, wednesday, thursday, friday, saturday, sunday

    var id: Int { rawValue }
    var shortName: String { ["一", "二", "三", "四", "五", "六", "日"][rawValue - 1] }

    static func < (lhs: Weekday, rhs: Weekday) -> Bool { lhs.rawValue < rhs.rawValue }
}

/// 一間收藏的餐廳
struct Restaurant: Identifiable, Codable, Hashable {
    var id = UUID()
    var name = ""
    var address = ""
    var cuisine = Cuisine.japanese
    var openDays: Set<Weekday> = Set(Weekday.allCases)
    var openTime = 11.0
    var closeTime = 21.0
    var rating = 4.0
    var budget = 300
    var visitDate = Date()
    var revisitDates: Set<DateComponents> = []
    var isFavorite = false
    var note = ""
    var photoData: Data?

    var openDaysText: String {
        let days = openDays.sorted()
        if days.count == 7 { return "每天營業" }
        guard let first = days.first, let last = days.last else { return "未設定營業日" }
        if days.count >= 3, last.rawValue - first.rawValue == days.count - 1 {
            return "週\(first.shortName)至週\(last.shortName)"
        }
        return "週" + days.map(\.shortName).joined(separator: "、")
    }

    var hoursText: String { "\(timeText(openTime))–\(timeText(closeTime))" }

    var isOpenNow: Bool {
        let calendar = Calendar.current
        let now = Date()
        let weekday = calendar.component(.weekday, from: now)
        guard let today = Weekday(rawValue: weekday == 1 ? 7 : weekday - 1) else { return false }
        let hour = Double(calendar.component(.hour, from: now))
            + Double(calendar.component(.minute, from: now)) / 60
        return openDays.contains(today) && hour >= openTime && hour < closeTime
    }

    /// 想再訪的日期
    var revisitList: [Date] {
        revisitDates.compactMap { Calendar.current.date(from: $0) }.sorted()
    }
}

func timeText(_ value: Double) -> String {
    let hour = Int(value)
    let minute = value.truncatingRemainder(dividingBy: 1) == 0 ? "00" : "30"
    return "\(String(format: "%02d", hour)):\(minute)"
}

/// 要帶到新增／編輯頁的資料
struct FormItem: Identifiable, Hashable {
    let id = UUID()
    var restaurant: Restaurant?
}

/// 提示視窗的內容
struct AlertInfo {
    var title: String
    var message: String
    var onDismiss: (() -> Void)? = nil
}
