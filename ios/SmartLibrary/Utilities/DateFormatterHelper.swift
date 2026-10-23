import Foundation

public enum DateFormatterHelper {
    private static let isoFormatterWithFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let isoFormatterBasic: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()

    private static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    public static func parseISO8601(_ string: String?) -> Date? {
        guard let string = string, !string.isEmpty else { return nil }
        if let date = isoFormatterWithFractional.date(from: string) {
            return date
        }
        return isoFormatterBasic.date(from: string)
    }

    public static func formatISO8601(_ date: Date) -> String {
        return isoFormatterWithFractional.string(from: date)
    }

    public static func formatTimeOnly(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }
        return timeFormatter.string(from: date)
    }

    public static func formatDateTime(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }
        return dateTimeFormatter.string(from: date)
    }

    /// Calculates remaining seconds from a server-provided ISO-8601 grace deadline
    public static func remainingSeconds(from deadlineISO: String?, relativeTo now: Date = Date()) -> Int {
        guard let deadline = parseISO8601(deadlineISO) else { return 0 }
        let diff = Int(deadline.timeIntervalSince(now))
        return max(0, diff)
    }

    /// Formats remaining seconds as MM:SS
    public static func formatCountdown(seconds: Int) -> String {
        let clamped = max(0, seconds)
        let mins = clamped / 60
        let secs = clamped % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    /// Formats elapsed time since entry
    public static func formatElapsedTime(from entryISO: String?, relativeTo now: Date = Date()) -> String {
        guard let entry = parseISO8601(entryISO) else { return "Just now" }
        let elapsed = Int(now.timeIntervalSince(entry))
        if elapsed < 60 {
            return "< 1 min ago"
        } else if elapsed < 3600 {
            let mins = elapsed / 60
            return "\(mins) min\(mins == 1 ? "" : "s") ago"
        } else {
            let hours = elapsed / 3600
            let mins = (elapsed % 3600) / 60
            return "\(hours)h \(mins)m ago"
        }
    }
}
