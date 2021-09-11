//
//  DataManager_SectionType_Hashable_ItemIdentifier_AnyHashable.swift
//  ConfigableCollectionView
//
//  Created by 庄黛淳华 on 2020/7/26.
//

import UIKit

extension CollectionView.DataManager where ItemIdentifier == CollectionView.AnyHashable, SectionType: Hashable {
	@inlinable
	@discardableResult
	public func applySections<Item>(_ sections: [(section: SectionType, items: [Item])]) -> ReloadHandler where Item: Hashable {
		_applySections(sections, map: {
			.init(.package($0))
		})
	}
	@inlinable
	@discardableResult
	public func applyItems<Item>(_ items: [Item], updatedSection sectionIdentifier: SectionType) -> ReloadHandler where Item: Hashable {
		_applyItems(items, updatedSection: sectionIdentifier, map: {
			.init(.package($0))
		})
	}
	@inlinable
	@discardableResult
	public func appendItems<Item>(_ items: [Item], toSection sectionIdentifier: SectionType) -> ReloadHandler where Item: Hashable {
		_appendItems(items, toSection: sectionIdentifier, map: {
			.init(.package($0))
		})
	}
	@inlinable
	public func allItems<Item>(inSection identifier: SectionType) -> [Item]? where Item: Hashable {
		_allItems(inSection: identifier)
	}
	
	@inlinable
	public func sectionIdentifier<Item>(containingItem identifier: Item) -> SectionType? where Item: Hashable  {
		_sectionIdentifier(containingItem: identifier)
	}
	#if swift(>=5.3)
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	public func visibleItems<Item>(inSection identifier: SectionType) -> [Item]? where Item: Hashable, SectionType : Hashable {
		_visibleItems(inSection: identifier, compactMap: {
			$0.base as? Item
		})
	}
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	public func rootItems<Item>(inSection identifier: SectionType) -> [Item]? where Item: Hashable {
		_rootItems(inSection: identifier)
	}
	#endif
}
