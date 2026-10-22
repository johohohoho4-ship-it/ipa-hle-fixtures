//
//  NetworkManager.swift
//  GitHubFollowers
//
//  Created by Monika Mateska on 9.10.22.
//

import UIKit

class NetworkManager {
    
    static let shared = NetworkManager()
    
    private let baseURL = "https://api.github.com/users/"
    let cache = NSCache<NSString, UIImage>()
    
    private init() { }
    
    func getFollowers(username: String, page: Int) async throws -> [Follower] {
        let endpoint = "\(baseURL)\(username)/followers?per_page=100&page=\(page)"
        guard let url = URL(string: endpoint) else {
            throw NetworkError.notValidUrl
        }
        let request = URLRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: request)
        if let response = response as? HTTPURLResponse,
           response.statusCode != 200 {
            throw NetworkError.requestFailed
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        guard let followers = try? decoder.decode([Follower].self, from: data) else {
            throw NetworkError.decodingFailed
        }
        
        return followers
    }
    
    func downloadImage(from urlString: String) async -> UIImage? {
        if let cachedImage = readCachedImage(from: urlString) {
            return cachedImage
        }
        
        guard let url = URL(string: urlString) else { return nil }
        
        do {
            let request = URLRequest(url: url)
            let (data, _) = try await URLSession.shared.data(for: request)
            if let downloadedImage = UIImage(data: data) {
                cacheImage(downloadedImage, for: urlString)
                return downloadedImage
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }
    
    func getUserInfo(for username: String) async throws -> User {
        let endpoint = "\(baseURL)\(username)"
        guard let url = URL(string: endpoint) else {
            throw NetworkError.notValidUrl
        }
        
        let request = URLRequest(url: url)
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse,
                  response.statusCode == 200 else {
                throw NetworkError.requestFailed
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            guard let loadedUser = try? decoder.decode(User.self, from: data) else {
                throw NetworkError.decodingFailed
            }
            return loadedUser
        } catch {
            throw NetworkError.requestFailed
        }
    }
    
    private func cacheImage(_ image: UIImage, for urlString: String) {
        cache.setObject(image, forKey: urlString as NSString)
    }
    
    private func readCachedImage(from urlString: String) -> UIImage? {
        cache.object(forKey: urlString as NSString)
    }
}
