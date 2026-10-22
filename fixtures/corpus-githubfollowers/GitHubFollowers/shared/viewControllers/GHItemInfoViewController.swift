//
//  GHItemInfoViewController.swift
//  GitHubFollowers
//
//  Created by Monika Mateska on 11.10.22.
//

import UIKit

class GHItemInfoViewController: UIViewController {
    
    let stackView = UIStackView()
    let firstInfoView = GHItemInfoView()
    let secondInfoView = GHItemInfoView()
    let actionButton = GHButton()
    
    let user: User!
    weak var delegate: UserInfoViewControllerDelegate!
    
    init(user: User) {
        self.user = user
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
    
    private func configure() {
        view.layer.cornerRadius = 18
        view.backgroundColor = .secondarySystemBackground
        
        configureStackView()
        configureActionButton()
    }
    
    let padding: CGFloat = 20
    
    private func configureStackView() {
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stackView.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        configureItemInfoViews()
    }
    
    private func configureItemInfoViews() {
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing

        stackView.addArrangedSubview(firstInfoView)
        stackView.addArrangedSubview(secondInfoView)
        
        firstInfoView.translatesAutoresizingMaskIntoConstraints = false
        secondInfoView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func configureActionButton() {
        view.addSubview(actionButton)
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            actionButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -padding),
            actionButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            actionButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            actionButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    @objc func actionButtonTapped() { }
}
