//
//  SwipeableCollectionViewCell.swift
//  SwipeableCollectionViewCell
//
//  Created by Amer Hukic on 23/08/2018.
//  Copyright © 2018 Amer Hukic. All rights reserved.
//

import UIKit

protocol SwipeableCollectionViewCellDelegate: AnyObject {
    func visibleContainerViewTapped(inCell cell: UICollectionViewCell)
    func hiddenContainerViewTapped(inCell cell: UICollectionViewCell)
}

class SwipeableCollectionViewCell: UICollectionViewCell {
    
    // MARK: Properties
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView(frame: .zero)
        scrollView.isPagingEnabled = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()
    
    let visibleContainerView = UIView()
    let hiddenContainerView = UIView()

    /// Corpus fixture: the delete control is a real button so the XCUITest can tap it
    /// by identifier instead of guessing coordinates. It replaces the image view and
    /// its tap gesture from the original example.
    let deleteButton: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(systemName: "trash")?.withRenderingMode(.alwaysTemplate)
        button.setImage(image, for: .normal)
        button.tintColor = .white
        button.accessibilityIdentifier = "cell.delete"
        button.accessibilityLabel = "Delete"
        return button
    }()

    weak var delegate: SwipeableCollectionViewCellDelegate?
    
    // MARK: Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
        setupGestureRecognizer()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSubviews() {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.addArrangedSubview(visibleContainerView)
        stackView.addArrangedSubview(hiddenContainerView)
        
        addSubview(scrollView)
        scrollView.pinEdgesToSuperView()
        scrollView.addSubview(stackView)
        stackView.pinEdgesToSuperView()
        stackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor).isActive = true
        stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 2).isActive = true

        hiddenContainerView.addSubview(deleteButton)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.centerXAnchor.constraint(equalTo: hiddenContainerView.centerXAnchor).isActive = true
        deleteButton.centerYAnchor.constraint(equalTo: hiddenContainerView.centerYAnchor).isActive = true
        deleteButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
        deleteButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
    }
    
    private func setupGestureRecognizer() {
        deleteButton.addTarget(self, action: #selector(hiddenContainerViewTapped), for: .touchUpInside)
        
        let visibleContainerTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(visibleContainerViewTapped))
        visibleContainerView.addGestureRecognizer(visibleContainerTapGestureRecognizer)
        
    }
    
    @objc private func visibleContainerViewTapped() {
        delegate?.visibleContainerViewTapped(inCell: self)
    }
    
    @objc private func hiddenContainerViewTapped() {
        delegate?.hiddenContainerViewTapped(inCell: self)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // when the orientation changes and the cell is open -> update the content offset for the new cell width
        if scrollView.contentOffset.x > 0 {
            scrollView.contentOffset.x = scrollView.frame.width
        }
    }
}
