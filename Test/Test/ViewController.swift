//
//  ViewController.swift
//  Test
//
//  Created by 庄黛淳华 on 2020/7/25.
//

import UIKit
import ConfigableCollectionView

class ViewController: UIViewController {

	let collectionView = CollectionView<Any, String>(layout: UICollectionViewFlowLayout())
	override func viewDidLoad() {
		super.viewDidLoad()
	
		view.addSubview(collectionView)
		collectionView.frame = view.bounds
		collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		
		registerCollectionView()
		prepareData()
	}
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .left, offset: CGPoint(x: 0, y: 100), animated: true)
	}
	func registerCollectionView() {
		collectionView.register(
			view: {
				UILabel()
			},
			.config {
				$0.view.text = $0.data
				if $0.configurationState.isHighlighted {
					$0.view.backgroundColor = .green
				} else {
					$0.view.backgroundColor = .clear
				}
			},
			.flowLayoutSize { _ in
				CGSize(width: 100, height: 100)
			},
			.tap { [weak self] _ in
				self?.view.backgroundColor = .red
			}
		)
	}
	func prepareData() {
		collectionView.dataManager.applyItems(["Hello World ~ ! ! !"])
	}
}

