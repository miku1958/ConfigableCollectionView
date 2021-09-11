//
//  DataManager_ItemIdentifier_AnyHashable.swift
//  ConfigableCollectionView
//
//  Created by 庄黛淳华 on 2020/7/26.
//

import UIKit

extension CollectionView.DataManager where ItemIdentifier == CollectionView.AnyHashable {
	@inlinable
	@discardableResult
	public func applyItems<Item>(_ items: [Item], atSectionIndex index: Int) -> ReloadHandler where Item: Hashable {
		_applyItems(items, atSectionIndex: index, map: {
			.init(.package($0))
		})
	}
	@inlinable
	@discardableResult
	public func applySections<Item>(_ sections: [[Item]]) -> ReloadHandler where Item: Hashable {
		_applySections(sections, map: {
			.init(.package($0))
		})
	}
	@inlinable
	public func itemIdentifier<Item>(for indexPath: IndexPath) -> Item? where Item : Hashable {
		element(for: indexPath) as? Item
	}
	
	@inlinable
	public func indexPath<Item>(for itemIdentifier: Item) -> IndexPath? where Item : Hashable {
		_indexPath(for: .package(itemIdentifier))
	}
	
	@inlinable
	@discardableResult
	public func appendItems<Item>(_ items: [Item]) -> ReloadHandler where Item: Hashable {
		_appendItems(items, map: {
			.init(.package($0))
		})
	}
	
	@inlinable
	@discardableResult
	public func insertItems<Insert, Before>(_ identifiers: [Insert], beforeItem beforeIdentifier: Before) -> ReloadHandler where Insert: Hashable, Before: Hashable {
		_insertItems(identifiers, to: beforeIdentifier, indexOffset: 0, map: {
			.init(.package($0))
		})
	}
	
	@inlinable
	@discardableResult
	public func insertItems<Insert, After>(_ identifiers: [Insert], afterItem afterIdentifier: After) -> ReloadHandler where Insert: Hashable, After: Hashable {
		_insertItems(identifiers, to: afterIdentifier, indexOffset: 1, map: {
			.init(.package($0))
		})
	}
	
	@inlinable
	public func allItems<Item>() -> [Item] where Item: Hashable{
		_allItems()
	}
	
	@inlinable
	public func allItems<Item>(atSectionIndex index: Int) -> [Item]? where Item: Hashable {
		_allItems(atSectionIndex: index)
	}
	
	@inlinable
	@discardableResult
	public func deleteItems<Item>(_ identifiers: [Item]) -> ReloadHandler where Item: Hashable {
		_deleteItems(identifiers)
	}
	
	@inlinable
	@discardableResult
	public func moveItem<Moved, Before>(_ identifier: Moved, beforeItem beforeIdentifier: Before) -> ReloadHandler where Moved: Hashable, Before: Hashable {
		_moveItem(.package(identifier), toIdentifier: .package(beforeIdentifier), indexOffset: 0)
	}
	@inlinable
	@discardableResult
	public func moveItem<Moved, After>(_ identifier: Moved, afterItem afterIdentifier: After) -> ReloadHandler where Moved: Hashable, After: Hashable {
		_moveItem(.package(identifier), toIdentifier: .package(afterIdentifier), indexOffset: 1)
	}
	
	@inlinable
	@discardableResult
	public func reloadItems<Item>(_ identifiers: [Item]) -> ReloadHandler where Item: Hashable {
		_reloadItems(identifiers, map: CollectionView.AnyHashable.package)
	}
	
	@inlinable
	public func contains<Item>(_ item: Item) -> Bool where Item : Hashable {
		_contains(item)
	}
	
	#if swift(>=5.3)
	// MARK: - iOS14的内容
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	@discardableResult
	public func appendChildItems<Child, Parent>(_ childItems: [Child], to parent: Parent, recursivePath: ((Child) -> [Child])? = nil) -> ReloadHandler where Child: Hashable, Parent: Hashable {
		_appendChildItems(childItems, to: parent, recursivePath: recursivePath, map:  {
			.init(.package($0))
		})
	}
	
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	@discardableResult
	public func expand<Parent>(parents: [Parent]) -> ReloadHandler where Parent: Hashable {
		_expand(parents: parents.map {
			.package($0)
		})
	}
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	@discardableResult
	public func collapse<Parent>(parents: [Parent]) -> ReloadHandler where Parent: Hashable {
		_collapse(parents: parents.map {
			.package($0)
		})
	}
	
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	public func isExpanded<Parent>(_ item: Parent) -> Bool where Parent: Hashable {
		_isExpanded(.package(item))
	}
	
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	public func level<Item>(of item: Item) -> Int where Item: Hashable {
		_level(of: .package(item))
	}
	
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	public func parent<Child, Parent>(of child: Child) -> Parent? where Child: Hashable, Parent: Hashable {
		_parent(of: .package(child))
	}
	
	@available(iOS 14.0, *)
	@inlinable
	public func visibleItems<Item>() -> [Item] where Item: Hashable {
		_visibleItems(compactMap: {
			$0.base as? Item
		})
	}
	
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	public func visibleItems<Item>(atSectionIndex index: Int) -> [Item]? where Item: Hashable {
		_visibleItems(atSectionIndex: index, compactMap: {
			$0.base as? Item
		})
	}
	
	@available(iOS 14.0, *)
	@inlinable
	public func isVisible<Item>(_ item: Item) -> Bool where Item: Hashable {
		_isVisible(.package(item))
	}
	
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	public func rootItems<Item>() -> [Item] where Item: Hashable {
		_rootItems()
	}
	
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	public func rootItems<Item>(atSectionIndex index: Int) -> [Item]? where Item: Hashable {
		_rootItems(atSectionIndex: index)
	}
	#endif
}
