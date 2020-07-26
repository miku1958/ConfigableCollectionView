//
//  DataManager_SectionIdentifier_AnyHashable.swift
//  ConfigableCollectionView
//
//  Created by 庄黛淳华 on 2020/7/26.
//

import Foundation

extension CollectionView.DataManager where SectionIdentifier == CollectionView.AnyHashable {
	@inlinable
	@discardableResult
	public func appendSections<Section>(_ identifiers: [Section]) -> ReloadHandler where Section: Hashable {
		_appendSections(new: identifiers.map {
			CollectionView.AnyHashable.package($0)
		}, to: Set(sections.map {
			$0.section()
		}))
	}
	
	@inlinable
	@discardableResult
	public func insertSections<Insert, Before>(_ identifiers: [Insert], beforeSection toIdentifier: Before) -> ReloadHandler where Insert: Hashable, Before: Hashable {
		_insertSections(identifiers, toIdentifier: toIdentifier, indexOffset: 0)
	}
	
	@inlinable
	@discardableResult
	public func insertSections<Insert, After>(_ identifiers: [Insert], afterSection toIdentifier: After) -> ReloadHandler where Insert: Hashable, After: Hashable {
		_insertSections(identifiers, toIdentifier: toIdentifier, indexOffset: 1)
	}
	
	@inlinable
	public func numberOfItems<Section>(inSection identifier: Section) -> Int where Section: Hashable {
		_numberOfItems(inSection: identifier)
	}
	@inlinable
	public func sectionIdentifiers<Section>() -> [Section] where Section: Hashable {
		_sectionIdentifiers()
	}
	
	@inlinable
	public func indexOfSection<Section>(_ identifier: Section) -> Int? where Section: Hashable {
		_indexOfSection(identifier)
	}
	
	@inlinable
	@discardableResult
	public func deleteSections<Section>(_ identifiers: [Section]) -> ReloadHandler where Section: Hashable {
		_deleteSections(identifiers)
	}
	
	@inlinable
	@discardableResult
	public func reverseRootItems<Section>(inSection identifier: Section) -> ReloadHandler where Section: Hashable {
		_reverseRootItems(inSection: identifier)
	}
	
	@inlinable
	@discardableResult
	public func moveSection<Moved, Before>(_ identifier: Moved, beforeSection toSection: Before) -> ReloadHandler where Moved: Hashable, Before: Hashable {
		_moveSection(identifier, toSection: toSection, indexOffset: 0)
	}
	@inlinable
	@discardableResult
	public func moveSection<Moved, After>(_ identifier: Moved, afterSection toSection: After) -> ReloadHandler where Moved: Hashable, After: Hashable {
		_moveSection(identifier, toSection: toSection, indexOffset: 1)
	}
	
	@inlinable
	@discardableResult
	public func reloadSections<Section>(_ identifiers: [Section]) -> ReloadHandler where Section: Hashable {
		_reloadSections(identifiers)
	}
}
