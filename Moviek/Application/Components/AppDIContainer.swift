
import Foundation

final class AppDIContainer {
    
    // MARK: - Network
    static let networkManager: NetworkService = {
        let config = ApiDataNetworkConfig(
            baseURL: URL(string: AppConfiguration.apiBaseURL)!,
            queryParameters: [
                "api_key": AppConfiguration.apiKey,
                "language": NSLocale.preferredLanguages.first ?? "en"
            ]
        )

        return DefaultNetworkService.init(config: config)
    }()
    
    static let swiftDataStorage: SwiftDataStorage = {
        do {
            return try SwiftDataStorage()
        } catch {
            fatalError("Failed to initialize SwiftDataStorage: \(error)")
        }
    }()
}
