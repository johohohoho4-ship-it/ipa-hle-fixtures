//
//  ShadowButton.swift
//  ToDoListUIkit
//
//  Created by mac on 7/10/25.
//

import UIKit

@IBDesignable
class ShadowButton: UIButton {
    
    @IBInspectable
    var cornerRadius: CGFloat = 5 {
        didSet {
            layer.cornerRadius = cornerRadius
        }
    }
    
    @IBInspectable
    var background: UIColor = .link {
        didSet {
            backgroundColor = background
        }
    }
    
    @IBInspectable
    var shadowColor: UIColor = UIColor(named: "secondaryLink")! {
        didSet {
            layer.shadowColor = shadowColor.cgColor
        }
    }
    
    override  func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }

    override  func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setupView()
    }
    
    private func setupView() {
        titleLabel?.font = UIFont.style(.secondaryText)
        backgroundColor = background
        layer.shadowColor = shadowColor.cgColor
        layer.masksToBounds = false
        layer.shadowOpacity = 1.0
        layer.shadowRadius = 0
    }
    
    override  func didMoveToSuperview() {
        super.didMoveToSuperview()
        layer.shadowOffset = CGSize(width: 0, height: 5)
    }
    
    override  func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = cornerRadius
        
    }
    
    

}
