//
//  FollowerListViewController.swift
//  GitHubFollowers
//
//  Created by Monika Mateska on 9.10.22.
//

import UIKit

protocol FollowerListViewControllerDelegate: NSObject {
    func didRequestFollowers(for username: String)
}

class FollowerListViewController: UIViewController {
    
    enum Section {
        case main
    }
    
    var username: String!
    var collectionView: UICollectionView!
    var dataSource: UICollectionViewDiffableDataSource<Section, Follower>!
    
    var page: Int = 1
    var hasMoreFollowers = true
    var filteredFollowers: [Follower] = []
    var followers: [Follower] = []
    var isSearching = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureViewController()
        configureSearchController()
        configureCollectionView()
        loadFollowers()
        configureDataSource()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    private func loadFollowers() {
        guard hasMoreFollowers else { return }
        showLoadingView()
        
        Task {
            do {
                let response = try await NetworkManager.shared.getFollowers(username: username,
                                                                            page: page)
                hideLoadingView()
                if response.count < 100 {
                    hasMoreFollowers = false
                }
                followers.append(contentsOf: response)
                page += 1
                updateData(with: followers)
                
                if followers.isEmpty {
                    let message = "This user doesn't have any followers. Go and follow them! 😊"
                    showEmptyStateView(with: message, in: view)
                }
            } catch {
                hideLoadingView()
                cleanupFollowersState()
                var errorMessage = "Failed to load the followers"
                if let error = error as? NetworkError {
                    errorMessage = error.rawValue
                }
                presentAlert(message: errorMessage)
            }
        }
    }
    
    private func filterFollowers(with filter: String) {
        filteredFollowers = followers.filter { $0.login.lowercased().contains(filter.lowercased()) }
        updateData(with: filteredFollowers)
    }
    
    private func configureViewController() {
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.prefersLargeTitles = true
        
        let followerButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addToFavouriteList))
        navigationItem.rightBarButtonItem = followerButton
    }
    
    @objc private func addToFavouriteList() {
        showLoadingView()
        Task {
            do {
                let user = try await NetworkManager.shared.getUserInfo(for: username)
                let follower = Follower(login: user.login, avatarUrl: user.avatarUrl)
                try PersistenceManager.update(with: follower, actionType: .add)
                hideLoadingView()
                presentAlert(title: "Success!", message: "Successfully added to favourites list 🎉", buttonText: "Hooreey!")
            } catch {
                hideLoadingView()
                if let error = error as? PersistenceError {
                    presentAlert(message: error.rawValue)
                } else if let error = error as? NetworkError {
                    presentAlert(message: error.rawValue)
                }
            }
        }
    }
    
    private func createThreeColumnFlowLayout() -> UICollectionViewFlowLayout {
        let width = view.bounds.width
        let padding: CGFloat = 12
        let minimumItemSpacing: CGFloat = 10
        let availableWidth = width - (padding * 2) - (minimumItemSpacing * 2)
        let cellWidth = availableWidth / 3
        
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.sectionInset = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        flowLayout.itemSize = CGSize(width: cellWidth, height: cellWidth + 40)
        
        return flowLayout
    }
    
    private func configureCollectionView() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createThreeColumnFlowLayout())
        collectionView.delegate = self
        view.addSubview(collectionView)
        
        collectionView.backgroundColor = .systemBackground
        collectionView.register(FollowerCell.self, forCellWithReuseIdentifier: FollowerCell.reuseID)
    }
    
    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Section, Follower>(collectionView: collectionView,
                                                                           cellProvider: { collectionView, indexPath, follower in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FollowerCell.reuseID, for: indexPath) as! FollowerCell
            
            cell.set(follower: follower)
            return cell
        })
    }
    
    private func configureSearchController() {
        let searchController = UISearchController()
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = "Search for a user name"
        navigationItem.searchController = searchController
    }
    
    private func updateData(with followers: [Follower]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Follower>()
        snapshot.appendSections([.main])
        snapshot.appendItems(followers)
        DispatchQueue.main.async {
            self.dataSource.apply(snapshot, animatingDifferences: true)
        }
    }
}

extension FollowerListViewController: UICollectionViewDelegate {
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let height = scrollView.frame.size.height
        
        if offsetY > contentHeight - height {
            loadFollowers()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let index = indexPath.item
        let selectedFollower = isSearching ? filteredFollowers[index] : followers[index]
        
        let userInfoViewController = UserInfoViewController()
        userInfoViewController.delegate = self
        userInfoViewController.username = selectedFollower.login
        let navigationController = UINavigationController(rootViewController: userInfoViewController)
        present(navigationController, animated: true)
    }
}

extension FollowerListViewController: UISearchResultsUpdating, UISearchBarDelegate {
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let filter = searchController.searchBar.text,
              !filter.isEmpty else {
            isSearching = false
            updateData(with: followers)
            return
        }
        
        isSearching = true
        filterFollowers(with: filter)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        isSearching = false
        updateData(with: followers)
    }
    
}

extension FollowerListViewController: FollowerListViewControllerDelegate {
    
    func didRequestFollowers(for username: String) {
        self.username = username
        navigationItem.title = username
        cleanupFollowersState()
        loadFollowers()
    }
    
    func cleanupFollowersState() {
        page = 1
        hasMoreFollowers = true
        followers = []
        filteredFollowers = []
        updateData(with: [])
    }
    
}
