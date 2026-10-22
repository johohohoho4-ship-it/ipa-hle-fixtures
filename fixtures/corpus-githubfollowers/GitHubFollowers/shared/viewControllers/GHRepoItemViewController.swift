//
//  File.swift
//  GitHubFollowers
//
//  Created by Monika Mateska on 11.10.22.
//

import Foundation

class GHRepoItemViewController: GHItemInfoViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureItems()
    }
    
    private func configureItems() {
        firstInfoView.set(type: .repos, count: user.publicRepos)
        secondInfoView.set(type: .gists, count: user.publicGists)
        actionButton.set(backgroundColor: .systemPurple, title: "GitHub Profile")
    }
    
    override func actionButtonTapped() {
        delegate.didTapGitHubProfile(for: user)
    }
}
