//
//  GHButton.swift
//  GitHubFollowers
//
//  Created by Monika Mateska on 9.10.22.
//

import UIKit

class GHButton: UIButton {
    
    init(backgroundColor: UIColor, title: String) {
        super.init(frame: .zero)
        self.set(backgroundColor: backgroundColor, title: title)
        configure()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func set(backgroundColor: UIColor, title: String) {
        self.backgroundColor = backgroundColor
        self.setTitle(title, for: .normal)
    }
    
    private func configure() {
        layer.cornerRadius = 10
        setTitleColor(.white, for: .normal)
        titleLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        translatesAutoresizingMaskIntoConstraints = false
    }
    
}
