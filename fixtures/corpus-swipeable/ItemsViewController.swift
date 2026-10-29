//
//  ItemsViewController.swift
//  SwipableCollectionViewCell
//
//  Created by Amer Hukic on 23/08/2018.
//  Copyright © 2018 Amer Hukic. All rights reserved.
//
//  Corpus fixture: `accessibilityIdentifier` on the collection view, the cells and
//  an accessibility-only probe for the item count. A collection view only realises
//  its visible cells, so the XCUITest cannot count all 19 cells from the element
//  tree; the probe carries the data-source count as an accessibility label. The
//  data model, layout and delete path are unchanged.
//

import UIKit

class ItemsViewController: UIViewController {
    
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(ItemCollectionViewCell.self, forCellWithReuseIdentifier: cellIdentifier)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 4, right: 0)
        collectionView.backgroundColor = UIColor(white: 0.97, alpha: 1)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.accessibilityIdentifier = "items.collection"
        return collectionView
    }()
    
    let cellIdentifier = "cell"

    /// Corpus fixture: 1x1, textless label that only exists for the XCUITest; its
    /// accessibility label is the current number of items.
    private let itemCountProbe: UILabel = {
        let label = UILabel(frame: .zero)
        label.isAccessibilityElement = true
        label.accessibilityIdentifier = "items.count"
        label.isUserInteractionEnabled = false
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    var items: [String] = {
        var items = [String]()
        for i in 1 ..< 20 {
            items.append("Item \(i)")
        }
        return items
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(collectionView)
        collectionView.pinEdgesToSuperView()
        view.addSubview(itemCountProbe)
        NSLayoutConstraint.activate([
            itemCountProbe.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            itemCountProbe.topAnchor.constraint(equalTo: view.topAnchor),
            itemCountProbe.widthAnchor.constraint(equalToConstant: 1),
            itemCountProbe.heightAnchor.constraint(equalToConstant: 1)
        ])
        updateItemCountValue()
    }
    
    private func updateItemCountValue() {
        itemCountProbe.accessibilityLabel = "\(items.count)"
    }
}

extension ItemsViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 80)
    }
}

extension ItemsViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! ItemCollectionViewCell
        cell.itemNameLabel.text = items[indexPath.item]
        cell.accessibilityIdentifier = "cell.item"
        cell.delegate = self
        return cell
    }
}

extension ItemsViewController: SwipeableCollectionViewCellDelegate {
    func hiddenContainerViewTapped(inCell cell: UICollectionViewCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        items.remove(at: indexPath.item)
        collectionView.performBatchUpdates({
            self.collectionView.deleteItems(at: [indexPath])
        }, completion: { _ in
            self.updateItemCountValue()
        })
    }
    
    func visibleContainerViewTapped(inCell cell: UICollectionViewCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        print("Tapped item at index path: \(indexPath)")
    }
}
