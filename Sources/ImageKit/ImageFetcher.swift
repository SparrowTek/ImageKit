import Foundation
import SwiftUI
import StorageKit

public actor ImageFetcher {
    private var inProgressRequests = [String : Task<(), any Error>]()
    
    public init() {}
    
    public static func normalizeURL(_ url: String) -> String {
        url.replacingOccurrences(of: "/", with: "")
    }
    
    private func removeProgressRequestValue(forKey key: String) {
        inProgressRequests.removeValue(forKey: key)
    }
    
    public func fetchImage(from url: String, priority: TaskPriority? = nil) {
        guard inProgressRequests[url] == nil else { return }
        
        // Tasks eat errors (😢) so the guard else statements would typically throw errors instead of just returning
        // but i'm choosing to ignore errors here. If it fails we'll try to cache it next time we need it
        let task = Task(priority: priority) {
            guard let link = URL(string: url), let (data, response) = try? await URLSession.shared.data(from: link), let httpResponse = response as? HTTPURLResponse else { return }
            
            do {
                try Task.checkCancellation()
            } catch {
                removeProgressRequestValue(forKey: url)
                return
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                let normalizedURL = ImageFetcher.normalizeURL(url)
                try Storage.store(data, to: .caches, as: normalizedURL)
                removeProgressRequestValue(forKey: url)
            default:
                removeProgressRequestValue(forKey: url)
                return
            }
        }
        
        inProgressRequests[url] = task
    }
    
    public func cancelPrefetch(for url: String) {
        guard let task = inProgressRequests[url] else { return }
        task.cancel()
        inProgressRequests.removeValue(forKey: url)
    }
    
    public func clearCache() {
        for task in inProgressRequests.values {
            task.cancel()
        }
        
        try? Storage.clear(.caches)
    }
}

extension EnvironmentValues {
    @Entry public var imageFetcher = ImageFetcher()
}
