import UIKit

let screenWidth = UIScreen.main.bounds.width
let screenHeight = UIScreen.main.bounds.height

class SearchViewController: UIViewController {
    
    let logoImageView = UIImageView()
    let usernameTextField = GHTextField()
    let calltoActionButton = GHButton(backgroundColor: .systemGreen, title: "Get Followers")
    
    var usernameIsValid: Bool {
        guard let username = usernameTextField.text else {
            return false
        }
        return !username.trimmingCharacters(in: [" "]).isEmpty
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        configureSubviews()
        createDismissKeyboardTapGesture()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    private func createDismissKeyboardTapGesture() {
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
        view.addGestureRecognizer(tap)
    }
    
    @objc func pushFollowerListViewController() {
        guard usernameIsValid else {
            presentAlert(title: "Error",
                         message: "The username is not valid. Please enter a valid one so we know who you are looking for.",
                         buttonText: "OK")
            return
        }
        let followerListViewController = FollowerListViewController()
        followerListViewController.username = usernameTextField.text
        followerListViewController.title = usernameTextField.text
        
        navigationController?.pushViewController(followerListViewController, animated: true)
    }
    
    private func configureSubviews() {
        configureLogoImageView()
        configureTextField()
        configureCallToActionButton()
    }
    
    private func configureLogoImageView() {
        view.addSubview(logoImageView)
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.image = UIImage(named: "gh-logo")!
        let imageSize = screenWidth * 0.7
        
        NSLayoutConstraint.activate([
            logoImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80),
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.heightAnchor.constraint(equalToConstant: imageSize),
            logoImageView.widthAnchor.constraint(equalToConstant: imageSize)
        ])
    }
    
    private func configureTextField() {
        view.addSubview(usernameTextField)
        usernameTextField.delegate = self
        
        NSLayoutConstraint.activate([
            usernameTextField.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 48),
            usernameTextField.heightAnchor.constraint(equalToConstant: 50),
            usernameTextField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 40),
            usernameTextField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -40),
            usernameTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    private func configureCallToActionButton() {
        view.addSubview(calltoActionButton)
        calltoActionButton.addTarget(self, action: #selector(pushFollowerListViewController), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            calltoActionButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            calltoActionButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            calltoActionButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50),
            calltoActionButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50),
            calltoActionButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
}

extension SearchViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(false)
        pushFollowerListViewController()
        return true
    }
}
