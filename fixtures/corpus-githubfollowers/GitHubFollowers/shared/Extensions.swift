//
//  Extensions.swift
//  GitHubFollowers
//
//  Created by Monika Mateska on 9.10.22.
//

import UIKit
import SafariServices

fileprivate var containerView: UIView!

extension UIViewController {
    
    func presentAlert(title: String = "Error",
                      message: String,
                      buttonText: String = "OK") {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction.init(title: buttonText, style: .destructive))
            self.present(alertController, animated: true)
        }
    }
    
    func showLoadingView() {
        containerView = UIView(frame: view.frame)
        view.addSubview(containerView)
        
        containerView.backgroundColor = .systemBackground
        containerView.alpha = 0
        
        UIView.animate(withDuration: 0.25) {
            containerView.alpha = 0.7
        }
        
        let activityIndicator = UIActivityIndicatorView(style: .large)
        containerView.addSubview(activityIndicator)
        
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        activityIndicator.startAnimating()
    }
    
    func hideLoadingView() {
        UIView.animate(withDuration: 0.25) {
            containerView.alpha = 0
        }
        containerView = nil
    }
    
    func showEmptyStateView(with message: String, in view: UIView) {
        let emptyStateView = GHEmptyStateView(description: message)
        emptyStateView.frame = view.bounds
        
        view.addSubview(emptyStateView)
    }
    
    func presentInSafariView(with url: String) {
        guard let url = URL(string: url) else {
            presentAlert(title: "Invalid URL", message: "The url attached to this user is invalid.", buttonText: "OK")
            return
        }
        
        let safariViewController = SFSafariViewController(url: url)
        safariViewController.preferredControlTintColor = .systemGreen
        present(safariViewController, animated: true)
    }
    
}

extension String {
    
    func convertToDate() -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let date = dateFormatter.date(from: self)
        
        return date
    }
}

extension Date {
    
    func convertToString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        let result = dateFormatter.string(from: self)
        
        return result
    }
}
