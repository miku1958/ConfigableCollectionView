//
//  DataSourceDiff13.swift
//  ConfigableCollectionView
//
//  Created by 庄黛淳华 on 2020/7/12.
//

import Foundation
private typealias AnyHashable = CollectionView<Any, Any>.AnyHashable
/// for test
@available(iOS 13.0, tvOS 13.0, *)
class DataSourceDiff13<ItemIdentifier, VerifyType> where ItemIdentifier : Hashable  {
	let collectionView: UICollectionView
	fileprivate var snapshot = NSDiffableDataSourceSnapshot<AnyHashable, ItemIdentifier>()
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
	
	func appendSections<Section>(_ identifiers: [Section]) where Section: Hashable {
		snapshot.appendSections(identifiers.map {
			.package($0)
		})
	}
	// TODO:    得测试一下toIdentifier找不到会怎么样
	func insertSections<Insert, Before>(_ identifiers: [Insert], beforeSection toIdentifier: Before) where Insert: Hashable, Before: Hashable {
		snapshot.insertSections(identifiers.map({
			.package($0)
		}), beforeSection: .package(toIdentifier))
	}
	// TODO:    得测试一下toIdentifier找不到会怎么样
	func insertSections<Insert, After>(_ identifiers: [Insert], afterSection toIdentifier: After) where Insert: Hashable, After: Hashable {
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
	func numberOfItems<Section>(inSection identifier: Section) -> Int where Section: Hashable {
		snapshot.numberOfItems(inSection: .package(identifier))
	}
	func numberOfItems(atSectionIndex index: Int) -> Int {
		snapshot.numberOfItems(inSection: snapshot.sectionIdentifiers[index])
	}
	
	func indexOfSection<Section>(_ identifier: Section) -> Int? where Section: Hashable {
		snapshot.indexOfSection(.package(identifier))
	}
	
	func deleteSections<Section>(_ identifiers: [Section]) where Section: Hashable {
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
	func reverseRootItems<Section>(inSection identifier: Section) where Section: Hashable {
		let section = AnyHashable.package(identifier)
		let items: [ItemIdentifier] = snapshot.itemIdentifiers(inSection: section).reversed()
		snapshot.deleteItems(items)
		snapshot.appendItems(items, toSection: section)
	}
	func reverseRootItems(atSectionIndex index: Int) {
		let section = snapshot.sectionIdentifiers[index]
		let items: [ItemIdentifier] = snapshot.itemIdentifiers(inSection: section).reversed()
		snapshot.deleteItems(items)
		snapshot.appendItems(items, toSection: section)
	}
	// TODO:    得测试NSDiffableDataSourceSnapshot找不到的话怎么处理
	func moveSection<Section, Before>(_ identifier: Section, beforeSection: Before) where Section: Hashable, Before: Hashable {
		snapshot.moveSection(.package(identifier), beforeSection: .package(beforeSection))
	}
	func moveSection<Section, After>(_ identifier: Section, afterSection: After) where Section: Hashable, After: Hashable {
		snapshot.moveSection(.package(identifier), afterSection: .package(afterSection))
	}
	// TODO:    NSDiffableDataSourceSectionSnapshot 没有 reload, 得看一下 NSDiffableDataSourceSnapshot 的 reload 到底做了什么
	func reloadSections<Section>(_ identifiers: [Section]) where Section: Hashable {
		snapshot.reloadSections(identifiers.map {
			.package($0)
		})
	}
}

// MARK: - DataManager VerifyType == Void
@available(iOS 13.0, *)
extension DataSourceDiff13 where VerifyType == Void {
	func apply(_ datas: [ItemIdentifier]) {
		snapshot = .init()
		// 没有section的情况下会直接闪退
		snapshot.appendSections([.package(0)])
		snapshot.appendItems(datas)
	}
	func apply<Section>(_ datas: [ItemIdentifier], toSection sectionIdentifier: Section) where Section: Hashable {
		snapshot = .init()
		snapshot.appendItems(datas, toSection: .package(sectionIdentifier))
	}
	
	func apply(_ sections: [[ItemIdentifier]]) {
		snapshot = .init()
		for pair in sections.enumerated() {
			snapshot.appendItems(pair.element, toSection: .package(pair.offset))
		}
	}
	
	func itemIdentifier(for indexPath: IndexPath) -> ItemIdentifier? {
		element(for: indexPath) as? ItemIdentifier
	}
	// TODO:    NSDiffableDataSourceSectionSnapshot.index(of:) 拿到的是不是 visibleItems 的 index?
	func indexPath(for itemIdentifier: ItemIdentifier) -> IndexPath? {
		for section in snapshot.sectionIdentifiers.enumerated() {
			if let itemIndex = snapshot.itemIdentifiers(inSection: section.element).firstIndex(of: itemIdentifier) {
				return IndexPath(item: itemIndex, section: section.offset)
			}
		}
		return nil
	}
	
	// TODO:    如果 NSDiffableDataSourceSnapshot 为空会怎么样
	func append<Section>(items: [ItemIdentifier], toSection sectionIdentifier: Section) where Section: Hashable {
		snapshot.appendItems(items, toSection: .package(sectionIdentifier))
	}
	
	// TODO:    如果 NSDiffableDataSourceSnapshot 为空会怎么样
	func append(_ items: [ItemIdentifier]) {
		snapshot.appendItems(items)
	}
	// TODO:    得测试一下NSDiffableDataSourceSnapshot找不到的话会怎么样
	func insertItems(_ identifiers: [ItemIdentifier], beforeItem beforeIdentifier: ItemIdentifier) {
		snapshot.insertItems(identifiers, beforeItem: beforeIdentifier)
	}
	// TODO:    得测试一下NSDiffableDataSourceSnapshot找不到的话会怎么样
	func insertItems(_ identifiers: [ItemIdentifier], afterItem afterIdentifier: ItemIdentifier) {
		snapshot.insertItems(identifiers, afterItem: afterIdentifier)
	}
	
	func allItems() -> [ItemIdentifier] {
		snapshot.itemIdentifiers
	}
	func allItems<Section>(inSection identifier: Section) -> [ItemIdentifier] where Section: Hashable {
		snapshot.itemIdentifiers(inSection: .package(identifier))
	}
	
	func allItems(atSectionIndex index: Int) -> [ItemIdentifier] {
		let sections = snapshot.sectionIdentifiers
		if index < sections.count {
			return snapshot.itemIdentifiers(inSection: sections[index])
		}
		return []
	}
	
	func indexPathOfItem(_ identifier: ItemIdentifier) -> IndexPath? {
		for (section, element) in snapshot.sectionIdentifiers.enumerated() {
			for (item, element) in snapshot.itemIdentifiers(inSection: element).enumerated() {
				if element == identifier {
					return IndexPath(item: item, section: section)
				}
			}
		}
		return nil
	}
	
	func sectionIdentifier<Section>(containingItem identifier: ItemIdentifier) -> Section? where Section: Hashable {
		snapshot.sectionIdentifier(containingItem: identifier)?.base as? Section
	}
	
	func deleteItems(_ identifiers: [ItemIdentifier]) {
		snapshot.deleteItems(identifiers)
	}
	// TODO:    得研究一下同一个 NSDiffableDataSourceSnapshot, 不同 section 存在相同的 item 时会怎么样
	func moveItem(_ identifier: ItemIdentifier, beforeItem: ItemIdentifier) {
		snapshot.moveItem(identifier, beforeItem: beforeItem)
	}
	
	func moveItem(_ identifier: ItemIdentifier, afterItem: ItemIdentifier) {
		snapshot.moveItem(identifier, afterItem: afterItem)
	}
	
	// TODO:    测试一下NSDiffableDataSourceSnapshot.reloadItems有什么用
	func reloadItems(_ identifiers: [ItemIdentifier]) {
		snapshot.reloadItems(identifiers)
	}
	
	func contains(_ item: ItemIdentifier) -> Bool {
		snapshot.sectionIdentifier(containingItem: item) != nil
	}
}
// MARK: - DataManager VerifyType == Any aka: ItemIdentifier == AnyHashable
@available(iOS 13.0, *)
extension DataSourceDiff13 where ItemIdentifier == AnyHashable {
	func apply<Item>(_ datas: [Item]) where Item: Hashable {
		snapshot = .init()
		// TODO:    得测试一下没有section的情况下会怎么样
		snapshot.appendItems(datas.map({ .package($0) }))
	}
	func apply<Section, Item>(_ datas: [Item], toSection sectionIdentifier: Section) where Item: Hashable, Section: Hashable {
		snapshot = .init()
		snapshot.appendItems(datas.map({ .package($0) }), toSection: .package(sectionIdentifier))
	}
	
	func apply<Item>(_ sections: [[Item]]) where Item: Hashable {
		snapshot = .init()
		for pair in sections.enumerated() {
			snapshot.appendItems(pair.element.map({ .package($0) }), toSection: .package(pair.offset))
		}
	}
	func itemIdentifier<Item>(for indexPath: IndexPath) -> Item? where Item : Hashable {
		element(for: indexPath) as? Item
	}
	
	// TODO:    NSDiffableDataSourceSectionSnapshot.index(of:) 拿到的是不是 visibleItems 的 index?
	func indexPath<Item>(for itemIdentifier: Item) -> IndexPath? where Item : Hashable {
		for section in snapshot.sectionIdentifiers.enumerated() {
			if let itemIndex = snapshot.itemIdentifiers(inSection: section.element).firstIndex(of: .package(itemIdentifier)) {
				return IndexPath(item: itemIndex, section: section.offset)
			}
		}
		return nil
	}
	
	// TODO:    如果 NSDiffableDataSourceSnapshot 为空会怎么样
	func append<Section, Item>(_ items: [Item], toSection sectionIdentifier: Section) where Item: Hashable, Section: Hashable {
		snapshot.appendItems(items.map({ .package($0) }), toSection: .package(sectionIdentifier))
	}
	func append<Item>(_ items: [Item]) where Item: Hashable {
		//如果 NSDiffableDataSourceSnapshot 为空会crash: 'NSInternalInconsistencyException', reason: 'There are currently no sections in the data source. Please add a section first.'
		if snapshot.numberOfSections == 0 {
			snapshot.appendSections([.package(0)])
		}
		snapshot.appendItems(items.map({ .package($0) }))
	}
	// TODO:    得测试一下NSDiffableDataSourceSnapshot找不到的话会怎么样
	func insertItems<Insert, Before>(_ identifiers: [Insert], beforeItem beforeIdentifier: Before) where Insert: Hashable, Before: Hashable {
		snapshot.insertItems(identifiers.map({ .package($0) }), beforeItem: .package(beforeIdentifier))
	}
	// TODO:    得测试一下NSDiffableDataSourceSnapshot找不到的话会怎么样
	func insertItems<Insert, After>(_ identifiers: [Insert], afterItem afterIdentifier: After) where Insert: Hashable, After: Hashable {
		snapshot.insertItems(identifiers.map({ .package($0) }), afterItem: .package(afterIdentifier))
	}
	func allItems<Section, Item>(inSection identifier: Section) -> [Item] where Item: Hashable, Section: Hashable {
		snapshot.itemIdentifiers(inSection: .package(identifier)).compactMap {
			$0.base as? Item
		}
	}
	func allItems<Item>(atSectionIndex index: Int) -> [Item] where Item: Hashable {
		let sections = snapshot.sectionIdentifiers
		if index < sections.count {
			return snapshot.itemIdentifiers(inSection: sections[index]).compactMap {
				$0.base as? Item
			}
		}
		
		return []
	}
	func allItems<Item>() -> [Item] where Item: Hashable {
		snapshot.itemIdentifiers.compactMap {
			$0 as? Item
		}
	}
	
	func indexPathOfItem<Item>(_ identifier: Item) -> IndexPath? where Item: Hashable {
		for (section, element) in snapshot.sectionIdentifiers.enumerated() {
			for (item, element) in snapshot.itemIdentifiers(inSection: element).enumerated() {
				if element == identifier {
					return IndexPath(item: item, section: section)
				}
			}
		}
		return nil
	}
	func sectionIdentifier<Section, Item>(containingItem identifier: Item) -> Section? where Item: Hashable , Section: Hashable {
		snapshot.sectionIdentifier(containingItem: .package(identifier))?.base as? Section
	}
	func deleteItems<Item>(_ identifiers: [Item]) where Item: Hashable {
		snapshot.deleteItems(identifiers.map({ .package($0) }))
	}
	// TODO:    得研究一下同一个 NSDiffableDataSourceSnapshot, 不同 section 存在相同的 item 时会怎么样
	func moveItem<Moved, Before>(_ identifier: Moved, beforeItem: Before) where Moved: Hashable, Before: Hashable {
		snapshot.moveItem(.package(identifier), beforeItem: .package(beforeItem))
	}
	func moveItem<Moved, After>(_ identifier: Moved, afterItem: After) where Moved: Hashable, After: Hashable {
		snapshot.moveItem(.package(identifier), afterItem: .package(afterItem))
	}
	func reloadItems<Item>(_ identifiers: [Item]) where Item: Hashable {
		snapshot.reloadItems(identifiers.map({ .package($0) }))
	}
	
	func contains<Item>(_ item: Item) -> Bool where Item : Hashable {
		snapshot.sectionIdentifier(containingItem: .package(item)) != nil
	}
}
