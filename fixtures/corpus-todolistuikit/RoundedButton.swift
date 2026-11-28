//
//  RoundedButton.swift
//  ToDoListUIkit
//
//  Created by mac on 7/10/25.
//

import UIKit

class RoundedButton: UIButton {

    override  func awakeFromNib() {
        super.awakeFromNib()
        titleLabel?.font = UIFont.style(.secondaryText)
        backgroundColor = UIColor.link
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = 5
    }

}
