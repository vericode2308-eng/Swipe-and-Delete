import Foundation

public enum Formatting {
    /// Assumed average photo size for "room for about N photos".
    public static let averagePhotoBytes: Int64 = 3_000_000

    private static let locale = Locale(identifier: "en_GB")

    /// Decimal units, like Settings › Storage: "0 KB", "999 MB", "1.2 GB".
    public static func size(_ bytes: Int64) -> String {
        let units = ["KB", "MB", "GB", "TB"]
        var value = Double(max(0, bytes)) / 1000
        var unit = 0
        while value >= 999.5 && unit < units.count - 1 { value /= 1000; unit += 1 }
        let text = value < 10 && value > 0
            ? String(format: "%.1f", value)
            : String(format: "%.0f", value)
        return "\(text.hasSuffix(".0") ? String(text.dropLast(2)) : text) \(units[unit])"
    }

    /// "Room for about 1,200 more photos". Rounded: exact below 100,
    /// nearest 10 below 1,000, nearest 100 above.
    public static func roomForPhotos(freedBytes: Int64) -> String {
        let n = Int(max(0, freedBytes) / averagePhotoBytes)
        let rounded: Int
        switch n {
        case ..<100: rounded = n
        case ..<1000: rounded = (n + 5) / 10 * 10
        default: rounded = (n + 50) / 100 * 100
        }
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = locale
        let text = f.string(from: NSNumber(value: rounded)) ?? "\(rounded)"
        return "Room for about \(text) more photo\(rounded == 1 ? "" : "s")"
    }
}
