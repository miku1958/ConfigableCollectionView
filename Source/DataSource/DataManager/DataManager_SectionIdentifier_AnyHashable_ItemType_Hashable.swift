//
//  DataManager_SectionIdentifier_AnyHashable_ItemType_Hashable.swift
//  ConfigableCollectionView
//
//  Created by 庄黛淳华 on 2020/7/26.
//

import Foundation

extension CollectionView.DataManager where ItemType: Hashable, SectionIdentifier == CollectionView.AnyHashable {
	@inlinable
	@discardableResult
	public func applySections<Section>(_ sections: [(section: Section, items: [ItemIdentifier])]) -> ReloadHandler where Section: Hashable {
		_applySections(sections, map: {
			.init($0)
		})
	}
	@inlinable
	@discardableResult
	public func applyItems<Section>(_ items: [ItemIdentifier], updatedSection sectionIdentifier: Section) -> ReloadHandler where Section: Hashable {
		_applyItems(items, updatedSection: sectionIdentifier, map: {
			.init($0)
		})
	}
	
	// NSDiffableDataSourceSnapshot 为空会crash
	// 'NSInternalInconsistencyException', reason: 'There are currently no sections in the data source. Please add a section first.'
	
	// 如果toSction找不到会crash
	// 'NSInternalInconsistencyException', reason: 'Invalid parameter not satisfying: section != NSNotFound'
	@inlinable
	@discardableResult
	public func appendItems<Section>(_ items: [ItemIdentifier], toSection sectionIdentifier: Section) -> ReloadHandler where Section: Hashable {
		_appendItems(items, toSection: sectionIdentifier, map: {
			.init($0 )
		})
	}
	@inlinable
	public func allItems<Section>(inSection identifier: Section) -> [ItemIdentifier]? where Section: Hashable {
		_allItems(inSection: identifier)
	}
	@inlinable
	public func sectionIdentifier<Section>(containingItem identifier: ItemIdentifier) -> Section? where Section: Hashable {
		_sectionIdentifier(containingItem: identifier)
	}
	#if swift(>=5.3)
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	public func visibleItems<Section>(inSection identifier: Section) -> [ItemIdentifier]? where Section : Hashable {
		_visibleItems(inSection: identifier, compactMap: nil)
	}
	
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	public func rootItems<Section>(inSection identifier: Section) -> [ItemIdentifier]? where Section : Hashable {
		_rootItems(inSection: identifier)
	}
	#endif
}
