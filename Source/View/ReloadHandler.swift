//
//  ReloadHandler.swift
//  ConfigableCollectionView
//
//  Created by 庄黛淳华 on 2020/7/12.
//

import Foundation

public class ReloadHandler {
	@usableFromInline
	typealias Completion = () -> Void
	
	@usableFromInline
	typealias Reload = (_ animatingDifferences: Bool, _ completions: [Completion]) -> Void
	
	@usableFromInline init() { }
	
	@usableFromInline
	internal var _baseReload: Reload = { _, _  in }
	
	@usableFromInline
	internal var _temporaryReload: (reload: Reload, option: (animatingDifferences: Bool, completions: [Completion]))?
	
	fileprivate var needReloadBase = false
	fileprivate var animatingDifferences = true
	fileprivate var completions = [Completion]()
}

extension ReloadHandler {
	@usableFromInline
	internal func commit(temporaryReload: @escaping Reload) -> ReloadHandler {
		reloadImmediately()
		_temporaryReload = (temporaryReload, (true, []))
		
		DispatchQueue.main.async {
			self.reloadTemporaryImmediately()
		}
		return self
	}
	
	@usableFromInline
	internal func commit() -> ReloadHandler {
		reloadTemporaryImmediately()
		if !needReloadBase {
			needReloadBase = true
			DispatchQueue.main.async {
				self.reloadBaseImmediately()
			}
		}
		return self
	}
	
	func reloadTemporaryImmediately() {
		guard let reload = _temporaryReload else { return }
		reload.reload(reload.option.animatingDifferences, reload.option.completions)
		_temporaryReload = nil
	}
	
	func reloadBaseImmediately() {
		defer {
			completions = []
		}
		guard needReloadBase else { return }
		_baseReload(animatingDifferences, completions)
		needReloadBase = false
		animatingDifferences = true
	}
}
	
extension ReloadHandler {
	public func reloadImmediately() {
		reloadTemporaryImmediately()
		reloadBaseImmediately()
	}
	@discardableResult
	public func on(animatingDifferences: Bool = true, completion: (() -> Void)? = nil) -> ReloadHandler {
		if _temporaryReload != nil {
			_temporaryReload?.option.animatingDifferences = animatingDifferences
			if let completion = completion {
				_temporaryReload?.option.completions.append(completion)
			}
		} else {
			self.animatingDifferences = animatingDifferences
			if let completion = completion {
				self.completions.append(completion)
			}
		}
		
		return self
	}
}
