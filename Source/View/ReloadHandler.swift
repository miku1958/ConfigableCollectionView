//
//  ReloadHandler.swift
//  ConfigableCollectionView
//
//  Created by 庄黛淳华 on 2020/7/12.
//

import Foundation

public class _CollectionViewReloadHandler {
	@usableFromInline
	init() { }
	fileprivate var needReload = false
	@usableFromInline
	internal var _reload: (_ animatingDifferences: Bool, _ completion: (() -> Void)?) -> Void = { _, _ in }
	
	fileprivate var animatingDifferences = false
	fileprivate var completion: (() -> Void)?
	
	@usableFromInline
	internal func commit() -> _CollectionViewReloadHandler {
		if !needReload {
			needReload = true
			DispatchQueue.main.async {
				guard self.needReload else { return }
				self.forceReload()
			}
		}
		return self
	}
	internal func forceReload() {
		_reload(animatingDifferences, completion)
		completion = nil
		needReload = false
	}
	internal func cancelReload() {
		needReload = false
	}
	
	@available(iOS 13.0, tvOS 13.0, *)
	public func on(animatingDifferences: Bool, completion: (() -> Void)? = nil) {
		self.animatingDifferences = animatingDifferences
		self.completion = completion
	}
	
	public func on(completion: (() -> Void)? = nil) {
		self.completion = completion
	}
}
