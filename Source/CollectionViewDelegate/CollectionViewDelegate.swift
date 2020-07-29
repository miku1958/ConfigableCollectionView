//
//  CollectionViewDelegate.swift
//  ConfigableCollectionView
//
//  Created by 庄黛淳华 on 2020/7/28.
//

import Foundation

extension CollectionView {
	class Delegate: NSObject, UICollectionViewDelegateFlowLayout {
		weak var collection: CollectionView?
		
		// MARK: - UICollectionViewDelegateFlowLayout
		func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
			guard let collection = collection else { return .zero }
			if let registerd = collection.registeredView(for: indexPath, item: nil),
			   let element = collection._dataManager.element(for: indexPath),
			   let size = registerd.flowLayoutSize(.init(collectionView: collection, data: element, indexPath: indexPath)) {
				return size
			} else if let delegates = (collection.collectionDelegate.customDelegates.allObjects as? [UICollectionViewDelegateFlowLayout]) {
				for delegate in delegates {
					if let size = delegate.collectionView?(collectionView, layout: collectionViewLayout, sizeForItemAt: indexPath) {
						return size
					}
				}
			}
			if let layout = collectionViewLayout as? UICollectionViewFlowLayout {
				if layout.estimatedItemSize != .zero {
					return layout.estimatedItemSize
				}
				if #available(iOS 10.0, *) {
					if layout.itemSize != UICollectionViewFlowLayout.automaticSize {
						return layout.itemSize
					}
				} else {
					return layout.itemSize
				}
			}
			return CGSize(width: 1, height: 1)
		}
		
		// MARK: - UICollectionViewDelegate
		func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
			guard
				let collection = collection,
				let registerd = collection.registeredView(for: indexPath, item: nil),
				let cell = collection.cellForItem(at: indexPath)
			else {
				return
			}
			let view: UIView
			if let cell = cell as? CollectionViewCell {
				if let subview = cell.subview {
					view = subview
				} else {
					return
				}
			} else {
				view = cell
			}
			
			guard
				let element = collection._dataManager.element(for: indexPath),
				!registerd.tap(.init(collectionView: collection, view: view, data: element, indexPath: indexPath)), // 处理自定义的tap, 如果成功则取消后续操作
				let delegates = collection.collectionDelegate.customDelegates.allObjects as? [UICollectionViewDelegate]
			else { return }
			for delegate in delegates {
				delegate.collectionView?(collectionView, didSelectItemAt: indexPath)
			}
		}
	}
}
