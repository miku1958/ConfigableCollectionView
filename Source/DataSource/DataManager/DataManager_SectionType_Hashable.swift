//
//  DataManager_SectionType_Hashable.swift
//  ConfigableCollectionView
//
//  Created by 庄黛淳华 on 2020/7/26.
//

import Foundation

extension CollectionView.DataManager where SectionType: Hashable {
	@inlinable
	@discardableResult
	public func appendSections(_ identifiers: [SectionType]) -> ReloadHandler {
		_appendSections(new: identifiers.map {
			CollectionView.AnyHashable.package($0)
		}, to: Set(sections.map {
			$0.anySection
		}))
	}
	@inlinable
	@discardableResult
	public func insertSections(_ identifiers: [SectionType], beforeSection toIdentifier: SectionType) -> ReloadHandler {
		_insertSections(identifiers, toIdentifier: toIdentifier, indexOffset: 0)
	}
	
	@inlinable
	@discardableResult
	public func insertSections(_ identifiers: [SectionType], afterSection toIdentifier: SectionType) -> ReloadHandler {
		_insertSections(identifiers, toIdentifier: toIdentifier, indexOffset: 1)
	}
	@inlinable
	public func numberOfRootItems(inSection identifier: SectionType) -> Int {
		_numberOfRootItems(inSection: identifier)
	}
	@inlinable
	public func sectionIdentifiers() -> [SectionType] {
		_sectionIdentifiers()
	}
	@inlinable
	public func indexOfSection(_ identifier: SectionType) -> Int? {
		_indexOfSection(identifier)
	}
	
	@inlinable
	@discardableResult
	public func deleteSections(_ identifiers: [SectionType]) -> ReloadHandler {
		_deleteSections(identifiers)
	}
	@inlinable
	@discardableResult
	public func reverseRootItems(inSection identifier: SectionType) -> ReloadHandler {
		_reverseRootItems(inSection: identifier)
	}
	
	@inlinable
	@discardableResult
	public func moveSection(_ identifier: SectionType, beforeSection toSection: SectionType) -> ReloadHandler {
		_moveSection(identifier, toSection: toSection, indexOffset: 0)
	}
	@inlinable
	@discardableResult
	public func moveSection(_ identifier: SectionType, afterSection toSection: SectionType) -> ReloadHandler {
		_moveSection(identifier, toSection: toSection, indexOffset: 1)
	}
	
	@inlinable
	@discardableResult
	public func reloadSections(_ identifiers: [SectionType]) -> ReloadHandler {
		_reloadSections(identifiers)
	}
}
