//
//  DataManager_SectionType_Hashable.swift
//  ConfigableCollectionView
//
//  Created by 庄黛淳华 on 2020/7/26.
//

import Foundation

extension CollectionView.DataManager where SectionType: Hashable {
	// 添加已有的section会crash
	// 'NSInternalInconsistencyException', reason: 'Section identifier count does not match data source count. This is most likely due to a hashing issue with the identifiers.'
	@inlinable
	@discardableResult
	public func appendSections(_ identifiers: [SectionType]) -> ReloadHandler {
		_appendSections(new: identifiers.map {
			CollectionView.AnyHashable.package($0)
		}, to: Set(sections.map {
			$0.anySection
		}))
	}
	// toIdentifier找不到会crash
	// 'NSInternalInconsistencyException', reason: 'Invalid parameter not satisfying: insertIndex != NSNotFound'
	
	// 如果identifiers已经存在会crash
	// 'NSInternalInconsistencyException', reason: 'Invalid update: destination for section operation [Modern_Collection_Views.OutlineViewController.Section.main] is in the inserted section list for update: <_UIDiffableDataSourceUpdate 0x600002df2c70 - action: INS; destinationIdentifier:Modern_Collection_Views.OutlineViewController.Section.main; destIsSection: 0; identifiers: [Modern_Collection_Views.OutlineViewController.Section.main]>'
	
	// 如果identifiers里有重复
	// 'NSInternalInconsistencyException', reason: 'Fatal: supplied section identifiers are not unique.'
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
	public func numberOfItems(inSection identifier: SectionType) -> Int {
		_numberOfItems(inSection: identifier)
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
	// beforeSection找不到
	// 'NSInternalInconsistencyException', reason: 'Invalid parameter not satisfying: toSection != NSNotFound'
	
	// identifier 找不到
	// 'NSInternalInconsistencyException', reason: 'Invalid parameter not satisfying: fromSection != NSNotFound'
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
	
	// NSDiffableDataSourceSectionSnapshot 没有 reload
	// NSDiffableDataSourceSnapshot 的 reload 作用是: UICollectionViewDiffableDataSource 每次 apply 都会对比两次的 snapshot, 除了 hashValue 有变化的之外都不会 reload, 这个时候需要调用 NSDiffableDataSourceSnapshot 的 reload 标记 section/item 为强刷新, 否则即使创建一个新的 snapshot 也没法自动触发 reload
	
	// 如果 reload 的 identifiers 找不到会crash
	// 'NSInternalInconsistencyException', reason: 'Invalid section identifier for reload specified: Modern_Collection_Views.OutlineViewController.Section.next'
	@inlinable
	@discardableResult
	public func reloadSections(_ identifiers: [SectionType]) -> ReloadHandler {
		_reloadSections(identifiers)
	}
}
