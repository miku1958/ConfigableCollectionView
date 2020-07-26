//
//  DataManager_SectionIdentifier_ItemIdentifier_AnyHashable.swift
//  ConfigableCollectionView
//
//  Created by 庄黛淳华 on 2020/7/26.
//

import Foundation

extension CollectionView.DataManager where ItemIdentifier == CollectionView.AnyHashable, SectionIdentifier == CollectionView.AnyHashable {
	
	@inlinable
	@discardableResult
	public func applySections<Section, Item>(_ sections: [(section: Section, items: [Item])]) -> ReloadHandler where Section: Hashable, Item: Hashable {
		_applySections(sections, map: {
			.init(.package($0))
		})
	}
	
	@inlinable
	@discardableResult
	public func applyItems<Section, Item>(_ items: [Item], updatedSection sectionIdentifier: Section) -> ReloadHandler where Section: Hashable, Item: Hashable {
		_applyItems(items, updatedSection: sectionIdentifier, map: {
			.init(.package($0))
		})
	}
	@inlinable
	@discardableResult
	public func appendItems<Section, Item>(_ items: [Item], toSection sectionIdentifier: Section) -> ReloadHandler where Section: Hashable, Item: Hashable {
		_appendItems(items, toSection: sectionIdentifier, map: {
			.init(.package($0))
		})
	}
	@inlinable
	public func allItems<Section, Item>(inSection identifier: Section) -> [Item]? where Section: Hashable, Item: Hashable {
		_allItems(inSection: identifier)
	}
	
	@inlinable
	public func sectionIdentifier<Section, Item>(containingItem identifier: Item) -> Section? where Section: Hashable, Item: Hashable {
		_sectionIdentifier(containingItem: identifier)
	}
	#if swift(>=5.3)
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	public func visibleItems<Section, Item>(inSection identifier: Section) -> [Item]? where Section: Hashable, Item: Hashable {
		_visibleItems(inSection: identifier, compactMap: {
			$0.base as? Item
		})
	}
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	public func rootItems<Section, Item>(inSection identifier: Section) -> [Item]? where Section: Hashable, Item: Hashable {
		_rootItems(inSection: identifier)
	}
	#endif
}
