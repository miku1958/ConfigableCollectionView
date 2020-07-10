//
//  DataManager.swift
//  ConfigableCollectionView
//
//  Created by 庄黛淳华 on 2020/7/8.
//

import UIKit


// 1. 所有东西都用AnyHashable包起来
private typealias Data = _DataManager.Data
private typealias AnyHashable = _DataManager.AnyHashable
struct _DataManager {
	// MARK: - Data
	struct Data {
		var section: AnyHashable
		var items: [Any]
		@inline(__always)
		init<SectionIdentifierType>(sectionIdentifier: SectionIdentifierType, items: [Any] = []) where SectionIdentifierType: Hashable {
			self.section = AnyHashable(sectionIdentifier)
			self.items = items
		}
	}
	
	
	// MARK: - AnyHashable
	struct AnyHashable: Hashable {
		/// The value wrapped by this instance.
		///
		/// The `base` property can be cast back to its original type using one of
		/// the type casting operators (`as?`, `as!`, or `as`).
		var base: Any
		var baseType: Any.Type
		var hashValue: Int
		
		/// Creates a type-erased hashable value that wraps the given instance.
		///
		/// - Parameter base: A hashable value to wrap.
		@inline(__always)
		init<H>(_ base: H) where H : Hashable {
			self.base = base
			self.baseType = H.self
			self.hashValue = base.hashValue
		}
	}
}
extension AnyHashable {
	@inline(__always)
	static func == (lhs: Self, rhs: Self) -> Bool {
		guard
			lhs.baseType == rhs.baseType,
			lhs.hashValue == rhs.hashValue
		else {
			return false
		}
		return true
	}
	@inline(__always)
	static func == <R>(lhs: Self, rhs: R) -> Bool where R: Hashable {
		guard
			lhs.baseType == R.self,
			lhs.hashValue == rhs.hashValue
		else {
			return false
		}
		return true
	}
}
extension Array where Element == Data {
	subscript<SectionIdentifierType>(_ sectionIdentifier: SectionIdentifierType) -> Element? where SectionIdentifierType: Hashable {
		for item in self where item.section == sectionIdentifier {
			return item
		}
		return nil
	}
}

extension Array where Element: Hashable {
	@inline(__always)
	func contains(_ element: _DataManager.AnyHashable) -> Bool {
		for item in self where element == item {
			return true
		}
		return false
	}
}

// MARK: - DataManager
extension CollectionView {
	public struct DataManager {
		weak var collectionView: CollectionView?
		var _datas = [_DataManager.Data]()
		var _animatingDifferences: Bool = true
		var isUsingSectionSnapshot = false
	}
}

// MARK: - DataManager extension
extension CollectionView.DataManager {
	@inline(__always)
	@available(iOS 13.0, tvOS 13.0, *)
	public var animatingDifferences: Bool {
		set {
			_animatingDifferences = newValue
		}
		get {
			_animatingDifferences
		}
	}
}
extension CollectionView.DataManager {
	// iOS 13以前的注册cell
	func registerBelow13() {
		guard let collection = collectionView else { return }
		
		collection.indexToIdentifier = [:]
		for section in 0..<_datas.count {
			for item in 0..<_datas[section].items.count {
				if let registerd = collection.registerViews.first(where: {
					let item = _datas[section].items[item]
					if let item = item as? AnyHashable {
						return $0.registerd.when(item.base)
					} else {
						return $0.registerd.when(item)
					}
				}) {
					collection.indexToIdentifier[IndexPath(item: item, section: section)] = registerd.registerd.reuseIdentifier
				} else if let registerd = collection.registerViews.first(where: {
					let item = _datas[section].items[item]
					if let item = item as? AnyHashable {
						return $0.dataType == item.baseType
					} else {
						return $0.dataType == type(of: item)
					}
				}) {
					collection.indexToIdentifier[IndexPath(item: item, section: section)] = registerd.registerd.reuseIdentifier
				} else {
					#if DEBUG
					fatalError("hit unuse data")
					#endif
				}
			}
		}
	}
	func element(for indexPath: IndexPath) -> Any {
		let item = _datas[indexPath.section].items[indexPath.item]
		if let item = item as? AnyHashable {
			return item.base
		} else {
			return item
		}
	}
	var lastIndexPath: IndexPath {
		IndexPath(item: max(_datas.last?.items.count ?? 0, 1)-1, section: max(_datas.count, 1)-1)
	}
}
public extension CollectionView.DataManager {
	@inline(__always)
	var isEmpty: Bool {
		_datas.isEmpty
	}
	
	@inline(__always)
	mutating func appendSections<SectionIdentifierType>(_ identifiers: [SectionIdentifierType]) where SectionIdentifierType: Hashable {
		_datas.append(contentsOf: identifiers.map({
			Data(sectionIdentifier: $0)
		}))
	}
	
	// TODO:    得测试一下toIdentifier找不到会怎么样
	@inline(__always)
	mutating func insertSections<InsertType, BeforeType>(_ identifiers: [InsertType], beforeSection toIdentifier: BeforeType) where InsertType: Hashable, BeforeType: Hashable {
		
	}
	
	// TODO:    得测试一下toIdentifier找不到会怎么样
	@inline(__always)
	mutating func insertSections<InsertType, AfterType>(_ identifiers: [InsertType], afterSection toIdentifier: AfterType) where InsertType: Hashable, AfterType: Hashable {
		
	}
	
	@inline(__always)
	var numberOfItems: Int {
		_datas.reduce(0) {
			$0 + $1.items.count
		}
	}
	
	@inline(__always)
	var numberOfSections: Int {
		_datas.count
	}
	
	@inline(__always)
	func numberOfItems<SectionIdentifierType>(inSection identifier: SectionIdentifierType) -> Int where SectionIdentifierType: Hashable {
		_datas[identifier]?.items.count ?? 0
	}
	@inline(__always)
	func numberOfItems(atSectionIndex index: Int) -> Int {
		if index < _datas.count {
			return _datas[index].items.count
		} else {
			return 0
		}
	}
	
	@inline(__always)
	func indexOfSection<SectionIdentifierType>(_ identifier: SectionIdentifierType) -> Int? where SectionIdentifierType: Hashable {
		_datas.firstIndex {
			$0.section == identifier
		}
	}
	
	@inline(__always)
	mutating func deleteAllItems() {
		_datas = []
	}
	
	@inline(__always)
	mutating func reverseSections() {
		_datas.reverse()
	}
	
	@inline(__always)
	mutating func reverseItems<SectionIdentifierType>(inSection identifier: SectionIdentifierType) where SectionIdentifierType: Hashable {
		if let index = _datas.firstIndex(where: {
			$0.section == identifier
		}) {
			_datas[index].items.reverse()
		}
	}
	
	@inline(__always)
	mutating func reverseItems(atSectionIndex index: Int){
		if index < _datas.count {
			return _datas[index].items.reverse()
		}
	}
	
	
	@inline(__always)
	mutating func deleteSections<SectionIdentifierType>(_ identifiers: [SectionIdentifierType]) where SectionIdentifierType: Hashable {
		_datas.removeAll {
			identifiers.contains($0.section)
		}
	}
	
	@inline(__always)
	mutating func moveSection<SectionIdentifierType, BeforeType>(_ identifier: SectionIdentifierType, beforeSection: BeforeType) where SectionIdentifierType: Hashable, BeforeType: Hashable {
		guard
			let moevedIndex = _datas.firstIndex(where: {
				$0.section == identifier
			}),
			let beforeIndex = _datas.firstIndex(where: {
				$0.section == beforeSection
			})
		else {
			return
		}
		// TODO:    测试一下能不能一句话完成:
		// _datas.insert(_datas.remove(at: moevedIndex), at: beforeIndex)
		_datas.insert(_datas[moevedIndex], at: beforeIndex)
		_datas.remove(at: moevedIndex)
	}
	
	@inline(__always)
	mutating func moveSection<SectionIdentifierType, AfterType>(_ identifier: SectionIdentifierType, afterSection: AfterType) where SectionIdentifierType: Hashable, AfterType: Hashable {
		guard
			let moevedIndex = _datas.firstIndex(where: {
				$0.section == identifier
			}),
			let afterIndex = _datas.firstIndex(where: {
				$0.section == afterSection
			})
		else {
			return
		}
		// TODO:    测试一下能不能一句话完成:
		// _datas.insert(_datas.remove(at: moevedIndex), at: afterIndex+1)
		_datas.insert(_datas[moevedIndex], at: afterIndex+1)
		_datas.remove(at: moevedIndex)
	}
	
	@inline(__always)
	mutating func reloadSections<SectionIdentifierType>(_ identifiers: [SectionIdentifierType]) where SectionIdentifierType: Hashable {
		// TODO:    collectionView reload
	}
}

// MARK: - DataManager VerifyType == Void
extension CollectionView.DataManager where VerifyType == Void, DataType: Hashable {
	mutating func apply(_ datas: [DataType]) {
		_datas = [Data(sectionIdentifier: 0, items: datas)]
	}
	mutating func apply<SectionIdentifierType>(_ datas: [DataType], toSection: SectionIdentifierType) where SectionIdentifierType: Hashable {
		_datas = [Data(sectionIdentifier: toSection, items: datas)]
	}
	mutating func apply<SectionIdentifierType>(_ sections: [(datas: [DataType], sectionIdentifier: SectionIdentifierType)]) where SectionIdentifierType: Hashable {
		_datas = sections.map({ section in
			Data(sectionIdentifier: section.sectionIdentifier, items: section.datas)
		})
	}
	mutating func apply(_ sections: [[DataType]]) {
		_datas = sections.enumerated().map({
			Data(sectionIdentifier: $0.offset, items: $0.element)
		})
	}
	/// The section to which to add the items. If no value is provided, the items are appended to the last section of the snapshot.
	@inline(__always)
	public static func += <SectionIdentifierType>(lhs: inout Self, rhs: (datas: [DataType], toSection: SectionIdentifierType)) where SectionIdentifierType: Hashable {
		lhs._datas.append(Data(sectionIdentifier: rhs.toSection, items: rhs.datas))
	}
	@inline(__always)
	public static func += (lhs: inout Self, rhs: [DataType]) {
		lhs._datas.append(Data(sectionIdentifier: lhs._datas.count, items: rhs))
	}
	
	/// The section to which to add the items. If no value is provided, the items are appended to the last section of the snapshot.
	@inline(__always)
	public mutating func append<SectionIdentifierType>(items: [DataType], toSection section: SectionIdentifierType) where SectionIdentifierType: Hashable {
		_datas.append(Data(sectionIdentifier: section, items: items))
	}
	@inline(__always)
	mutating func appendToLast(_ items: [DataType]) {
		if _datas.isEmpty {
			_datas.append(Data(sectionIdentifier: _datas.count))
		}
		_datas[_datas.count-1].items.append(contentsOf: items)
	}
	
	// TODO:    得测试一下NSDiffableDataSourceSnapshot找不到的话会怎么样
	@inline(__always)
	public mutating func insertItems<ItemIdentifierType>(_ identifiers: [DataType], beforeItem beforeIdentifier: ItemIdentifierType) where ItemIdentifierType: Hashable {
		
	}
	
	// TODO:    得测试一下NSDiffableDataSourceSnapshot找不到的话会怎么样
	@inline(__always)
	public mutating func insertItems<ItemIdentifierType>(_ identifiers: [ItemIdentifierType], afterItem afterIdentifier: ItemIdentifierType) where ItemIdentifierType: Hashable {
		
	}
	
	@inline(__always)
	public func items<SectionIdentifierType>(inSection identifier: SectionIdentifierType) -> [DataType]? where SectionIdentifierType: Hashable {
		_datas.first {
			$0.section == identifier
		}?.items as? [DataType]
	}
	@inline(__always)
	public func items(atSectionIndex index: Int) -> [DataType]? {
		if index < _datas.count {
			return _datas[index].items as? [DataType]
		}
		return nil
	}
	
	@inline(__always)
	public func indexPathOfItem(_ identifier: DataType) -> [IndexPath] {
		_datas.enumerated().flatMap { (section, element) in
			element.items.enumerated().compactMap { (item, element) in
				if (element as! DataType) == identifier {
					return IndexPath(item: item, section: section)
				} else {
					return nil
				}
			}
		}
	}
	@inline(__always)
	public func sectionIdentifier<SectionIdentifierType>(containingItem identifier: DataType) -> [SectionIdentifierType] where SectionIdentifierType: Hashable {
		_datas.filter {
			$0.items.contains {
				($0 as! DataType) == identifier
			}
		}.compactMap {
			$0.section as? SectionIdentifierType
		}
	}
	
	@inline(__always)
	public mutating func deleteItems(_ identifiers: [DataType]) {
		for identifier in identifiers {
			var section = 0
			while section < _datas.count {
				_datas[section].items.removeAll {
					($0 as! DataType) == identifier
				}
				section += 1
			}
		}
	}
	
	// TODO:    得研究一下同一个 NSDiffableDataSourceSnapshot, 不同 section 存在相同的 item 时会怎么样
	@inline(__always)
	public mutating func moveItem(_ identifier: DataType, beforeItem: DataType) {
		
	}
	
	@inline(__always)
	public mutating func moveItem(_ identifier: DataType, afterItem: DataType) {
		
	}
	
	@inline(__always)
	public mutating func reloadItems(_ identifiers: [DataType]) {
		// TODO:    collectionView reload
	}
	
	@inline(__always)
	public func items() -> [DataType] {
		_datas.flatMap {
			$0.items as! [DataType]
		}
	}
	
	@inline(__always)
	public func visibleItems() -> [DataType] {
		guard let collectionView = collectionView else {
			return []
		}
		if isUsingSectionSnapshot {
			return []
		} else {
			return collectionView.indexPathsForVisibleItems.map {
				_datas[$0.section].items[$0.item] as! DataType
			}
		}
	}
}
// MARK: - DataManager VerifyType == Any
public extension CollectionView.DataManager where VerifyType == Any {
	@inline(__always)
	mutating func apply<ItemIdentifierType>(_ datas: [ItemIdentifierType]) where ItemIdentifierType: Hashable {
		_datas = [Data(sectionIdentifier: 0, items: datas.map(AnyHashable.init))]
	}
	
	@inline(__always)
	mutating func apply<ItemIdentifierType, SectionIdentifierType>(_ datas: [ItemIdentifierType], toSection section: SectionIdentifierType) where ItemIdentifierType: Hashable, SectionIdentifierType: Hashable {
		_datas = [Data(sectionIdentifier: section, items: datas.map(AnyHashable.init))]
	}
	
	@inline(__always)
	mutating func apply<ItemIdentifierType, SectionIdentifierType>(_ sections: [(datas: [ItemIdentifierType], sectionIdentifier: SectionIdentifierType)]) where ItemIdentifierType: Hashable, SectionIdentifierType: Hashable {
		_datas = sections.map({ section in
			Data(sectionIdentifier: section.sectionIdentifier, items: section.datas.map(AnyHashable.init))
		})
	}
	
	@inline(__always)
	mutating func apply<ItemIdentifierType>(_ sections: [[ItemIdentifierType]]) where ItemIdentifierType: Hashable {
		_datas = sections.enumerated().map({
			Data(sectionIdentifier: $0.offset, items: $0.element.map(AnyHashable.init))
		})
	}
	/// The section to which to add the items. If no value is provided, the items are appended to the last section of the snapshot.
	@inline(__always)
	static func += <ItemIdentifierType, SectionIdentifierType>(lhs: inout Self, rhs: (datas: [ItemIdentifierType], toSection: SectionIdentifierType)) where ItemIdentifierType: Hashable, SectionIdentifierType: Hashable {
		lhs._datas.append(Data(sectionIdentifier: rhs.toSection, items: rhs.datas.map(AnyHashable.init)))
	}
	@inline(__always)
	static func += <ItemIdentifierType>(lhs: inout Self, rhs: [ItemIdentifierType]) where ItemIdentifierType: Hashable {
		lhs._datas.append(Data(sectionIdentifier: lhs._datas.count, items: rhs.map(AnyHashable.init)))
	}
	
	/// The section to which to add the items. If no value is provided, the items are appended to the last section of the snapshot.
	@inline(__always)
	mutating func append<ItemIdentifierType, SectionIdentifierType>(_ items: [ItemIdentifierType], toSection: SectionIdentifierType) where ItemIdentifierType: Hashable, SectionIdentifierType: Hashable {
		_datas.append(Data(sectionIdentifier: toSection, items: items.map(AnyHashable.init)))
	}
	@inline(__always)
	mutating func appendToLast<ItemIdentifierType>(_ items: [ItemIdentifierType]) where ItemIdentifierType: Hashable {
		if _datas.isEmpty {
			_datas.append(Data(sectionIdentifier: _datas.count))
		}
		_datas[_datas.count-1].items.append(contentsOf: items.map(AnyHashable.init))
	}
	
	// TODO:    得测试一下NSDiffableDataSourceSnapshot找不到的话会怎么样
	@inline(__always)
	mutating func insertItems<InsertType, BeforeType>(_ identifiers: [InsertType], beforeItem beforeIdentifier: BeforeType) where InsertType: Hashable, BeforeType: Hashable {
		
	}
	
	// TODO:    得测试一下NSDiffableDataSourceSnapshot找不到的话会怎么样
	@inline(__always)
	mutating func insertItems<InsertType, AfterType>(_ identifiers: [InsertType], afterItem afterIdentifier: AfterType) where InsertType: Hashable, AfterType: Hashable {
		
	}
	
	@inline(__always)
	func items<ItemIdentifierType, SectionIdentifierType>(inSection identifier: SectionIdentifierType) -> [ItemIdentifierType]? where ItemIdentifierType: Hashable, SectionIdentifierType: Hashable {
		_datas.first {
			$0.section == identifier
		}?.items.compactMap {
			$0 as? ItemIdentifierType
		}
	}
	@inline(__always)
	func items<ItemIdentifierType>(atSectionIndex index: Int) -> [ItemIdentifierType]? where ItemIdentifierType: Hashable {
		if index < _datas.count {
			return _datas[index].items.compactMap {
				$0 as? ItemIdentifierType
			}
		}
		return nil
	}
	
	
	@inline(__always)
	func indexPathOfItem<ItemIdentifierType>(_ identifier: ItemIdentifierType) -> [IndexPath] where ItemIdentifierType: Hashable {
		_datas.enumerated().flatMap { (section, element) in
			element.items.enumerated().compactMap { (item, element) in
				if (element as? ItemIdentifierType) == identifier {
					return IndexPath(item: item, section: section)
				} else {
					return nil
				}
			}
		}
	}
	@inline(__always)
	func sectionIdentifier<ItemIdentifierType, SectionIdentifierType>(containingItem identifier: ItemIdentifierType) -> [SectionIdentifierType] where ItemIdentifierType: Hashable , SectionIdentifierType: Hashable {
		_datas.filter {
			$0.items.contains {
				($0 as? ItemIdentifierType) == identifier
			}
		}.compactMap {
			$0.section as? SectionIdentifierType
		}
	}
	
	@inline(__always)
	mutating func deleteItems<ItemIdentifierType>(_ identifiers: [ItemIdentifierType]) where ItemIdentifierType: Hashable {
		for identifier in identifiers {
			var section = 0
			while section < _datas.count {
				_datas[section].items.removeAll {
					($0 as? ItemIdentifierType) == identifier
				}
				section += 1
			}
		}
	}
	
	// TODO:    得研究一下同一个 NSDiffableDataSourceSnapshot, 不同 section 存在相同的 item 时会怎么样
	@inline(__always)
	mutating func moveItem<MovedType, BeforeType>(_ identifier: MovedType, beforeItem: BeforeType) where MovedType: Hashable, BeforeType: Hashable {
		
	}
	
	@inline(__always)
	mutating func moveItem<MovedType, AfterType>(_ identifier: MovedType, afterItem: AfterType) where MovedType: Hashable, AfterType: Hashable {
		
	}
	
	@inline(__always)
	mutating func reloadItems<ItemIdentifierType>(_ identifiers: [ItemIdentifierType]) where ItemIdentifierType: Hashable {
		
	}
	@inline(__always)
	func items<ItemIdentifierType>() -> [ItemIdentifierType] where ItemIdentifierType: Hashable {
		_datas.flatMap {
			$0.items.compactMap {
				$0 as? ItemIdentifierType
			}
		}
	}
	
	@inline(__always)
	func visibleItems<ItemIdentifierType>() -> [ItemIdentifierType] where ItemIdentifierType: Hashable {
		guard let collectionView = collectionView else {
			return []
		}
		if isUsingSectionSnapshot {
			return []
		} else {
			return collectionView.indexPathsForVisibleItems.compactMap {
				_datas[$0.section].items[$0.item] as? ItemIdentifierType
			}
		}
	}

}

#if swift(>=5.3)
// MARK: - DataManager iOS 14
// MARK: - 以下内容依赖于 NSDiffableDataSourceSectionSnapshot 所以直接操作就行
@available(iOS 14.0, tvOS 14.0, *)
public extension CollectionView.DataManager {
	
}
// MARK: - DataManager VerifyType == Void
@available(iOS 14.0, tvOS 14.0, *)
public extension CollectionView.DataManager where VerifyType == Void, DataType: Hashable {
	// TODO:    得测试一下NSDiffableDataSourceSectionSnapshot的parent为nil会怎么样
	@inline(__always)
	mutating func append(childItems: [DataType], to parent: DataType) {
		isUsingSectionSnapshot = true
	}
	@inline(__always)
	mutating func expand(parents: [DataType]) {
		isUsingSectionSnapshot = true
	}
	
	@inline(__always)
	mutating func collapse(parents: [DataType]) {
		isUsingSectionSnapshot = true
	}
	// TODO:    要测试一下snapshot里的rootItem和parent哪个没了, 感觉应该是把parent删掉后把snapshot插入到对应位置了
	@inline(__always)
	mutating func replace(childrenOf parent: DataType, using snapshot: NSDiffableDataSourceSectionSnapshot<DataType>) {
		isUsingSectionSnapshot = true
	}
	
	@inline(__always)
	mutating func insert(_ snapshot: NSDiffableDataSourceSectionSnapshot<DataType>, before item: DataType) {
		isUsingSectionSnapshot = true
	}
	
	@inline(__always)
	mutating func insert(_ snapshot: NSDiffableDataSourceSectionSnapshot<DataType>, after item: DataType) {
		isUsingSectionSnapshot = true
	}
	@inline(__always)
	func isExpanded(_ item: DataType) -> Bool {
		false
	}
	
	@inline(__always)
	func isVisible(_ item: DataType) -> Bool {
		false
	}
	
	@inline(__always)
	func contains(_ item: DataType) -> Bool {
		false
	}
	
	@inline(__always)
	func level(of item: DataType) -> Int {
		0
	}
	// TODO:    得测试一下展开后的数据和展开前的index有没有区别
	@inline(__always)
	func index(of item: DataType) -> Int? {
		nil
	}
	
	@inline(__always)
	func parent(of child: DataType) -> DataType? {
		nil
	}
	
	@inline(__always)
	func snapshot(of parent: DataType, includingParent: Bool = false) -> NSDiffableDataSourceSectionSnapshot<DataType> {
		.init()
	}
	
	@inline(__always)
	func rootItems() -> [DataType] {
		[]
	}
}
// MARK: - DataManager VerifyType == Any
@available(iOS 14.0, tvOS 14.0, *)
public extension CollectionView.DataManager where VerifyType == Any {
	@inline(__always)
	mutating func append<ChildType, ParentType>(_ items: [ChildType], to parent: ParentType) where ChildType: Hashable, ParentType: Hashable {
		isUsingSectionSnapshot = true
	}
	@inline(__always)
	mutating func expand<ParentType>(parents: [ParentType]) where ParentType: Hashable {
		isUsingSectionSnapshot = true
	}
	
	@inline(__always)
	mutating func collapse<ParentType>(parents: [ParentType]) where ParentType: Hashable {
		isUsingSectionSnapshot = true
	}
	
	@inline(__always)
	mutating func replace<ChildType, ParentType>(childrenOf parent: ParentType, using snapshot: NSDiffableDataSourceSectionSnapshot<ChildType>) where ChildType: Hashable, ParentType: Hashable {
		isUsingSectionSnapshot = true
	}
	
	@inline(__always)
	mutating func insert<ChildType, BeforeType>(_ snapshot: NSDiffableDataSourceSectionSnapshot<ChildType>, before item: BeforeType) where ChildType: Hashable, BeforeType: Hashable {
		isUsingSectionSnapshot = true
	}
	
	@inline(__always)
	mutating func insert<ChildType, AfterType>(_ snapshot: NSDiffableDataSourceSectionSnapshot<ChildType>, after item: AfterType) where ChildType: Hashable, AfterType: Hashable {
		isUsingSectionSnapshot = true
	}
	@inline(__always)
	func isExpanded<ParentType>(_ item: ParentType) -> Bool where ParentType: Hashable {
		false
	}
	
	@inline(__always)
	func isVisible<ParentType>(_ item: ParentType) -> Bool where ParentType: Hashable {
		false
	}
	
	@inline(__always)
	func contains<ParentType>(_ item: ParentType) -> Bool where ParentType: Hashable {
		false
	}
	
	@inline(__always)
	func level<ItemIdentifierType>(of item: ItemIdentifierType) -> Int where ItemIdentifierType: Hashable {
		0
	}
	
	@inline(__always)
	func index<ItemIdentifierType>(of item: ItemIdentifierType) -> Int? where ItemIdentifierType: Hashable {
		nil
	}
	
	@inline(__always)
	func parent<ChildType, ParentType>(of child: ChildType) -> ParentType? where ChildType: Hashable, ParentType: Hashable {
		nil
	}
	
	@inline(__always)
	func snapshot<ChildType, ParentType>(of parent: ParentType, includingParent: Bool = false) -> NSDiffableDataSourceSectionSnapshot<ChildType> where ChildType: Hashable, ParentType: Hashable {
		.init()
	}
	@inline(__always)
	func rootItems<ParentType>() -> [ParentType] where ParentType: Hashable {
		[]
	}
}
#endif
