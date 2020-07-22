//
//  ViewController.swift
//  ConfigableCollectionViewDemo
//
//  Created by 庄黛淳华 on 2020/6/29.
//  Copyright © 2020 庄黛淳华. All rights reserved.
//

import UIKit
import ConfigableCollectionView
import SwiftUI

class ViewController: UIViewController {
	let collectionView = CollectionView(layout: UICollectionViewFlowLayout())
	let show = true
	override func viewDidLoad() {
		super.viewDidLoad()
		collectionView.register(
			dataType: String.self,
			view: { [weak self] in
				if let show = self?.show, show {
					UILabel()
				}
			},
			.config {
				$0.view.text = "\($0.data)"
			},
			.size { _ in
				CGSize(width: 100, height: 100)
			},
			.tap {
				$0.view.backgroundColor = .red
			}
		)
		if #available(iOS 14.0, *) {
			#if swift(>=5.3)
			collectionView.register(
				dataType: Int.self,
				view: UICollectionViewListCell(),
				.config {
					var config = $0.view.defaultContentConfiguration()
					config.text =  "\($0.data)"
					$0.view.contentConfiguration = config
				}
			)
			#endif
		} else {
			collectionView.register(
				dataType: Int.self,
				view: UIView(),
				.config { _ in

				},
				.tap {
					$0.view.backgroundColor = .red
				}
			)
		}
//		collectionView.dataSource = nil
		collectionView.dataManager.appendSections(["s1"])
		collectionView.dataManager.append(["abc"])
		collectionView.dataManager.append([123])
		view.addSubview(collectionView)
		collectionView.frame = view.bounds
		
		collectionView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
		
	}
}
protocol protocolA {

}
protocol protocolB: protocolA {
	var hashValue: Int { get }
}
struct B: protocolA, protocolB {
	
	var hashValue: Int { 0 }
	
}
struct A<T> {
	let t: T
}
extension A where T: protocolA {
	dynamic func function() {
		
	}
}
extension A where T: protocolB {
	@_dynamicReplacement(for: function)
	func function2() {
		guard self is protocolB else {
//			function()
			return
		}
		print("\(t.hashValue)")
	}
}
