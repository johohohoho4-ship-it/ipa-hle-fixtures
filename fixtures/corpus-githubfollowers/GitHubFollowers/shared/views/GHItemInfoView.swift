//
//  GHItemInfoView.swift
//  GitHubFollowers
//
//  Created by Monika Mateska on 11.10.22.
//

import UIKit

enum ItemInfoType {
    case repos, followers, gists, following
}

class GHItemInfoView: UIView {

    let symbolImageView = UIImageView()
    let titleLabel = GHTitleLabel(textAlignment: .left, fontSize: 14)
    let countLabel = GHTitleLabel(textAlignment: .center, fontSize: 14)
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        configure()
    }
    
    func set(type itemInfoType: ItemInfoType, count: Int) {
        configure()
        var symbolImageName = ""
        var titleText = ""
        
        switch itemInfoType {
        case .repos:
            symbolImageName = "folder"
            titleText = "Public Repos"
        case .followers:
            symbolImageName = "heart"
            titleText = "Followers"
        case .gists:
            symbolImageName = "text.alignleft"
            titleText = "Public Gists"
        case .following:
            symbolImageName = "person.2"
            titleText = "Following"
        }
        
        symbolImageView.image = UIImage(systemName: symbolImageName)
        titleLabel.text = titleText
        countLabel.text = String(count)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure() {
        addSubview(symbolImageView)
        addSubview(titleLabel)
        addSubview(countLabel)
        
        symbolImageView.translatesAutoresizingMaskIntoConstraints = false
        symbolImageView.contentMode = .scaleToFill
        symbolImageView.tintColor = .label
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            symbolImageView.topAnchor.constraint(equalTo: self.topAnchor),
            symbolImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            symbolImageView.heightAnchor.constraint(equalToConstant: 20),
            symbolImageView.widthAnchor.constraint(equalToConstant: 20),
            
            titleLabel.centerYAnchor.constraint(equalTo: symbolImageView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: symbolImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: 18),
            
            countLabel.topAnchor.constraint(equalTo: symbolImageView.bottomAnchor, constant: 4),
            countLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            countLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            countLabel.heightAnchor.constraint(equalToConstant: 18)
        ])
    }

}
