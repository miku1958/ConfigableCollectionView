//
//  DataManager_ItemType_Hashable.swift
//  ConfigableCollectionView
//
//  Created by 庄黛淳华 on 2020/7/26.
//

import Foundation

extension CollectionView.DataManager where ItemType: Hashable {
	@inlinable
	@discardableResult
	public func applyItems(_ items: [ItemIdentifier]) -> ReloadHandler {
		_applyItems(items, map: {
			.init($0)
		})
	}
	@inlinable
	@discardableResult
	public func applyItems(_ items: [ItemIdentifier], atSection index: Int) -> ReloadHandler {
		_applyItems(items, atSection: index, map: {
			.init($0)
		})
	}
	@inlinable
	@discardableResult
	public func applySections(_ sections: [[ItemIdentifier]]) -> ReloadHandler {
		_applySections(sections, map: {
			.init($0)
		})
	}
	@inlinable
	public func itemIdentifier(for indexPath: IndexPath) -> ItemIdentifier? {
		element(for: indexPath) as? ItemIdentifier
	}
	
	// NSDiffableDataSourceSectionSnapshot.index(of:) 拿到的是 allItems 的 index
	@inlinable
	public func indexPath(for itemIdentifier: ItemIdentifier) -> IndexPath? {
		_indexPath(for: itemIdentifier)
	}
	
	@inlinable
	@discardableResult
	public func appendItems(_ items: [ItemIdentifier]) -> ReloadHandler {
		_appendItems(items, map: {
			.init($0)
		})
	}
	
	@inlinable
	@discardableResult
	public func insertItems(_ identifiers: [ItemIdentifier], beforeItem beforeIdentifier: ItemIdentifier) -> ReloadHandler {
		_insertItems(identifiers, to: beforeIdentifier, indexOffset: 0, map: {
			.init($0)
		})
	}
	
	@inlinable
	@discardableResult
	public func insertItems(_ identifiers: [ItemIdentifier], afterItem afterIdentifier: ItemIdentifier) -> ReloadHandler {
		_insertItems(identifiers, to: afterIdentifier, indexOffset: 1, map: {
			.init($0)
		})
	}
	
	@inlinable
	public func allItems() -> [ItemIdentifier] {
		_allItems()
	}
	
	@inlinable
	public func allItems(atSection index: Int) -> [ItemIdentifier]? {
		_allItems(atSectionIndex: index)
	}
	
	@inlinable
	@discardableResult
	public func deleteItems(_ identifiers: [ItemIdentifier]) -> ReloadHandler {
		_deleteItems(identifiers)
	}
	
	@inlinable
	@discardableResult
	public func moveItem(_ identifier: ItemIdentifier, beforeItem beforeIdentifier: ItemIdentifier) -> ReloadHandler {
		_moveItem(identifier, toIdentifier: beforeIdentifier)
	}
	
	@inlinable
	@discardableResult
	public func moveItem(_ identifier: ItemIdentifier, afterItem afterIdentifier: ItemIdentifier) -> ReloadHandler {
		_moveItem(identifier, toIdentifier: afterIdentifier)
	}
	
	@inlinable
	@discardableResult
	public func reloadItems(_ identifiers: [ItemIdentifier]) -> ReloadHandler {
		_reloadItems(identifiers, map: { $0 })
	}
	
	@inlinable
	public func contains(_ item: ItemIdentifier) -> Bool {
		_contains(item)
	}
	
	#if swift(>=5.3)
	// MARK: - iOS14的内容
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	@discardableResult
	public func appendChildItems(_ childItems: [ItemIdentifier], to parent: ItemIdentifier?) -> ReloadHandler {
		_appendChildItems(childItems, to: parent, map: {
			.init($0)
		})
	}
	
	// expand 的对象找不到不会有任何效果
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	@discardableResult
	public func expand(parents: [ItemIdentifier]) -> ReloadHandler {
		_expand(parents: parents)
	}
	
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	@discardableResult
	public func collapse(parents: [ItemIdentifier]) -> ReloadHandler {
		_collapse(parents: parents)
	}
	
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	public func isExpanded(_ item: ItemIdentifier) -> Bool {
		_isExpanded(item)
	}
	
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	public func level(of item: ItemIdentifier) -> Int {
		_level(of: item)
	}
	
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	public func parent(of child: ItemIdentifier) -> ItemIdentifier? {
		_parent(of: child)
	}
	
	@available(iOS 14.0, *)
	@inlinable
	public func visibleItems() -> [ItemIdentifier] {
		_visibleItems(compactMap: nil)
	}
	
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	public func visibleItems(atSection index: Int) -> [ItemIdentifier]? {
		_visibleItems(atSection: index, compactMap: nil)
	}
	
	@available(iOS 14.0, *)
	@inlinable
	public func isVisible(_ item: ItemIdentifier) -> Bool {
		_isVisible(item)
	}
	
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	public func rootItems() -> [ItemIdentifier] {
		_rootItems()
	}
	
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	public func rootItems(atSection index: Int) -> [ItemIdentifier]? {
		_rootItems(atSectionIndex: index)
	}
	#endif
}
