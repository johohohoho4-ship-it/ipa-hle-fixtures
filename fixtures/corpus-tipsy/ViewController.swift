//
//  ViewController.swift
//  Tipsy
//
//  Created by Angela Yu on 09/09/2019.
//  Copyright © 2019 The App Brewery. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    //MARK: - Variables
    var tipBrain = TipBrain()
    var tip = 0.10
    private var formatter: NumberFormatter?
    
    //MARK: - @IBOutlets
    @IBOutlet var billTextField: UITextField!
    @IBOutlet var zeroPercentButton: UIButton!
    @IBOutlet var tenPercentButton: UIButton!
    @IBOutlet var twentyPercentButton: UIButton!
    @IBOutlet var stepperLabel: UILabel!
    @IBOutlet var stepper: UIStepper!
    @IBOutlet var calculateButton: UIButton!
    
    
    //MARK: - Views
    override func viewDidLoad() {
        super.viewDidLoad()
        // Accessibility identifiers for the fixture's XCUITest and the corpus runner.
        billTextField.accessibilityIdentifier = "tipsy.bill"
        zeroPercentButton.accessibilityIdentifier = "tipsy.tip.0"
        tenPercentButton.accessibilityIdentifier = "tipsy.tip.10"
        twentyPercentButton.accessibilityIdentifier = "tipsy.tip.20"
        stepperLabel.accessibilityIdentifier = "tipsy.people.label"
        stepper.accessibilityIdentifier = "tipsy.people"
        calculateButton.accessibilityIdentifier = "tipsy.calculate"
        // The decimal pad has no return key; a tap outside the field dismisses it.
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard)))
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    //MARK: - Functions
    @IBAction func tipButtonPressed(_ sender: UIButton) {
        if sender.tag == 0 {
            tenPercentButton.isSelected = false
            zeroPercentButton.isSelected = true
            twentyPercentButton.isSelected = false
            tip = 0.0
        }
        else if sender.tag == 1 {
            tenPercentButton.isSelected = true
            zeroPercentButton.isSelected = false
            twentyPercentButton.isSelected = false
            tip = 0.10
        }
        else {
            tenPercentButton.isSelected = false
            zeroPercentButton.isSelected = false
            twentyPercentButton.isSelected = true
            tip = 0.20
        }
        
        
    }
    
    @IBAction func calculateButtonPressed(_ sender: UIButton) {
        tipBrain.calculateTip(amountValue: Double(billTextField.text!)!, numberOfPeople: stepper.value, tip: tip)
        self.performSegue(withIdentifier: "goToResult", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToResult" {
            let destinationVC = segue.destination as! ResultViewController
            destinationVC.amountPerPersonValue = tipBrain.getAmountPerPerson()
            destinationVC.numberOfPeople = stepper.value
            destinationVC.tipSelection = Int(tip * 100)
        }
    }
    
    
    @IBAction func stepperChanged(_ sender: UIStepper) {
        self.stepperLabel.text = String(format: "%.0f", sender.value)
    }

}

