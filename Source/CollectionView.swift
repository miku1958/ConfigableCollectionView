//
//  CollectionView.swift
//  ConfigableCollectionView
//
//  Created by 庄黛淳华 on 2020/2/24.
//  Copyright © 2020 庄黛淳华. All rights reserved.
//

import UIKit

public var CollectionViewDeletegateInvade: CollectionViewInvadeProtocol.Type?
public class CollectionView<DataType, ElementType, VerifyType>: UICollectionView {
	public var datas = [DataType]()
	fileprivate var registerViews = [(dataType: Any.Type, view: _RegisteredView)]()
	fileprivate var cachingViews = [String: UIView]()
	fileprivate var indexToIdentifier = [IndexPath: String]()
	
	// swiftlint:disable weak_delegate
	fileprivate lazy var collectionDelegate = CollectionViewDelegateProxy(collection: self)
	fileprivate var mainDelegate: Delegate {
		collectionDelegate.mainDelegate as! Delegate
	}
	
// MARK: - override
	public override var dataSource: UICollectionViewDataSource? {
		didSet {
			update(dataSource: dataSource)
		}
	}
	public override var delegate: UICollectionViewDelegate? {
		didSet {
			update(delegate: delegate)
		}
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
	public override func reloadData() {
		mainDelegate.prepareReload()
		super.reloadData()
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
		// iOS 10的模拟器有bug, 如果view比较短不能滑动的时候, 通过滑动触发点击事件后, 再点击是不会响应tap的(但会来到这里), 并且只有模拟器会
		// 如果点到的View有能响应的手势是不会来到这里的
		
		guard
			let touch = touches.first,
			let view = touch.view
		else { return }
		
		// 当注册的 View 是 UICollectionView 时, super.touchesEnded(touches, with: event) 是不会回调 didSelected 的, 所以这里要提前判断调一下
		if let indexPath = indexPathForItem(at: touch.location(in: self)), let cell = cellForItem(at: indexPath) as? CollectionViewCell, cell.isContainUICollectionView {
			// 如果来到这里但是没有触发 didselected, cellForItem(at: indexPath) 也返回空, 就代表点击的时候触发了 relaodData
			collectionDelegate.collectionView(self, didSelectItemAt: indexPath)
			return
		}
		
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
	required init?(coder: NSCoder) { return nil }
}

// MARK: - initialize
extension CollectionView where VerifyType == Any, DataType == Any, ElementType == Any {
	public convenience init(layout: UICollectionViewLayout = UICollectionViewFlowLayout()) {
		self.init(frame: .zero, collectionViewLayout: layout)
	}
}
extension CollectionView where VerifyType == Void, DataType == [ElementType] {
	public convenience init(layout: UICollectionViewLayout = UICollectionViewFlowLayout(), datasType: DataType.Type) {
		self.init(frame: .zero, collectionViewLayout: layout)
	}
}
extension CollectionView where VerifyType == Void, ElementType == DataType {
	public convenience init(layout: UICollectionViewLayout = UICollectionViewFlowLayout(), dataType: DataType.Type) {
		self.init(frame: .zero, collectionViewLayout: layout)
	}
}
extension CollectionView {
	func update(dataSource: UICollectionViewDataSource?) {
		collectionDelegate.addDatasources(dataSource)
		super.dataSource = self.collectionDelegate
	}
	func update(delegate: UICollectionViewDelegate?) {
		#if canImport(RxCocoa)
		/*
		因为RxCocoa内部在设置完delegate后会进行assert判断有没有被修改, 所以这里异步修改回自定义的delegate, 不然会死循环
		*/
		if let delegate = delegate as? RxCocoa.RxCollectionViewDelegateProxy {
			DispatchQueue.main.async {
				// 这里得先设置成nil, 否则下一步时检查有没有实现UICollectionViewDelegate的方法时会死循环
				delegate._setForwardToDelegate(nil, retainDelegate: false)
				self.collectionDelegate.addDelegates(delegate)
				super.delegate = self.collectionDelegate
			}
			return
		}
		#endif
		collectionDelegate.addDelegates(delegate)
		super.delegate = self.collectionDelegate
	}
}

// MARK: - register view
public extension CollectionView where VerifyType == Any {
	/// 使用多个RegisteredView注册Cell
	func register<View, ElementType>(dataType: ElementType.Type, _ builds: RegisteredView<View, ElementType>...) {
		
		register(viewType: View.self, dataType: dataType, builds)
	}
}
public extension CollectionView where VerifyType == Void {
	/// 使用多个RegisteredView注册Cell
	func register<View>(_ builds: RegisteredView<View, ElementType>...) {

		register(viewType: View.self, dataType: ElementType.self, builds)
	}
}

public extension CollectionView {
	fileprivate func register<View, ElementType>(viewType: View.Type, dataType: ElementType.Type, _ builds: [RegisteredView<View, ElementType>]) {
		
		var registeredView = RegisteredView<View, ElementType>()
		for build in builds {
			registeredView.bind(from: build)
		}
		let reuseIdentifier = "\(dataType)-\(viewType)"
		registerViews.append((dataType, .init(registeredView, reuseIdentifier: reuseIdentifier)))
		register(CollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
	}
	fileprivate struct _RegisteredView {
		let view: () -> UIView
		let config: (UIView, Any) -> Void
		let when: (Any) -> Bool
		
		let created: ((UIView) -> Void)
		let tap: (UIView, Any) -> Bool
		let size: ((UICollectionView) -> CGSize?)
		
		let reuseIdentifier: String
		
		init<View, ElementType>(_ _view: RegisteredView<View, ElementType>, reuseIdentifier: String) {
			self.reuseIdentifier = reuseIdentifier
			self.view = _view._view ?? UIView.init
			
			self.when = { data in
				guard let when = _view._when, let data = data as? ElementType else { return false }
				return when(data)
			}
			
			self.config = { view, data in
				if let view = view as? View, let data = data as? ElementType {
					_view._config?(view, data)
				}
			}
			
			self.created = { view in
				if let view = view as? View {
					_view._created?(view)
				}
			}
			
			self.tap = { view, data in
				if let tap = _view._tap, let view = view as? View, let data = data as? ElementType {
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
	
	struct RegisteredView<View, ElementType> where View: UIView {
		public typealias R = RegisteredView<View, ElementType>
		fileprivate var _view: (() -> View)?
		fileprivate var _config: ((View, ElementType) -> Void)?
		fileprivate var _when: ((ElementType) -> Bool)?
		
		fileprivate var _created: ((View) -> Void)?
		fileprivate var _tap: ((View, ElementType) -> Void)?
		
		fileprivate var _size: ((UICollectionView) -> CGSize)?
		
		fileprivate init(view: (() -> View)? = nil, config: ((View, ElementType) -> Void)? = nil, when: ((ElementType) -> Bool)? = nil, created: ((View) -> Void)? = nil, tap: ((View, ElementType) -> Void)? = nil, size: ((UICollectionView) -> CGSize)? = nil) {
			_view = view
			_config = config
			_when = when
			_created = created
			_tap = tap
			_size = size
		}
		
		/// 创建View, 独立开是为了复用 View
		static public func view(_ act: @escaping () -> View) -> R { R(view: act) }
		/// 决定什么时候需要分配这个 View
		static public func when(_ act: @escaping (ElementType) -> Bool) -> R { R(when: act) }
		/// 配置View, 每次使用之前都会调用这个
		static public func config(_ act: @escaping (View, ElementType) -> Void) -> R { R(config: act) }
		/// 当首次创建了这个 View 就会调用
		static public func created(_ act: @escaping (View) -> Void) -> R { R(created: act) }
		/// 当点击了这个 View 就会调用
		static public func tap(_ act: @escaping (View, ElementType) -> Void) -> R { R(tap: act) }
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
	fileprivate class Delegate: NSObject, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
		
		weak var collection: CollectionView?
		typealias DelegateData = (Any, _RegisteredView)
		var datas: [[DelegateData]] = []
		
		var lastIndexPath: IndexPath {
			IndexPath(item: max(datas.last?.count ?? 0, 1)-1, section: max(datas.count, 1)-1)
		}
		
		func element(for indexPath: IndexPath) -> DelegateData {
			datas[indexPath.section][indexPath.item]
		}
		
		func prepareReload() {
			guard let collection = collection else { return }
			var registerViews = collection.registerViews
			
			func makeDatas(datas: [Any]) {
				var currentDatas = [DelegateData]()
				for data in datas {
					if let view = registerViews.first(where: {
						$0.dataType == type(of: data)
					}) {
						currentDatas.append((data, view.view))
					} else if let data = data as? [Any] {
						if !currentDatas.isEmpty {
							self.datas.append(currentDatas)
							currentDatas = []
						}
						makeDatas(datas: data)
					}
				}
				if !currentDatas.isEmpty {
					self.datas.append(currentDatas)
					
				}
			}
			self.datas = []
			makeDatas(datas: collection.datas)
			
			collection.indexToIdentifier = [:]
			for section in 0..<datas.count {
				for item in 0..<datas[section].count {
					if let registerd = collection.registerViews.first(where: {
						$0.view.when(datas[section][item].0)
					}) {
						collection.indexToIdentifier[IndexPath(item: item, section: section)] = registerd.view.reuseIdentifier
					} else if let registerd = collection.registerViews.first(where: {
						$0.dataType == type(of: datas[section][item].0)
					}) {
						collection.indexToIdentifier[IndexPath(item: item, section: section)] = registerd.view.reuseIdentifier
					} else {
						#if DEBUG
						fatalError("hit unuse data")
						#endif
					}
				}
			}
		}
		
		// MARK: - UICollectionViewDataSource
		func numberOfSections(in collectionView: UICollectionView) -> Int {
			datas.count
		}
		func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
			datas[section].count
		}
		
		func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
			guard
				let collection = collection,
				let identifier = collection.indexToIdentifier[indexPath],
				let registerd = collection.registerViews.first(where: { $0.view.reuseIdentifier == identifier })?.view,
				let cell = collection.dequeueReusableCell(withReuseIdentifier: registerd.reuseIdentifier, for: indexPath) as? CollectionViewCell
				else {
					return collectionView.dequeueReusableCell(withReuseIdentifier: "empty", for: indexPath)
			}
			if cell.createSubview == nil {
				cell.createSubview = registerd.view
				if let view = cell.subview {
					registerd.created(view)
				}
			}
			if let view = cell.subview {
				let element = self.element(for: indexPath).0
				// 这个不能放到willDisplay里去调, 不然如果是自适应尺寸的cell会出错
				registerd.config(view, element)
			}
			return cell
		}
		
		// MARK: - UICollectionViewDelegateFlowLayout
		func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
			guard let collection = collection else { return .zero }
			if let identifier = collection.indexToIdentifier[indexPath],
				let registerd = collection.registerViews.first(where: { $0.view.reuseIdentifier == identifier })?.view,
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
		func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
			guard
				let collection = collection,
				let identifier = collection.indexToIdentifier[indexPath],
				let registerd = collection.registerViews.first(where: { $0.view.reuseIdentifier == identifier })?.view,
				let cell = collection.cellForItem(at: indexPath) as? CollectionViewCell,
				let view = cell.subview
				else {
					return
			}
			
			let call = {
				let element = self.element(for: indexPath).0
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
		scrollToItem(at: mainDelegate.lastIndexPath, at: .right, animated: animated)
	}
}
