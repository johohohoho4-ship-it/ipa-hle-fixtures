//
//  UserInfoViewController.swift
//  GitHubFollowers
//
//  Created by Monika Mateska on 11.10.22.
//

import UIKit

protocol UserInfoViewControllerDelegate: AnyObject {
    func didTapGitHubProfile(for user: User)
    func didTapGetFollowers(for user: User)
}

class UserInfoViewController: UIViewController {
    
    var username: String!
    weak var delegate: FollowerListViewControllerDelegate!
    
    let headerView = UIView()
    let itemViewOne = UIView()
    let itemViewTwo = UIView()
    let dateLabel = GHBodyLabel(textAlignment: .center)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissViewController))
        navigationItem.rightBarButtonItem = doneButton
        
        configureUI()
        loadUserData()
    }
    
    private func loadUserData() {
        showLoadingView()
        Task {
            do {
                let user = try await NetworkManager.shared.getUserInfo(for: self.username)
                hideLoadingView()
                configureUIelements(with: user)
            } catch {
                hideLoadingView()
                let mappedError = error as! NetworkError
                presentAlert(message: "Failed loading user info. \(mappedError.rawValue).")
            }
        }
    }
    
    private func configureUI() {
        configureHeaderView()
        configureViewOne()
        configureViewTwo()
        configureDateLabel()
    }
    
    private func configureUIelements(with user: User) {
        addChildViewController(GHUserInfoViewController(user: user), to: headerView)
        
        let repoItemVc = GHRepoItemViewController(user: user)
        repoItemVc.delegate = self
        addChildViewController(repoItemVc, to: itemViewOne)
        
        let followerItemVc = GHFollowerItemViewController(user: user)
        followerItemVc.delegate = self
        addChildViewController(followerItemVc, to: itemViewTwo)
        
        updateDateLabel(with: user.createdAt)
    }
    
    private func configureHeaderView() {
        view.addSubview(headerView)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 180)
        ])
    }
    
    let padding: CGFloat = 20
    let itemHeight: CGFloat = 140
    
    private func configureViewOne() {
        view.addSubview(itemViewOne)
        itemViewOne.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            itemViewOne.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: padding),
            itemViewOne.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            itemViewOne.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
            itemViewOne.heightAnchor.constraint(equalToConstant: itemHeight)
        ])
    }
    
    private func configureViewTwo() {
        view.addSubview(itemViewTwo)
        itemViewTwo.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            itemViewTwo.topAnchor.constraint(equalTo: itemViewOne.bottomAnchor, constant: padding),
            itemViewTwo.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            itemViewTwo.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
            itemViewTwo.heightAnchor.constraint(equalToConstant: itemHeight)
        ])
    }
    
    private func configureDateLabel() {
        view.addSubview(dateLabel)
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            dateLabel.topAnchor.constraint(equalTo: itemViewTwo.bottomAnchor, constant: padding),
            dateLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            dateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
            dateLabel.heightAnchor.constraint(equalToConstant: 18)
        ])
    }
    
    private func updateDateLabel(with inputDate: String) {
        guard let date = inputDate.convertToDate() else { return }
        dateLabel.text = "GitHub since \(date.convertToString())"
    }
    
    func addChildViewController(_ childVC: UIViewController, to contrainerView: UIView) {
        addChild(childVC)
        contrainerView.addSubview(childVC.view)
        childVC.view.frame = contrainerView.bounds
        childVC.didMove(toParent: self)
    }
    
    @objc func dismissViewController() {
        dismiss(animated: true)
    }
}

extension UserInfoViewController: UserInfoViewControllerDelegate {
    
    func didTapGitHubProfile(for user: User) {
        presentInSafariView(with: user.htmlUrl)
    }
    
    func didTapGetFollowers(for user: User) {
        guard user.followers > 0 else {
            presentAlert(message: "This user does not have any follower.")
            return 
        }
        delegate.didRequestFollowers(for: user.login)
        dismiss(animated: true)
    }
}
