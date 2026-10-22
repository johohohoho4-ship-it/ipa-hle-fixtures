//
//  PersistenceManager.swift
//  GitHubFollowers
//
//  Created by Monika Mateska on 13.10.22.
//

import Foundation

enum PersistenceActionType {
    case add, remove
}

class PersistenceManager {
    
    static private let defaults = UserDefaults.standard
    
    enum Keys {
        static let favourites = "favourites"
    }
    
    static func update(with follower: Follower, actionType: PersistenceActionType) throws {
        var favouritesList = try retreiveFavourites()
        
        switch actionType {
        case .add:
            guard !favouritesList.contains(where: { $0.login == follower.login }) else {
                throw PersistenceError.alreadyAddedToFavourites
            }
            favouritesList.append(follower)
        case .remove:
            favouritesList.removeAll(where: { $0.login == follower.login })
        }
        
        try saveToFavourites(favouritesList)
    }
    
    static func retreiveFavourites() throws -> [Follower] {
        guard let favouritesData = defaults.object(forKey: Keys.favourites) as? Data else {
            return []
        }
        
        do {
            let favourites = try JSONDecoder().decode([Follower].self, from: favouritesData)
            return favourites
        } catch {
            throw PersistenceError.unableToReadFavourites
        }
    }
    
    static func saveToFavourites(_ favouritesList: [Follower]) throws {
        do {
            let favouritesData = try JSONEncoder().encode(favouritesList)
            defaults.set(favouritesData, forKey: Keys.favourites)
        } catch {
            throw PersistenceError.unableToStoreFavourites
        }
    }
}
