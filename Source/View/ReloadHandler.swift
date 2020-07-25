//
//  ReloadHandler.swift
//  ConfigableCollectionView
//
//  Created by 庄黛淳华 on 2020/7/12.
//

import Foundation

public class ReloadHandler {
	@usableFromInline
	init() { }
	fileprivate var needReload = false
	@usableFromInline
	internal var _reload: (_ animatingDifferences: Bool, _ completion: [() -> Void]) -> Void = { _, _ in }
	
	fileprivate var animatingDifferences = true
	fileprivate var completion = [() -> Void]()
	
	@usableFromInline
	internal func commit() -> ReloadHandler {
		if !needReload {
			needReload = true
			DispatchQueue.main.async {
				self.reloadImmediately()
			}
		}
		return self
	}
    
    public func reloadImmediately() {
		defer {
			completion = []
		}
		guard needReload else { return }
		_reload(animatingDifferences, completion)
		needReload = false
		animatingDifferences = true
	}
	
	@available(iOS 13.0, tvOS 13.0, *)
    @discardableResult
	public func on(animatingDifferences: Bool, completion: (() -> Void)? = nil) -> ReloadHandler {
		self.animatingDifferences = animatingDifferences
        if let completion = completion {
            self.completion.append(completion)
        }
        return self
	}
	
    @discardableResult
	public func on(completion: (() -> Void)? = nil) -> ReloadHandler {
        if let completion = completion {
            self.completion.append(completion)
        }
        return self
	}
}
