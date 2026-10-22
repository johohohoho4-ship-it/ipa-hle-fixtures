//
//  GHUserInfoViewController.swift
//  GitHubFollowers
//
//  Created by Monika Mateska on 11.10.22.
//

import UIKit

class GHUserInfoViewController: UIViewController {
    
    var user: User!
    
    let userAvatarImage = GHAvatarImageView(frame: .zero)
    let usernameLabel = GHTitleLabel(textAlignment: .left, fontSize: 34)
    let nameLabel = GHSecondaryTitleLabel(fontSize: 18)
    let locationImageView = UIImageView()
    let locationLabel = GHSecondaryTitleLabel(fontSize: 18)
    let bioLabel = GHBodyLabel(textAlignment: .left)
    
    init(user: User) {
        super.init(nibName: nil, bundle: nil)
        self.user = user
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configure()
        configureUIEelements()
    }
    
    private func configureUIEelements() {
        self.userAvatarImage.downloadImage(from: user.avatarUrl)
        self.usernameLabel.text = user.login
        self.nameLabel.text = user.name ?? ""
        self.locationImageView.image = UIImage(systemName: "mappin.and.ellipse")
        self.locationLabel.text = user.location ?? ""
        self.bioLabel.text = user.bio ?? ""
    }
    
    private func configure() {
        configureUserAvatarImage()
        configureUsernameLabel()
        configureNameLabel()
        configureLocationImageView()
        configureLocationLabel()
        configureBioLabel()
    }
    
    private func configureUserAvatarImage() {
        view.addSubview(userAvatarImage)
        userAvatarImage.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            userAvatarImage.topAnchor.constraint(equalTo: view.topAnchor),
            userAvatarImage.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            userAvatarImage.heightAnchor.constraint(equalToConstant: 100),
            userAvatarImage.widthAnchor.constraint(equalToConstant: 100)
        ])
    }
    
    private func configureUsernameLabel() {
        view.addSubview(usernameLabel)
        usernameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            usernameLabel.topAnchor.constraint(equalTo: userAvatarImage.topAnchor),
            usernameLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            usernameLabel.leadingAnchor.constraint(equalTo: userAvatarImage.trailingAnchor, constant: 12),
            usernameLabel.heightAnchor.constraint(equalToConstant: 38)
        ])
    }
    
    private func configureNameLabel() {
        view.addSubview(nameLabel)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            nameLabel.centerYAnchor.constraint(equalTo: userAvatarImage.centerYAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: userAvatarImage.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            nameLabel.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    private func configureLocationImageView() {
        view.addSubview(locationImageView)
        locationImageView.translatesAutoresizingMaskIntoConstraints = false
        
        locationImageView.tintColor = .secondaryLabel
        
        NSLayoutConstraint.activate([
            locationImageView.bottomAnchor.constraint(equalTo: userAvatarImage.bottomAnchor),
            locationImageView.leadingAnchor.constraint(equalTo: userAvatarImage.trailingAnchor, constant: 12),
            locationImageView.heightAnchor.constraint(equalToConstant: 20),
            locationImageView.widthAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    private func configureLocationLabel() {
        view.addSubview(locationLabel)
        locationLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            locationLabel.centerYAnchor.constraint(equalTo: locationImageView.centerYAnchor),
            locationLabel.leadingAnchor.constraint(equalTo: locationImageView.trailingAnchor, constant: 5),
            locationLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            locationLabel.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    private func configureBioLabel() {
        view.addSubview(bioLabel)
        bioLabel.translatesAutoresizingMaskIntoConstraints = false
        
        bioLabel.numberOfLines = 3
        
        NSLayoutConstraint.activate([
            bioLabel.topAnchor.constraint(equalTo: userAvatarImage.bottomAnchor, constant: 12),
            bioLabel.leadingAnchor.constraint(equalTo: userAvatarImage.leadingAnchor),
            bioLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            bioLabel.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
}
