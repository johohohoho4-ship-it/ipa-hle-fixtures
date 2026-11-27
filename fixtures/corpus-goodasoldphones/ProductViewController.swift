//
//  ViewController.swift
//  GoodAsOldPhones
//
//  Copyright © 2016 Code School. All rights reserved.
//

import UIKit

class ProductViewController: UIViewController {

  @IBOutlet var productImageView: UIImageView!
  @IBOutlet var productNameLabel: UILabel!
  @IBOutlet weak var addToCartButton: UIButton!
  
  var product: Product?

  override func viewDidLoad() {
    super.viewDidLoad()
    
    productNameLabel.accessibilityIdentifier = "gaop.product.name"
    addToCartButton.accessibilityIdentifier = "gaop.addtocart"
    productNameLabel.text = product?.name
    
    if let imageName = product?.fullscreenImageName {
      productImageView.image = UIImage(named: imageName)
    }
  }

  @IBAction func addToCartButtonDidTap(_ sender: AnyObject) {
    print("Add to cart successfully")
  }
}
