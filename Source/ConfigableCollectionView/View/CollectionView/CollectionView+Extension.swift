//
//  CollectionView+Extension.swift
//  ConfigableCollectionView
//
//  Created by 庄黛淳华 on 2020/7/28.
//

import UIKit

extension CollectionView {
	public func scrollToItem(at indexPath: IndexPath, at scrollPosition: UICollectionView.ScrollPosition, offset: CGPoint, animated: Bool) {
		customScrollOffst = offset
		super.scrollToItem(at: indexPath, at: scrollPosition, animated: animated)
		customScrollOffst = .zero
	}
	public func scrollToEnd(animated: Bool = true) {
		guard let lastIndexPath = _dataManager.lastIndexPath else {
			return
		}
		scrollToItem(at: lastIndexPath, at: .right, animated: animated)
	}
}

extension CollectionView {
	@inline(__always)
	public func reloadImmediately(animatingDifferences: Bool = false) {
		if #available(iOS 13.0, *) {
			reloadHandler.on(animatingDifferences: animatingDifferences)
		}
		reloadHandler.reloadTemporaryImmediately()
		if #available(iOS 13.0, *) {
			reloadHandler.on(animatingDifferences: animatingDifferences)
		}
		reloadHandler.reloadBaseImmediately()
	}
}
