//
//  NetworkError.swift
//  GitHubFollowers
//
//  Created by Monika Mateska on 9.10.22.
//

import Foundation

enum NetworkError: String, Error {
    case notValidUrl = "The URL is not valid"
    case requestFailed = "The URL request has failed"
    case decodingFailed = "The data response cannot be decoded"
}
