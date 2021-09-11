//
//  DataManager_SectionType_ItemType_Hashable.swift
//  ConfigableCollectionView
//
//  Created by 庄黛淳华 on 2020/7/26.
//

import UIKit

extension CollectionView.DataManager where ItemType: Hashable, SectionType: Hashable {
	
	@inlinable
	@discardableResult
	public func applySections(_ sections: [(section: SectionType, items: [ItemIdentifier])]) -> ReloadHandler {
		_applySections(sections, map: {
			.init($0)
		})
	}
	@inlinable
	@discardableResult
	public func applyItems(_ items: [ItemIdentifier], updatedSection sectionIdentifier: SectionType) -> ReloadHandler {
		_applyItems(items, updatedSection: sectionIdentifier, map: {
			.init($0)
		})
	}
	
	@inlinable
	@discardableResult
	public func appendItems(_ items: [ItemIdentifier], toSection sectionIdentifier: SectionType) -> ReloadHandler {
		_appendItems(items, toSection: sectionIdentifier, map: {
			.init($0)
		})
	}
	@inlinable
	public func allItems(inSection identifier: SectionType) -> [ItemIdentifier]? {
		_allItems(inSection: identifier)
	}
	@inlinable
	public func sectionIdentifier(containingItem identifier: ItemIdentifier) -> SectionType? {
		_sectionIdentifier(containingItem: identifier)
	}
	#if swift(>=5.3)
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	public func visibleItems(inSection identifier: SectionType) -> [ItemIdentifier]? {
		_visibleItems(inSection: identifier, compactMap: nil)
	}
	
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	public func rootItems(inSection identifier: SectionType) -> [ItemIdentifier]? {
		_rootItems(inSection: identifier)
	}
	#endif
}
