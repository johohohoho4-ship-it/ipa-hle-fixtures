//
//  GHEmptyStateView.swift
//  GitHubFollowers
//
//  Created by Monika Mateska on 10.10.22.
//

import UIKit

class GHEmptyStateView: UIView {
    
    let label = GHTitleLabel(textAlignment: .center, fontSize: 28)
    let backgroundImage = UIImageView()
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(description: String) {
        super.init(frame: .zero)
        label.text = description
        configure()
    }
    
    private func configure() {
        self.addSubview(label)
        self.addSubview(backgroundImage)
        
        label.numberOfLines = 3
        label.textColor = .secondaryLabel
        
        backgroundImage.image = UIImage(named: "empty-state-logo")
        backgroundImage.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            label.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: -150),
            label.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 40),
            label.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -40),
            label.heightAnchor.constraint(equalToConstant: 200),
            backgroundImage.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            backgroundImage.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 200)
        ])
    }
}
