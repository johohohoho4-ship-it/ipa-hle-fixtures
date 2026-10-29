//
//  ItemCollectionViewCell.swift
//  SwipeableCollectionViewCell
//
//  Created by Amer Hukic on 24/08/2018.
//  Copyright © 2018 Amer Hukic. All rights reserved.
//
//  Corpus fixture: the delete image view moved into `SwipeableCollectionViewCell`
//  as `deleteButton` (SF Symbol instead of the asset catalog). No other change.
//

import UIKit

class ItemCollectionViewCell: SwipeableCollectionViewCell {
    
    let itemNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 20)
        label.textColor = UIColor(white: 0.2, alpha: 1)
        label.textAlignment = .center
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSubviews() {
        visibleContainerView.backgroundColor = .white
        visibleContainerView.addSubview(itemNameLabel)
        itemNameLabel.pinEdgesToSuperView()
        
        hiddenContainerView.backgroundColor = UIColor(red: 231.0 / 255.0, green: 76.0 / 255.0, blue: 60.0 / 255.0, alpha: 1)
    }
}
