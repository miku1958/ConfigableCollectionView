//
//  CollectionView.swift
//  ConfigableCollectionView
//
//  Created by 庄黛淳华 on 2020/2/24.
//  Copyright © 2020 庄黛淳华. All rights reserved.
//

import UIKit
#if canImport(Proxy)
@_implementationOnly import Proxy
#endif

var isUnitTesting = false
let emptyCellIdentifier = "_emptyCellIdentifier"
public class CollectionView<SectionType, ItemType>: UICollectionView {
	var _dataManager: CollectionViewDataManager!
	@usableFromInline
	var reloadHandler = ReloadHandler()
	/// [dataType: registerd]
	var registerViews = [ObjectIdentifier: [_RegisteredView]]()
	var registerSupplementaryViews = [ObjectIdentifier: [_RegisteredView]]()
	var cachingViews = [String: UIView]()
	
	// swiftlint:disable weak_delegate
	var collectionDelegate: CollectionViewDelegateProxy!
	var collectionDatasource: UICollectionViewDataSource?
	
	func set(uiCollectionViewDataSource: UICollectionViewDataSource?) {
		super.dataSource = uiCollectionViewDataSource
	}
// MARK: - override
	public override weak var dataSource: UICollectionViewDataSource? {
		didSet {
			super.dataSource = collectionDatasource
		}
	}
	public override weak var delegate: UICollectionViewDelegate? {
		// 这里没法直接重写 set/get, 不然在 touchesEnd 里不会回调 delegate 的 didSelected 方法
		didSet {
			// 防止有些第三方(比如 RxCocoa) 内部在设置完 delegate 后会进行 assert 判断有没有被修改, 所以这里先把原来的异步修改回自定义的 delegate, 并且把原来的 collectionDelegate 释放, 不然会死循环
			guard let delegate = delegate else { return }
			guard
				!delegate.isEqual(collectionDelegate),
				!delegate.isEqual(oldValue)
			else { return }
			DispatchQueue.main.async {
				self.resetANewDelegateProxy(addingDelegate: delegate)
			}
		}
	}
	@inline(__always)
	func resetANewDelegateProxy(addingDelegate: UICollectionViewDelegate?) {
		let newDelegate = CollectionViewDelegateProxy(proxy: collectionDelegate)
		// 先释放旧的是为了防止像 RxSwift 这类会内部又持有原本 delegate 的导致死循环
		collectionDelegate = nil
		super.delegate = nil
		// 因为设置 super.delegate 的时候就会检查 delegate 的方法实现, 所以这里改成先添加再设置
		newDelegate.addDelegates(addingDelegate)
		self.collectionDelegate = newDelegate
		super.delegate = newDelegate
	}
	
	required init<Section, Item>(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout, dataManagerInit: (CollectionView) -> DataManager<Section, Item>) {
		super.init(frame: frame, collectionViewLayout: layout)
		
		let dataManager = dataManagerInit(self)
		let delegate = Delegate()
		delegate.collection = self
		collectionDelegate =  CollectionViewDelegateProxy(collection: self)
		if !isUnitTesting {
			collectionDatasource = dataManager.prepareDatasource()
		}
		_dataManager = dataManager
		
		collectionDelegate.mainDelegate = delegate
		
		super.dataSource = collectionDatasource
		super.delegate = collectionDelegate
		
		backgroundColor = .clear
		
		register(CollectionViewCell.self, forCellWithReuseIdentifier: emptyCellIdentifier)
	}
	
	var customScrollOffst: CGPoint = .zero
	public override func setContentOffset(_ contentOffset: CGPoint, animated: Bool) {
		var contentOffset = contentOffset
		contentOffset.x -= customScrollOffst.x
		contentOffset.y -= customScrollOffst.y
		super.setContentOffset(contentOffset, animated: animated)
	}
	public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		// 如果点到的View有能响应的手势是不会来到这里的
		
		// iOS 10的模拟器有bug, 如果view比较短不能滑动的时候, 通过滑动触发点击事件后, 再点击是不会响应tap的(但会来到这里), 并且只有模拟器会
		
		guard
			let touch = touches.first,
			let view = touch.view
		else { return }
		
		//因为 CollectionViewCell 实现了交由 contentView 来决定 hittest, 而 super.touchesEnded(touches, with: event) 会判断当前点击的点是否在 cell 内部, 如果不是就直接结束了, 所以这里判断当 hittest 返回的 view 对应的点击在 cell 外面时就手动调用, 因为 hittest 得到一个 cell 外部的 view 跟点击到了 cell 外面原本是互斥的, 所以当条件满足时就代表 contentView 内部复写了 hittest 方法, 所以是没问题的
		if let cell: CollectionViewCell = view.map({
			var next = $0.superview
			while next != nil {
				if let cell = next as? CollectionViewCell {
					return cell
				}
				next = next?.superview
			}
			return nil
		}), !cell.bounds.contains(touch.location(in: cell)), let indexPath = indexPath(for: cell) {
			collectionDelegate.collectionView(self, didSelectItemAt: indexPath)
			return
		}
		
		super.touchesEnded(touches, with: event)
	}
	required init?(coder: NSCoder) { nil }
}

extension CollectionView {
	@usableFromInline
	func cell(at indexPath: IndexPath, item: Any?) -> UICollectionViewCell {
		guard
			let registerd = registeredView(for: indexPath, item: item)
		else {
			if !isUnitTesting {
				if let item = item {
					assertionFailure("Invalid parameter not satisfying: view register for item: \(type(of: item))(\(item)) != nil")
				} else {
					assertionFailure("Invalid parameter not satisfying: view register != nil")
				}
			}
			
			return dequeueReusableCell(withReuseIdentifier: emptyCellIdentifier, for: indexPath)
		}
		let cell = dequeueReusableCell(withReuseIdentifier: registerd.reuseIdentifier, for: indexPath)
		
		if let cell = cell as? CollectionViewCell {
			if cell.createSubview == nil {
				cell.createSubview = registerd.view
			}
			if let view = cell.subview,
			   let element = item ?? _dataManager.element(for: indexPath) {
				// 这个不能放到willDisplay里去调, 不然如果是自适应尺寸的cell会出错
				registerd.config(.init(collectionView: self, view: view, data: element, indexPath: indexPath))
				#if swift(>=5.3)
				if #available(iOS 14.0, *) {
					cell.updateUICellConfigurationState = { [weak self] in
						guard let self = self else { return }
						let state = $0 as! UICellConfigurationState
						registerd.config(.init(collectionView: self, view: view, data: element, indexPath: indexPath, _configurationState: state))
					}
				}
				#endif
			}
		} else if let element = _dataManager.element(for: indexPath) { // 注册的 View 是 UICollectionViewCell
			// 这个不能放到willDisplay里去调, 不然如果是自适应尺寸的cell会出错
			registerd.config(.init(collectionView: self, view: cell, data: element, indexPath: indexPath))
		}
		return cell
	}
}
