import Foundation

public struct AppConfig {
    public static let shared = AppConfig()

    public let supabaseURL: URL
    public let supabaseAnonKey: String
    public let defaultLibraryId: UUID
    public var isMockMode: Bool

    public static let fallbackLibraryId = UUID(uuidString: "11111111-1111-4111-8111-111111111111")!

    public init() {
        var urlString = ""
        var anonKey = ""
        var libraryIdString = "11111111-1111-4111-8111-111111111111"
        var mockMode = false

        // 1. Try reading from AppConfig.plist
        if let path = Bundle.main.path(forResource: "AppConfig", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path) as? [String: Any] {
            urlString = dict["SUPABASE_URL"] as? String ?? ""
            anonKey = dict["SUPABASE_ANON_KEY"] as? String ?? ""
            if let customLib = dict["DEFAULT_LIBRARY_ID"] as? String, !customLib.isEmpty {
                libraryIdString = customLib
            }
            if let mock = dict["ENABLE_MOCK_MODE"] as? Bool {
                mockMode = mock
            }
        }

        // 2. Try ProcessInfo environment variables (useful for CI/test schemes)
        if let envUrl = ProcessInfo.processInfo.environment["SUPABASE_URL"], !envUrl.isEmpty {
            urlString = envUrl
        }
        if let envKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"], !envKey.isEmpty {
            anonKey = envKey
        }
        if let envMock = ProcessInfo.processInfo.environment["ENABLE_MOCK_MODE"] {
            mockMode = (envMock == "1" || envMock.lowercased() == "true")
        }

        // 3. Defaults & fallback
        if urlString.isEmpty {
            urlString = "https://your-project.supabase.co"
        }
        if anonKey.isEmpty {
            anonKey = "your-anon-publishable-key"
        }

        self.supabaseURL = URL(string: urlString) ?? URL(string: "https://your-project.supabase.co")!
        self.supabaseAnonKey = anonKey
        self.defaultLibraryId = UUID(uuidString: libraryIdString) ?? AppConfig.fallbackLibraryId
        self.isMockMode = mockMode
    }

    public var isConfiguredForRealBackend: Bool {
        !supabaseURL.absoluteString.contains("your-project") &&
        !supabaseAnonKey.contains("your-anon") &&
        !supabaseAnonKey.isEmpty
    }
}
