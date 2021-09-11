//
//  CollectionView+RegisterView.swift
//  ConfigableCollectionView
//
//  Created by 庄黛淳华 on 2020/7/28.
//

import UIKit

public extension CollectionView where ItemType == Any {
	/// 使用多个RegisteredView注册Cell
	/// view: 创建View, 独立开是为了复用 View, 如果view为UICollectionViewCell, 则初始化无效(不会调用), 会使用UICollectionView.dequeue来实现
	func register<View, Item>(dataType: Item.Type, @ViewBuilder view: @escaping () -> View?, _ builds: RegisteredView<View, Item>...) where View: ViewProtocol, Item: Hashable {
		register(view: view, builds)
	}
	
	//func register<View, Item>(dataType: ItemType.Type, @ViewBuilder supplementaryView: @escaping () -> View?, in kind: ElementKindSection, _ builds: RegisteredView<View, Item>...) where View: ViewProtocol {
	//		register(supplementaryView: supplementaryView, in: kind, builds)
	//	}
}
public extension CollectionView where ItemType: Hashable {
	/// 使用多个RegisteredView注册Cell
	func register<View>(@ViewBuilder view: @escaping () -> View?, _ builds: RegisteredView<View, ItemType>...) where View: ViewProtocol {
		register(view: view, builds)
	}
	
	//	func register<View>(@ViewBuilder supplementaryView: @escaping () -> View?, in kind: ElementKindSection, _ builds: RegisteredView<View, ItemType>...) where View: ViewProtocol {
	//		register(supplementaryView: supplementaryView, in: kind, builds)
	//	}
}

extension CollectionView {
	@inline(__always)
	func register<View, Item>(view: @escaping () -> View?, _ builds: [RegisteredView<View, Item>]) where View: ViewProtocol {
		
		var registeredView = RegisteredView<View, Item>(_view: view)
		for build in builds {
			registeredView.bind(from: build)
		}
		
		let reuseIdentifier = UUID().uuidString
		registerViews[ObjectIdentifier(Item.self), default: []].append(.init(registeredView, reuseIdentifier: reuseIdentifier))
		if let type = View.self as? UICollectionViewCell.Type {
			register(type, forCellWithReuseIdentifier: reuseIdentifier)
		} else {
			register(CollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
		}
	}
	//	public enum ElementKindSection {
	//		case header
	//		case footer
	//		fileprivate var identifier: String {
	//			switch self {
	//			case .header:
	//				return UICollectionView.elementKindSectionHeader
	//			case .footer:
	//				return UICollectionView.elementKindSectionFooter
	//			}
	//		}
	//	}
	//	@inline(__always)
	//	func register<View, Item>(supplementaryView: @escaping () -> View?, in kind: ElementKindSection, _ builds: [RegisteredView<View, Item>]) where View: ViewProtocol {
	//
	//		var registeredView = RegisteredView<View, Item>(_view: supplementaryView)
	//		for build in builds {
	//			registeredView.bind(from: build)
	//		}
	//
	//		let reuseIdentifier = UUID().uuidString
	//		registerSupplementaryViews[ObjectIdentifier(Item.self), default: []].append(.init(registeredView, reuseIdentifier: reuseIdentifier))
	//		if let type = View.self as? UICollectionReusableView.Type {
	//			register(type, forSupplementaryViewOfKind: kind.identifier, withReuseIdentifier: reuseIdentifier)
	//		} else {
	//			register(CollectionViewSupplementaryView.self, forSupplementaryViewOfKind: kind.identifier, withReuseIdentifier: reuseIdentifier)
	//		}
	//	}
	
	@inline(__always)
	func registeredView(for indexPath: IndexPath, item: Any?) -> _RegisteredView? {
		guard let item = item ?? _dataManager.element(for: indexPath) else {
			return nil
		}
		if item is CollectionView.AnyHashable {
			fatalError()
		}
		guard let registerViews = registerViews[ObjectIdentifier(type(of: item))] else { return nil }
		return registerViews.first {
			$0.when?(.init(collectionView: self, data: item, indexPath: indexPath)) ?? false
		} ?? registerViews.first(where: {
			$0.when == nil
		})
	}
	
	struct _RegisteredView {
		struct Data {
			let collectionView: CollectionView
			let data: Any
			let indexPath: IndexPath
		}
		struct DataWithView {
			let collectionView: CollectionView
			let view: UIView
			let data: Any
			let indexPath: IndexPath
			var _configurationState: Any?
		}
		let view: () -> UIView?
		let config: (DataWithView) -> Void
		let when: ((Data) -> Bool)?
		
		let tap: (DataWithView) -> Bool
		let flowLayoutSize: ((Data) -> CGSize?)
		
		let willDisplay: ((DataWithView) -> Void)
		let endDisplay: ((DataWithView) -> Void)
		
		let reuseIdentifier: String
		
		init<View, Item>(_ _view: RegisteredView<View, Item>, reuseIdentifier: String) {
			self.reuseIdentifier = reuseIdentifier
			self.view =  {
				_view._view?() as? UIView
			}
			
			let Data = RegisteredView<View, Item>.DataFrom
			let DataWithView = RegisteredView<View, Item>.DataWithViewFrom
			
			if let when = _view._when {
				self.when = { data in
					guard let data = Data(data) else { return false }
					return when(data)
				}
			} else {
				self.when = nil
			}
			
			self.config = { data in
				if let data = DataWithView(data) {
					_view._config?(data)
				}
			}
			
			self.tap = { data in
				if let tap = _view._tap, let data = DataWithView(data) {
					tap(data)
					return true
				}
				return false
			}
			
			self.flowLayoutSize = { data in
				if let size = _view._flowLayoutSize, let data = Data(data) {
					return size(data)
				}
				return nil
			}
			
			self.willDisplay = { data in
				if let data = DataWithView(data) {
					_view._willDisplay?(data)
				}
			}
			
			self.endDisplay = { data in
				if let data = DataWithView(data) {
					_view._endDisplay?(data)
				}
			}
		}
	}
	
	public struct RegisteredView<ViewIdentifier, ItemIdentifier> where ViewIdentifier: ViewProtocol {
		public struct Data {
			public let collectionView: CollectionView
			public let data: ItemIdentifier
			public let indexPath: IndexPath
		}
		public struct DataWithView<ItemIdentifier> {
			public let collectionView: CollectionView
			public let view: ViewIdentifier
			public let data: ItemIdentifier
			public let indexPath: IndexPath
			let _configurationState: Any?
			#if swift(>=5.3)
			@available(iOS 14.0, *)
			public var configurationState: UICellConfigurationState {
				_configurationState as? UICellConfigurationState ?? .init(traitCollection: .current)
			}
			#endif
		}
		static func DataFrom(_ from: _RegisteredView.Data) -> Data? {
			guard let data = from.data as? ItemIdentifier else {
				return nil
			}
			return .init(collectionView: from.collectionView, data: data, indexPath: from.indexPath)
		}
		static func DataWithViewFrom(_ from: _RegisteredView.DataWithView) -> DataWithView<ItemIdentifier>? {
			guard let view = from.view as? ViewIdentifier, let data = from.data as? ItemIdentifier else {
				return nil
			}
			return .init(collectionView: from.collectionView, view: view, data: data, indexPath: from.indexPath, _configurationState: from._configurationState)
		}
		
		public typealias R = RegisteredView<ViewIdentifier, ItemIdentifier>
		var _view: (() -> ViewIdentifier?)?
		var _config: ((DataWithView<ItemIdentifier>) -> Void)?
		var _when: ((Data) -> Bool)?
		
		var _tap: ((DataWithView<ItemIdentifier>) -> Void)?
		
		var _flowLayoutSize: ((Data) -> CGSize)?
		
		var _willDisplay: ((DataWithView<ItemIdentifier>) -> Void)?
		var _endDisplay: ((DataWithView<ItemIdentifier>) -> Void)?
		
		/// 决定什么时候需要分配这个 View
		static public func when(_ act: @escaping (Data) -> Bool) -> R {
			R(_when: act)
		}
		/// 配置View, 每次使用之前都会调用这个
		static public func config<Mapped>(map transform: @escaping (ItemIdentifier) throws -> Mapped,_ act: @escaping (DataWithView<Mapped>) -> Void) -> R {
			R(_config: {
				guard let data = try? transform($0.data) else { return }
				act(.init(collectionView: $0.collectionView, view: $0.view, data: data, indexPath: $0.indexPath, _configurationState: $0._configurationState))
			})
		}
		/// 配置View, 每次使用之前都会调用这个
		static public func config<Mapped>(compactMap transform: @escaping (ItemIdentifier) throws -> Mapped?,_ act: @escaping (DataWithView<Mapped>) -> Void) -> R {
			R(_config: {
				guard let data = try? transform($0.data) else { return }
				act(.init(collectionView: $0.collectionView, view: $0.view, data: data, indexPath: $0.indexPath, _configurationState: $0._configurationState))
			})
		}
		static public func config(_ act: @escaping (DataWithView<ItemIdentifier>) -> Void) -> R {
			R(_config: act)
		}
		/// 当点击了这个 View 就会调用
		static public func tap(_ act: @escaping (DataWithView<ItemIdentifier>) -> Void) -> R {
			R(_tap: act)
		}
		/// 给这个 View 一个默认尺寸
		static public func flowLayoutSize(_ act: @escaping (Data) -> CGSize) -> R {
			R(_flowLayoutSize: act)
		}
		
		/// 配置View, 每次使用之前都会调用这个
		static public func willDisplay(_ act: @escaping (DataWithView<ItemIdentifier>) -> Void) -> R {
			R(_willDisplay: act)
		}
		
		/// 配置View, 每次使用之前都会调用这个
		static public func didEndDisplay(_ act: @escaping (DataWithView<ItemIdentifier>) -> Void) -> R {
			R(_endDisplay: act)
		}
		
		@inline(__always)
		mutating func bind(from r: R) {
			if let act = r._view { _view = act }
			if let act = r._when { _when = act }
			if let act = r._config { _config = act }
			if let act = r._tap { _tap = act }
			if let act = r._flowLayoutSize { _flowLayoutSize = act }
			if let act = r._willDisplay { _willDisplay = act }
			if let act = r._endDisplay { _endDisplay = act }
		}
	}
}
