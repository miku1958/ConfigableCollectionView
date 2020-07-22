//
//  CollectionView.swift
//  ConfigableCollectionView
//
//  Created by 庄黛淳华 on 2020/2/24.
//  Copyright © 2020 庄黛淳华. All rights reserved.
//

import UIKit

public var CollectionViewDeletegateInvade: CollectionViewInvadeProtocol.Type?
public class CollectionView<DataType, VerifyType>: UICollectionView {
	var _dataManager: CollectionViewDataManager!
	@usableFromInline
	var reloadHandlers = [_CollectionViewReloadHandler]()
	/// [dataType: registerd]
	var registerViews = [ObjectIdentifier: [_RegisteredView]]()
	var cachingViews = [String: UIView]()
	
	// swiftlint:disable weak_delegate
	lazy var collectionDelegate = CollectionViewDelegateProxy(collection: self)
	var mainDelegate: Delegate {
		collectionDelegate.mainDelegate as! Delegate
	}
	
// MARK: - override
	public override weak var dataSource: UICollectionViewDataSource? {
		didSet {
			self.collectionDelegate.addDatasources(dataSource)
			super.dataSource = collectionDelegate
		}
	}
	public override weak var delegate: UICollectionViewDelegate? {
		// 这里没法直接重写 set/get, 不然在 touchesEnd 里不会回调 delegate 的 didSelected 方法
		willSet {
			// 防止有些第三方(比如 RxCocoa) 内部在设置完 delegate 后会进行 assert 判断有没有被修改, 所以这里先把原来的异步修改回自定义的 delegate, 并且把原来的 collectionDelegate 释放, 不然会死循环
			if newValue?.isEqual(collectionDelegate) ?? false {
				return
			}
			DispatchQueue.main.async {
				self.resetANewDelegateProxy()
				self.collectionDelegate.addDelegates(newValue)
			}
		}
	}
	func resetANewDelegateProxy() {
		let newDelegate = CollectionViewDelegateProxy(proxy: collectionDelegate)
		self.collectionDelegate = newDelegate
		super.delegate = newDelegate
	}
	
	override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
		super.init(frame: frame, collectionViewLayout: layout)
		
		let delegate = Delegate()
		delegate.collection = self
		
		collectionDelegate.mainDelegate = delegate
		
		super.dataSource = collectionDelegate
		super.delegate = collectionDelegate
		
		backgroundColor = .clear
		
		register(CollectionViewCell.self, forCellWithReuseIdentifier: "empty")
	}
	
	public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
		let view = super.hitTest(point, with: event)
		return view
	}
	
	private var customScrollOffst: CGPoint = .zero
	func scrollToItem(at indexPath: IndexPath, at scrollPosition: UICollectionView.ScrollPosition, offset: CGPoint, animated: Bool) {
		customScrollOffst = offset
		super.scrollToItem(at: indexPath, at: scrollPosition, animated: animated)
		customScrollOffst = .zero
	}
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
	func forceReload() {
		for handler in reloadHandlers {
			handler.forceReload()
		}
	}
}

// MARK: - initialize
extension CollectionView where VerifyType == Any, DataType == Any {
	public convenience init(layout: UICollectionViewLayout) {
		self.init(frame: .zero, collectionViewLayout: layout)
		let dataManager = DataManager<AnyHashable>(collectionView: self)
		self._dataManager = dataManager
	}
	
	public var dataManager: DataManager<AnyHashable> {
		_dataManager as! DataManager<AnyHashable>
	}
}

extension CollectionView where VerifyType == Void, DataType: Hashable {
	public convenience init(layout: UICollectionViewLayout, dataType: DataType.Type) {
		self.init(frame: .zero, collectionViewLayout: layout)
		
		let dataManager = DataManager<DataType>(collectionView: self)
		self._dataManager = dataManager
	}
	public var dataManager: DataManager<DataType> {
		_dataManager as! DataManager<DataType>
	}
}

// MARK: - register view
public extension CollectionView where VerifyType == Any {
	/// 使用多个RegisteredView注册Cell
	/// view: 创建View, 独立开是为了复用 View, 如果view为UICollectionViewCell, 则初始化无效(不会调用), 会使用UICollectionView.dequeue来实现
	func register<View, DataType>(dataType: DataType.Type, view: @escaping () -> View, _ builds: RegisteredView<View, DataType>...) {
		register(view: view, builds)
	}
	func register<View, DataType>(dataType: DataType.Type, view: @escaping @autoclosure () -> View, _ builds: RegisteredView<View, DataType>...) {
		register(view: view, builds)
	}
}
public extension CollectionView where VerifyType == Void {
	/// 使用多个RegisteredView注册Cell
	func register<View>(view: @escaping () -> View, _ builds: RegisteredView<View, DataType>...) {
		register(view: view, builds)
	}
	func register<View>(view: @escaping @autoclosure () -> View, _ builds: RegisteredView<View, DataType>...) {
		register(view: view, builds)
	}
}

extension CollectionView {
	func register<View, DataType>(view: @escaping () -> View, _ builds: [RegisteredView<View, DataType>]) {
		
		var registeredView = RegisteredView<View, DataType>(view: view)
		for build in builds {
			registeredView.bind(from: build)
		}
		let reuseIdentifier = "\(DataType.self)-\(View.self)"
		registerViews[ObjectIdentifier(DataType.self), default: []].append(.init(registeredView, reuseIdentifier: reuseIdentifier))
		if View.self is UICollectionViewCell.Type {
			register(View.self, forCellWithReuseIdentifier: reuseIdentifier)
		} else {
			register(CollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
		}
	}
	
	@inline(__always)
	func registeredView(for indexPath: IndexPath, item: Any?) -> _RegisteredView? {
		let item = item ?? _dataManager.element(for: indexPath)
		if item is CollectionView.AnyHashable {
			fatalError()
		}
		guard let registerViews = registerViews[ObjectIdentifier(type(of: item))] else { return nil }
		return registerViews.first {
			$0.when(item)
		} ?? registerViews.first
	}
	
	struct _RegisteredView {
		let view: () -> UIView
		let config: (UIView, Any) -> Void
		let when: (Any) -> Bool
		
		let created: ((UIView) -> Void)
		let tap: (UIView, Any) -> Bool
		let size: ((UICollectionView) -> CGSize?)
		
		let reuseIdentifier: String
		
		init<View, DataType>(_ _view: RegisteredView<View, DataType>, reuseIdentifier: String) {
			self.reuseIdentifier = reuseIdentifier
			self.view = _view._view ?? UIView.init
			
			self.when = { data in
				guard let when = _view._when, let data = data as? DataType else { return false }
				return when(data)
			}
			
			self.config = { view, data in
				if let view = view as? View, let data = data as? DataType {
					_view._config?(view, data)
				}
			}
			
			self.created = { view in
				if let view = view as? View {
					_view._created?(view)
				}
			}
			
			self.tap = { view, data in
				if let tap = _view._tap, let view = view as? View, let data = data as? DataType {
					tap(view, data)
					return true
				}
				return false
			}
			
			self.size = {
				_view._size?($0)
			}
		}
	}
	
	public struct RegisteredView<View, DataType> where View: UIView {
		public typealias R = RegisteredView<View, DataType>
		var _view: (() -> View)?
		var _config: ((View, DataType) -> Void)?
		var _when: ((DataType) -> Bool)?
		
		var _created: ((View) -> Void)?
		var _tap: ((View, DataType) -> Void)?
		
		var _size: ((UICollectionView) -> CGSize)?
		
		init(view: (() -> View)? = nil, config: ((View, DataType) -> Void)? = nil, when: ((DataType) -> Bool)? = nil, created: ((View) -> Void)? = nil, tap: ((View, DataType) -> Void)? = nil, size: ((UICollectionView) -> CGSize)? = nil) {
			_view = view
			_config = config
			_when = when
			_created = created
			_tap = tap
			_size = size
		}
		
		/// 决定什么时候需要分配这个 View
		static public func when(_ act: @escaping (DataType) -> Bool) -> R { R(when: act) }
		/// 配置View, 每次使用之前都会调用这个
		static public func config(_ act: @escaping (View, DataType) -> Void) -> R { R(config: act) }
		/// 当首次创建了这个 View 就会调用
		static public func created(_ act: @escaping (View) -> Void) -> R { R(created: act) }
		/// 当点击了这个 View 就会调用
		static public func tap(_ act: @escaping (View, DataType) -> Void) -> R { R(tap: act) }
		/// 给这个 View 一个默认尺寸
		static public func size(_ act: @escaping (UICollectionView) -> CGSize) -> R { R(size: act) }
		
		mutating func bind(from r: R) {
			if let act = r._view { _view = act }
			if let act = r._when { _when = act }
			if let act = r._config { _config = act }
			if let act = r._created { _created = act }
			if let act = r._tap { _tap = act }
			if let act = r._size { _size = act }
		}
	}
}

extension CollectionView {
	func cell(at indexPath: IndexPath, item: Any?) -> UICollectionViewCell? {
		guard
			let registerd = registeredView(for: indexPath, item: item)
		else {
			return nil
		}
		let cell = dequeueReusableCell(withReuseIdentifier: registerd.reuseIdentifier, for: indexPath)
		
		if let cell = cell as? CollectionViewCell {
			if cell.createSubview == nil {
				cell.createSubview = registerd.view
				if let view = cell.subview {
					registerd.created(view)
				}
			}
			if let view = cell.subview {
				let element = _dataManager.element(for: indexPath)
				// 这个不能放到willDisplay里去调, 不然如果是自适应尺寸的cell会出错
				registerd.config(view, element)
			}
		} else { // 注册的 View 是 UICollectionViewCell
			if cell.isFirstTimeDequeued {
				registerd.created(cell)
				cell.isFirstTimeDequeued = false
			}
			let element = _dataManager.element(for: indexPath)
			// 这个不能放到willDisplay里去调, 不然如果是自适应尺寸的cell会出错
			registerd.config(cell, element)
		}
		return cell
	}
	class Delegate: NSObject, UICollectionViewDelegateFlowLayout {
		weak var collection: CollectionView?
	
		// MARK: - UICollectionViewDelegateFlowLayout
		func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
			guard let collection = collection else { return .zero }
			if let registerd = collection.registeredView(for: indexPath, item: nil),
				let size = registerd.size(collectionView) {
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
				if layout.itemSize != UICollectionViewFlowLayout.automaticSize {
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
				let cell = collection.cellForItem(at: indexPath) as? CollectionViewCell,
				let view = cell.subview
				else {
					return
			}
			
			let call = {
				let element = collection._dataManager.element(for: indexPath)
				guard
					!registerd.tap(view, element), // 处理自定义的tap, 如果成功则取消后续操作
					let delegates = collection.collectionDelegate.customDelegates.allObjects as? [UICollectionViewDelegate]
					else { return }
				for delegate in delegates {
					delegate.collectionView?(collectionView, didSelectItemAt: indexPath)
				}
			}
			if let invade = CollectionViewDeletegateInvade, let view = cell.subview {
				invade.didselected(view: view, call: call)
			} else {
				call()
			}
		}
	}
}

extension CollectionView {
	public func scrollToEnd(animated: Bool = true) {
		guard let lastIndexPath = _dataManager.lastIndexPath else {
			return
		}
		scrollToItem(at: lastIndexPath, at: .right, animated: animated)
	}
}

extension UICollectionViewCell {
	private static var CellFirstTimeDequeuedKey: Void?
	var isFirstTimeDequeued: Bool {
		set {
			objc_setAssociatedObject(self, &Self.CellFirstTimeDequeuedKey, newValue, .OBJC_ASSOCIATION_RETAIN)
		}
		get {
			objc_getAssociatedObject(self, &Self.CellFirstTimeDequeuedKey) as? Bool ?? true
		}
	}
}

