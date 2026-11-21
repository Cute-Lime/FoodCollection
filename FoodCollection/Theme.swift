import SwiftUI

enum Theme {
    static let defaultHex = "FF8FB1"
}

// MARK: - Color 轉 Hex
extension Color {
    init(hex: String) {
        let value = Scanner(string: hex).scanInt(representation: .hexadecimal) ?? 0
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }

    var hex: String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(
            format: "%02X%02X%02X",
            Int((r * 255).rounded()), Int((g * 255).rounded()), Int((b * 255).rounded())
        )
    }
}

// MARK: - 背景色
struct ThemedBackground: View {
    @AppStorage("themeHex") private var themeHex = Theme.defaultHex

    var body: some View {
        LinearGradient(
            colors: [Color(hex: themeHex).opacity(0.35), Color(.systemBackground)],
            startPoint: .top,
            endPoint: .center
        )
        .ignoresSafeArea()
    }
}

extension View {
    func themedBackground() -> some View {
        background(ThemedBackground())
    }

    /// 半透明卡片
    func card() -> some View {
        self
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    /// 提示視窗
    func infoAlert(_ info: Binding<AlertInfo?>) -> some View {
        alert(
            info.wrappedValue?.title ?? "",
            isPresented: Binding(
                get: { info.wrappedValue != nil },
                set: { if !$0 { info.wrappedValue = nil } }
            ),
            presenting: info.wrappedValue
        ) { item in
            Button("好", role: .cancel) { item.onDismiss?() }
        } message: { item in
            Text(item.message)
        }
    }
}

// MARK: - 星星評分
struct RatingStars: View {
    let rating: Double

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { index in
                Image(systemName: symbol(for: index))
            }
        }
        .foregroundStyle(.yellow)
    }

    private func symbol(for index: Int) -> String {
        if rating >= Double(index) { return "star.fill" }
        if rating >= Double(index) - 0.5 { return "star.leadinghalf.filled" }
        return "star"
    }
}

// MARK: - 縮小照片
extension UIImage {
    func resized(maxSide: CGFloat) -> UIImage {
        let scale = min(1, maxSide / max(size.width, size.height))
        guard scale < 1 else { return self }
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
