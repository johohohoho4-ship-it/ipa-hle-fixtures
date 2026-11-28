//
//  SettingsViewController.swift
//  ToDoListUIkit
//
//  Created by mac on 7/9/25.
//

import UIKit

/// This allows the user to change settings. The only setting available is the ability to change interface style to light,dark, or sytem preference
class SettingsViewController: UIViewController {

    @IBOutlet weak var settingsTitleLabel: UILabel!
    
    @IBOutlet weak var appthemeLabel: UILabel!
    
    @IBOutlet weak var modalVIew: UIView!
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    private func setupView() {
        settingsTitleLabel.font = UIFont.style(.heading1)
        appthemeLabel.font = UIFont.style(.secondaryText)
        
        // Depending on the current interface style ,we change the srgmented control's selected index to the interface
        let window = UIApplication.shared
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        if let window = window {
            switch window.overrideUserInterfaceStyle {
            case .light:
                segmentedControl.selectedSegmentIndex = 0
            case .dark:
                segmentedControl.selectedSegmentIndex = 1
            case .unspecified:
                segmentedControl.selectedSegmentIndex = 2
           @unknown default :
                segmentedControl.selectedSegmentIndex = 2
            }
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        modalVIew.layer.cornerRadius = 5
    }
    

    @IBAction func dismissButtonTapped(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func segmentedControlValueChanged(_ sender: UISegmentedControl) {
        
        /*
         The hierarchy for views is as follows:
         - uiapplication
         - windowscenes
         - windows
         - keyWindow
         - overrideUserInterfaceStyle
         We obtain the window to change the interface style below
         */
        let window = UIApplication.shared
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        
        if sender.selectedSegmentIndex == 0 {
            // Light Mode
            window?.overrideUserInterfaceStyle = .light
            UserDefaults.standard.set(0, forKey: "interfacePreference")
        
        }
        else if sender.selectedSegmentIndex == 1 {
            // Dark Mode
            window?.overrideUserInterfaceStyle = .dark
            UserDefaults.standard.set(1, forKey: "interfacePreference")
        }
        else {
            // System Default
            window?.overrideUserInterfaceStyle = .unspecified
            UserDefaults.standard.set(2, forKey: "interfacePreference")
        }
    }
    
}
