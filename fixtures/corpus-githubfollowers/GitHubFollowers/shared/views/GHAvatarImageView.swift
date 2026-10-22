//
//  AvatarImageView.swift
//  GitHubFollowers
//
//  Created by Monika Mateska on 10.10.22.
//

import UIKit

class GHAvatarImageView: UIImageView {
    
    let placeholderImage = UIImage(named: "avatar-placeholder")

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configure() {
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = 10
        clipsToBounds = true
        image = placeholderImage
    }
    
    func downloadImage(from urlString: String) {
        Task { @MainActor in
            if let downloadedImage = await NetworkManager.shared.downloadImage(from: urlString) {
                image = downloadedImage
            }
        }
    }
}
