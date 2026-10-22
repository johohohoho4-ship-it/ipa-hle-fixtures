//
//  FollowerCell.swift
//  GitHubFollowers
//
//  Created by Monika Mateska on 10.10.22.
//

import UIKit

class FollowerCell: UICollectionViewCell {
    static let reuseID = "FollowerCell"
    
    let avatarImageView = GHAvatarImageView()
    let usernameLebel = GHTitleLabel(textAlignment: .center, fontSize: 16)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func set(follower: Follower) {
        usernameLebel.text = follower.login
        avatarImageView.downloadImage(from: follower.avatarUrl)
    }
    
    private func configure() {
        configureImageView()
        configureUsernameLabel()
    }
    
    private func configureImageView() {
        self.addSubview(avatarImageView)
        
        NSLayoutConstraint.activate([
            avatarImageView.topAnchor.constraint(equalTo: self.topAnchor, constant: 8),
            avatarImageView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            avatarImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 8),
            avatarImageView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -8),
            avatarImageView.heightAnchor.constraint(equalTo: avatarImageView.widthAnchor)
        ])
    }
    
    private func configureUsernameLabel() {
        self.addSubview(usernameLebel)
        
        NSLayoutConstraint.activate([
            usernameLebel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -17),
            usernameLebel.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            usernameLebel.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
}
