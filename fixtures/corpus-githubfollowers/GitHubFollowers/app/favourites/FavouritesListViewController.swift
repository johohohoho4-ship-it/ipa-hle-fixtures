import UIKit

class FavouritesListViewController: UIViewController {
    
    let tableView = UITableView(frame: .zero)
    
    var favourites = [Follower]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        configureViewController()
        configureTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        retreiveFavourites()
    }
    
    private func configureViewController() {
        view.backgroundColor = .systemBackground
        title = "Favourites"
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    private func configureTableView() {
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.frame = view.bounds
        tableView.rowHeight = 80
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        tableView.register(FavouriteCell.self, forCellReuseIdentifier: FavouriteCell.reuseID)
    }
    
    private func retreiveFavourites() {
        showLoadingView()
        do {
            let favourites = try PersistenceManager.retreiveFavourites()
            hideLoadingView()
            self.favourites = favourites
            if self.favourites.isEmpty {
                showEmptyStateView(with: "No favourites?\nAdd one on the follower screen.", in: self.view)
            } else {
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        } catch {
            hideLoadingView()
            if let error = error as? PersistenceError {
                presentAlert(message: error.rawValue)
            }
        }
    }
}

extension FavouritesListViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        favourites.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FavouriteCell.reuseID) as! FavouriteCell
        let index = indexPath.row
        let follower = favourites[index]
        
        cell.set(favourite: follower)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.dequeueReusableCell(withIdentifier: FavouriteCell.reuseID) as! FavouriteCell
        let index = indexPath.row
        let follower = favourites[index]
        
        let followerViewController = FollowerListViewController()
        followerViewController.username = follower.login
        followerViewController.title = follower.login
        
        navigationController?.pushViewController(followerViewController, animated: true)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        
        let index = indexPath.row
        let follower = favourites[index]
        
        favourites.remove(at: index)
        tableView.deleteRows(at: [indexPath], with: .left)
        
        do {
            try PersistenceManager.update(with: follower, actionType: .remove)
        } catch {
            presentAlert(title: "Error", message: "Unable to remove")
        }
    }
    
}
