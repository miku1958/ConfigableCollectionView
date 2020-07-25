//
//  DataSourceDiff13.swift
//  ConfigableCollectionView
//
//  Created by 庄黛淳华 on 2020/7/12.
//

import Foundation
private typealias AnyHashable = CollectionView<Any, Any, Any>.AnyHashable
/// for test
@available(iOS 13.0, tvOS 13.0, *)
class DataSourceDiff13<ItemIdentifierType, VerifyType> where ItemIdentifierType : Hashable  {
	let collectionView: UICollectionView
	fileprivate var snapshot = NSDiffableDataSourceSnapshot<AnyHashable, ItemIdentifierType>()
	init(collectionView: UICollectionView) {
		self.collectionView = collectionView
	}
}
@available(iOS 13.0, *)
extension DataSourceDiff13 {
	func element(for indexPath: IndexPath) -> Any {
		let section = snapshot.sectionIdentifiers[indexPath.section]
		let item = snapshot.itemIdentifiers(inSection: section)[indexPath.item]
	
		if let item = item as? AnyHashable {
			return item.base
		} else {
			return item
		}
	}
	var isEmpty: Bool {
		snapshot.numberOfSections == 0
	}
	var lastIndexPath: IndexPath? {
		let sectionIndex = numberOfSections-1
		guard sectionIndex >= 0 else {
			return nil
		}
		let itemCount = snapshot.numberOfItems(inSection: snapshot.sectionIdentifiers[sectionIndex])
		
		guard itemCount > 0 else {
			return nil
		}
		return IndexPath(item: itemCount-1, section: sectionIndex)
	}
	
	func appendSections<SectionIdentifierType>(_ identifiers: [SectionIdentifierType]) where SectionIdentifierType: Hashable {
		snapshot.appendSections(identifiers.map {
			.package($0)
		})
	}
	// TODO:    得测试一下toIdentifier找不到会怎么样
	func insertSections<InsertType, BeforeType>(_ identifiers: [InsertType], beforeSection toIdentifier: BeforeType) where InsertType: Hashable, BeforeType: Hashable {
		snapshot.insertSections(identifiers.map({
			.package($0)
		}), beforeSection: .package(toIdentifier))
	}
	// TODO:    得测试一下toIdentifier找不到会怎么样
	func insertSections<InsertType, AfterType>(_ identifiers: [InsertType], afterSection toIdentifier: AfterType) where InsertType: Hashable, AfterType: Hashable {
		snapshot.insertSections(identifiers.map({
			.package($0)
		}), afterSection: .package(toIdentifier))
	}
	
	var numberOfSections: Int {
		snapshot.numberOfSections
	}
	
	var numberOfItems: Int {
		snapshot.numberOfItems
	}
	func numberOfItems<SectionIdentifierType>(inSection identifier: SectionIdentifierType) -> Int where SectionIdentifierType: Hashable {
		snapshot.numberOfItems(inSection: .package(identifier))
	}
	func numberOfItems(atSectionIndex index: Int) -> Int {
		snapshot.numberOfItems(inSection: snapshot.sectionIdentifiers[index])
	}
	
	func indexOfSection<SectionIdentifierType>(_ identifier: SectionIdentifierType) -> Int? where SectionIdentifierType: Hashable {
		snapshot.indexOfSection(.package(identifier))
	}
	
	func deleteSections<SectionIdentifierType>(_ identifiers: [SectionIdentifierType]) where SectionIdentifierType: Hashable {
		snapshot.deleteSections(identifiers.map {
			.package($0)
		})
	}
	
	func deleteAllItems() {
		snapshot.deleteAllItems()
	}
	
	func reverseSections() {
		var datas = snapshot.sectionIdentifiers.map {
			($0, snapshot.itemIdentifiers(inSection: $0))
		}
		datas.reverse()
		snapshot.deleteAllItems()
		for data in datas {
			// TODO:    测试一下在没用section的情况下是否能这样做
			snapshot.appendItems(data.1, toSection: data.0)
		}
	}
	func reverseRootItems<SectionIdentifierType>(inSection identifier: SectionIdentifierType) where SectionIdentifierType: Hashable {
		let section = AnyHashable.package(identifier)
		let items: [ItemIdentifierType] = snapshot.itemIdentifiers(inSection: section).reversed()
		snapshot.deleteItems(items)
		snapshot.appendItems(items, toSection: section)
	}
	func reverseRootItems(atSectionIndex index: Int) {
		let section = snapshot.sectionIdentifiers[index]
		let items: [ItemIdentifierType] = snapshot.itemIdentifiers(inSection: section).reversed()
		snapshot.deleteItems(items)
		snapshot.appendItems(items, toSection: section)
	}
	// TODO:    得测试NSDiffableDataSourceSnapshot找不到的话怎么处理
	func moveSection<SectionIdentifierType, BeforeType>(_ identifier: SectionIdentifierType, beforeSection: BeforeType) where SectionIdentifierType: Hashable, BeforeType: Hashable {
		snapshot.moveSection(.package(identifier), beforeSection: .package(beforeSection))
	}
	func moveSection<SectionIdentifierType, AfterType>(_ identifier: SectionIdentifierType, afterSection: AfterType) where SectionIdentifierType: Hashable, AfterType: Hashable {
		snapshot.moveSection(.package(identifier), afterSection: .package(afterSection))
	}
	// TODO:    NSDiffableDataSourceSectionSnapshot 没有 reload, 得看一下 NSDiffableDataSourceSnapshot 的 reload 到底做了什么
	func reloadSections<SectionIdentifierType>(_ identifiers: [SectionIdentifierType]) where SectionIdentifierType: Hashable {
		snapshot.reloadSections(identifiers.map {
			.package($0)
		})
	}
}

// MARK: - DataManager VerifyType == Void
@available(iOS 13.0, *)
extension DataSourceDiff13 where VerifyType == Void {
	func apply(_ datas: [ItemIdentifierType]) {
		snapshot = .init()
		// 没有section的情况下会直接闪退
		snapshot.appendSections([.package(0)])
		snapshot.appendItems(datas)
	}
	func apply<SectionIdentifierType>(_ datas: [ItemIdentifierType], toSection sectionIdentifier: SectionIdentifierType) where SectionIdentifierType: Hashable {
		snapshot = .init()
		snapshot.appendItems(datas, toSection: .package(sectionIdentifier))
	}
	
	func apply(_ sections: [[ItemIdentifierType]]) {
		snapshot = .init()
		for pair in sections.enumerated() {
			snapshot.appendItems(pair.element, toSection: .package(pair.offset))
		}
	}
	
	func itemIdentifier(for indexPath: IndexPath) -> ItemIdentifierType? {
		element(for: indexPath) as? ItemIdentifierType
	}
	// TODO:    NSDiffableDataSourceSectionSnapshot.index(of:) 拿到的是不是 visibleItems 的 index?
	func indexPath(for itemIdentifier: ItemIdentifierType) -> IndexPath? {
		for section in snapshot.sectionIdentifiers.enumerated() {
			if let itemIndex = snapshot.itemIdentifiers(inSection: section.element).firstIndex(of: itemIdentifier) {
				return IndexPath(item: itemIndex, section: section.offset)
			}
		}
		return nil
	}
	
	// TODO:    如果 NSDiffableDataSourceSnapshot 为空会怎么样
	func append<SectionIdentifierType>(items: [ItemIdentifierType], toSection sectionIdentifier: SectionIdentifierType) where SectionIdentifierType: Hashable {
		snapshot.appendItems(items, toSection: .package(sectionIdentifier))
	}
	
	// TODO:    如果 NSDiffableDataSourceSnapshot 为空会怎么样
	func append(_ items: [ItemIdentifierType]) {
		snapshot.appendItems(items)
	}
	// TODO:    得测试一下NSDiffableDataSourceSnapshot找不到的话会怎么样
	func insertItems(_ identifiers: [ItemIdentifierType], beforeItem beforeIdentifier: ItemIdentifierType) {
		snapshot.insertItems(identifiers, beforeItem: beforeIdentifier)
	}
	// TODO:    得测试一下NSDiffableDataSourceSnapshot找不到的话会怎么样
	func insertItems(_ identifiers: [ItemIdentifierType], afterItem afterIdentifier: ItemIdentifierType) {
		snapshot.insertItems(identifiers, afterItem: afterIdentifier)
	}
	
	func allItems() -> [ItemIdentifierType] {
		snapshot.itemIdentifiers
	}
	func allItems<SectionIdentifierType>(inSection identifier: SectionIdentifierType) -> [ItemIdentifierType] where SectionIdentifierType: Hashable {
		snapshot.itemIdentifiers(inSection: .package(identifier))
	}
	
	func allItems(atSectionIndex index: Int) -> [ItemIdentifierType] {
		let sections = snapshot.sectionIdentifiers
		if index < sections.count {
			return snapshot.itemIdentifiers(inSection: sections[index])
		}
		return []
	}
	
	func indexPathOfItem(_ identifier: ItemIdentifierType) -> IndexPath? {
		for (section, element) in snapshot.sectionIdentifiers.enumerated() {
			for (item, element) in snapshot.itemIdentifiers(inSection: element).enumerated() {
				if element == identifier {
					return IndexPath(item: item, section: section)
				}
			}
		}
		return nil
	}
	
	func sectionIdentifier<SectionIdentifierType>(containingItem identifier: ItemIdentifierType) -> SectionIdentifierType? where SectionIdentifierType: Hashable {
		snapshot.sectionIdentifier(containingItem: identifier)?.base as? SectionIdentifierType
	}
	
	func deleteItems(_ identifiers: [ItemIdentifierType]) {
		snapshot.deleteItems(identifiers)
	}
	// TODO:    得研究一下同一个 NSDiffableDataSourceSnapshot, 不同 section 存在相同的 item 时会怎么样
	func moveItem(_ identifier: ItemIdentifierType, beforeItem: ItemIdentifierType) {
		snapshot.moveItem(identifier, beforeItem: beforeItem)
	}
	
	func moveItem(_ identifier: ItemIdentifierType, afterItem: ItemIdentifierType) {
		snapshot.moveItem(identifier, afterItem: afterItem)
	}
	
	// TODO:    测试一下NSDiffableDataSourceSnapshot.reloadItems有什么用
	func reloadItems(_ identifiers: [ItemIdentifierType]) {
		snapshot.reloadItems(identifiers)
	}
	
	func contains(_ item: ItemIdentifierType) -> Bool {
		snapshot.sectionIdentifier(containingItem: item) != nil
	}
}
// MARK: - DataManager VerifyType == Any aka: ItemIdentifierType == AnyHashable
@available(iOS 13.0, *)
extension DataSourceDiff13 where ItemIdentifierType == AnyHashable {
	func apply<ItemIdentifierType>(_ datas: [ItemIdentifierType]) where ItemIdentifierType: Hashable {
		snapshot = .init()
		// TODO:    得测试一下没有section的情况下会怎么样
		snapshot.appendItems(datas.map({ .package($0) }))
	}
	func apply<ItemIdentifierType, SectionIdentifierType>(_ datas: [ItemIdentifierType], toSection sectionIdentifier: SectionIdentifierType) where ItemIdentifierType: Hashable, SectionIdentifierType: Hashable {
		snapshot = .init()
		snapshot.appendItems(datas.map({ .package($0) }), toSection: .package(sectionIdentifier))
	}
	
	func apply<ItemIdentifierType>(_ sections: [[ItemIdentifierType]]) where ItemIdentifierType: Hashable {
		snapshot = .init()
		for pair in sections.enumerated() {
			snapshot.appendItems(pair.element.map({ .package($0) }), toSection: .package(pair.offset))
		}
	}
	func itemIdentifier<ItemIdentifierType>(for indexPath: IndexPath) -> ItemIdentifierType? where ItemIdentifierType : Hashable {
		element(for: indexPath) as? ItemIdentifierType
	}
	
	// TODO:    NSDiffableDataSourceSectionSnapshot.index(of:) 拿到的是不是 visibleItems 的 index?
	func indexPath<ItemIdentifierType>(for itemIdentifier: ItemIdentifierType) -> IndexPath? where ItemIdentifierType : Hashable {
		for section in snapshot.sectionIdentifiers.enumerated() {
			if let itemIndex = snapshot.itemIdentifiers(inSection: section.element).firstIndex(of: .package(itemIdentifier)) {
				return IndexPath(item: itemIndex, section: section.offset)
			}
		}
		return nil
	}
	
	// TODO:    如果 NSDiffableDataSourceSnapshot 为空会怎么样
	func append<ItemIdentifierType, SectionIdentifierType>(_ items: [ItemIdentifierType], toSection sectionIdentifier: SectionIdentifierType) where ItemIdentifierType: Hashable, SectionIdentifierType: Hashable {
		snapshot.appendItems(items.map({ .package($0) }), toSection: .package(sectionIdentifier))
	}
	func append<ItemIdentifierType>(_ items: [ItemIdentifierType]) where ItemIdentifierType: Hashable {
		//如果 NSDiffableDataSourceSnapshot 为空会crash: 'NSInternalInconsistencyException', reason: 'There are currently no sections in the data source. Please add a section first.'
		if snapshot.numberOfSections == 0 {
			snapshot.appendSections([.package(0)])
		}
		snapshot.appendItems(items.map({ .package($0) }))
	}
	// TODO:    得测试一下NSDiffableDataSourceSnapshot找不到的话会怎么样
	func insertItems<InsertType, BeforeType>(_ identifiers: [InsertType], beforeItem beforeIdentifier: BeforeType) where InsertType: Hashable, BeforeType: Hashable {
		snapshot.insertItems(identifiers.map({ .package($0) }), beforeItem: .package(beforeIdentifier))
	}
	// TODO:    得测试一下NSDiffableDataSourceSnapshot找不到的话会怎么样
	func insertItems<InsertType, AfterType>(_ identifiers: [InsertType], afterItem afterIdentifier: AfterType) where InsertType: Hashable, AfterType: Hashable {
		snapshot.insertItems(identifiers.map({ .package($0) }), afterItem: .package(afterIdentifier))
	}
	func allItems<ItemIdentifierType, SectionIdentifierType>(inSection identifier: SectionIdentifierType) -> [ItemIdentifierType] where ItemIdentifierType: Hashable, SectionIdentifierType: Hashable {
		snapshot.itemIdentifiers(inSection: .package(identifier)).compactMap {
			$0.base as? ItemIdentifierType
		}
	}
	func allItems<ItemIdentifierType>(atSectionIndex index: Int) -> [ItemIdentifierType] where ItemIdentifierType: Hashable {
		let sections = snapshot.sectionIdentifiers
		if index < sections.count {
			return snapshot.itemIdentifiers(inSection: sections[index]).compactMap {
				$0.base as? ItemIdentifierType
			}
		}
		
		return []
	}
	func allItems<ItemIdentifierType>() -> [ItemIdentifierType] where ItemIdentifierType: Hashable {
		snapshot.itemIdentifiers.compactMap {
			$0 as? ItemIdentifierType
		}
	}
	
	func indexPathOfItem<ItemIdentifierType>(_ identifier: ItemIdentifierType) -> IndexPath? where ItemIdentifierType: Hashable {
		for (section, element) in snapshot.sectionIdentifiers.enumerated() {
			for (item, element) in snapshot.itemIdentifiers(inSection: element).enumerated() {
				if element == identifier {
					return IndexPath(item: item, section: section)
				}
			}
		}
		return nil
	}
	func sectionIdentifier<ItemIdentifierType, SectionIdentifierType>(containingItem identifier: ItemIdentifierType) -> SectionIdentifierType? where ItemIdentifierType: Hashable , SectionIdentifierType: Hashable {
		snapshot.sectionIdentifier(containingItem: .package(identifier))?.base as? SectionIdentifierType
	}
	func deleteItems<ItemIdentifierType>(_ identifiers: [ItemIdentifierType]) where ItemIdentifierType: Hashable {
		snapshot.deleteItems(identifiers.map({ .package($0) }))
	}
	// TODO:    得研究一下同一个 NSDiffableDataSourceSnapshot, 不同 section 存在相同的 item 时会怎么样
	func moveItem<MovedType, BeforeType>(_ identifier: MovedType, beforeItem: BeforeType) where MovedType: Hashable, BeforeType: Hashable {
		snapshot.moveItem(.package(identifier), beforeItem: .package(beforeItem))
	}
	func moveItem<MovedType, AfterType>(_ identifier: MovedType, afterItem: AfterType) where MovedType: Hashable, AfterType: Hashable {
		snapshot.moveItem(.package(identifier), afterItem: .package(afterItem))
	}
	func reloadItems<ItemIdentifierType>(_ identifiers: [ItemIdentifierType]) where ItemIdentifierType: Hashable {
		snapshot.reloadItems(identifiers.map({ .package($0) }))
	}
	
	func contains<ItemIdentifierType>(_ item: ItemIdentifierType) -> Bool where ItemIdentifierType : Hashable {
		snapshot.sectionIdentifier(containingItem: .package(item)) != nil
	}
}
