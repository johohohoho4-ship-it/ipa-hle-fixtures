//
//  PersistenceError.swift
//  GitHubFollowers
//
//  Created by Monika Mateska on 13.10.22.
//

import Foundation

enum PersistenceError: String, Error {
    case unableToReadFavourites = "There was an error retreiving the favourites list. Please try again."
    case unableToStoreFavourites = "There was an error storing the favourites list. Please try again."
    case alreadyAddedToFavourites = "You have already added this user to favourites list."
}
