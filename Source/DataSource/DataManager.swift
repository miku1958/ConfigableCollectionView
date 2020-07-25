//
//  DataManager.swift
//  ConfigableCollectionView
//
//  Created by 庄黛淳华 on 2020/7/8.
//

import UIKit
// NSDiffableDataSourceSectionSnapshot 和 NSDiffableDataSourceSnapshot 可以混用, 后面设置的会覆盖前面的内容, 但是只能先设置 NSDiffableDataSourceSnapshot 再设置 NSDiffableDataSourceSectionSnapshot, 反过来会被完全覆盖

// UICollectionViewDiffableDataSource不管apply的是NSDiffableDataSourceSectionSnapshot 还是 NSDiffableDataSourceSnapshot, section/item都是全局hash的, 跨section的item也是唯一的
// 所以moveItem和insert是唯一的
// append的话, 会先删掉先添加的
// 虽然要求Hashable. 但是如果用的数据是类, 则会用类对象地址做hash, 不会用Hashable

// 如果 NSDiffableDataSourceSectionSnapshot 添加添加多个一样的会报错: Supplied identifiers are not unique.
// 而 NSDiffableDataSourceSnapshot 添加两个一样的会过滤
// UICollectionViewDiffableDataSource 添加两个 NSDiffableDataSourceSectionSnapshot 也会自我过滤

//添加 NSDiffableDataSourceSectionSnapshot 后拿 NSDiffableDataSourceSnapshot 相当于 visibleItem 的 NSDiffableDataSourceSnapshot, 但是里面的数据还是以 NSDiffableDataSourceSectionSnapshot 为准的

// TODO(pass):    assert改成throw, 但这样线上也不能用了
// ☑️TODO:    整理items: allItems, rootItems, visibleItems, 并且三种都有 全部/inSectionIdentifier/atSectionIndex 三种情况, 并且得分DataType 一共18个方法
// snapshot(for section: SectionIdentifierType) 找不到会返回一个空的 NSDiffableDataSourceSectionSnapshot
// ☑️TODO:    使用diffDataSource前得强刷新, 有些情况得强行prepare
// ☑️TODO:    @inline(__always)改成@inlinable, 把不能inline的东西加上@usableFromInline

// apply是覆盖, 当提供的sectionIdentifier找不到时则添加到末尾, 除此之外会覆盖所有数据
// append是添加, 所以需要sectionIdentifier
protocol CollectionViewDataManager {
	var lastIndexPath: IndexPath? { get }
	func element(for indexPath: IndexPath) -> Any
}

extension CollectionView {
	public class DataManager<SectionIdentifier, ItemIdentifier> where SectionIdentifier: Hashable, ItemIdentifier: Hashable {
		@usableFromInline
		weak var collectionView: CollectionView?
		@usableFromInline
		var sections = [SectionData<ItemIdentifier>]()
		@usableFromInline
		var useDiffDataSource = false
		var _diffDataSource: Any?
		
		@available(iOS 13.0, *)
		public typealias DiffDataSource = UICollectionViewDiffableDataSource<SectionIdentifier, ItemIdentifier>
		
		@available(iOS 13.0, *)
		@usableFromInline
		@inline(__always)
		var diffDataSource: DiffDataSource? {
			get {
				_diffDataSource as? DiffDataSource
			} set {
				_diffDataSource = newValue
			}
		}
		init(collectionView: CollectionView) {
			self.collectionView = collectionView
			registerReloadHandler()
		}
	}
}
extension CollectionView.DataManager {
	@inline(__always)
	func registerReloadHandler() {
		collectionView?.reloadHandlers.first?._reload = { [weak collectionView] animatingDifferences, completion in
			guard let collectionView = collectionView else {
				return
			}
			
			let dataManager = collectionView._dataManager as! Self
			
			if #available(iOS 14.0, *), dataManager.useDiffDataSource {
				var _completion = Optional(completion.call)
				for section in dataManager.sections {
					var snapshot = NSDiffableDataSourceSectionSnapshot<ItemIdentifier>()
					func addItems(_ items: [CollectionView.ItemData<ItemIdentifier>], to parent: CollectionView.ItemData<ItemIdentifier>?) {
						snapshot.append(items.map({
							$0.base
						}), to: parent?.base)
						for item in items where !item.subItems.isEmpty {
							addItems(item.subItems, to: item)
						}
					}
					
					addItems(section.items, to: nil)

					dataManager.diffDataSource?.apply(snapshot, to: section.section(), animatingDifferences: animatingDifferences, completion: _completion)
					_completion = nil
				}
			} else if #available(iOS 13.0, *) {
				var snapshot = NSDiffableDataSourceSnapshot<SectionIdentifier, ItemIdentifier>()
				
				snapshot.appendSections(dataManager.sections.map({
					$0.section()
				}))
				for section in dataManager.sections {
					snapshot.appendItems(section.items.map({
						$0.base
					}), toSection: section.section())
				}
				dataManager.diffDataSource?.apply(snapshot, animatingDifferences: animatingDifferences, completion: completion.call)
			} else {
				UIView.animate(withDuration: 0, animations: {
					collectionView.reloadData()
				}, completion: { _ in
					completion.call()
				})
			}
		}
	}
}
extension CollectionView.DataManager {
	@inlinable
	public var lastIndexPath: IndexPath? {
		let sectionIndex = numberOfSections-1
		guard sectionIndex >= 0 else {
			return nil
		}
		let itemCount = numberOfItems(atSectionIndex: sectionIndex)
		guard itemCount > 0 else {
			return nil
		}
		return IndexPath(item: itemCount-1, section: sectionIndex)
	}
	@inlinable
	@inline(__always)
	func element(for indexPath: IndexPath) -> Any {
		var item: Any?
		if #available(iOS 13.0, *), let diffDataSource = diffDataSource {
			item = diffDataSource.itemIdentifier(for: indexPath)
		}
		if item == nil {
			item = sections[indexPath.section].items[indexPath.item].base
		}
		if let item = item as? CollectionView.AnyHashable {
			return item.base
		} else {
			return item!
		}
	}
	@usableFromInline
	@inline(__always)
	func prepareDatasource() -> UICollectionViewDataSource? {
		guard let collectionView = collectionView else {
			return nil
		}
		if #available(iOS 13.0, *) {
			if _diffDataSource == nil {
				let cellProvider: (UICollectionView, IndexPath, ItemIdentifier) -> UICollectionViewCell?
				if ItemIdentifier.self == CollectionView.AnyHashable.self {
					cellProvider = { [weak collectionView] (_, indexPath, data) in
						collectionView?.cell(at: indexPath, item: (data as! CollectionView.AnyHashable).base)
					}
				} else {
					cellProvider = { [weak collectionView] (_, indexPath, data) in
						collectionView?.cell(at: indexPath, item: data)
					}
				}
				diffDataSource = .init(collectionView: collectionView, cellProvider: cellProvider)
			}
			return diffDataSource
		} else {
			let dataSource = CollectionView.DataSourceBase<SectionIdentifier, ItemIdentifier>(collectionView: collectionView)
			return dataSource
		}
	}
}
// visibleItems是展开的item合集
extension CollectionView.DataManager: CollectionViewDataManager {
	@usableFromInline
	@inline(__always)
	var reloadHandler: ReloadHandler {
		collectionView?.reloadHandlers.first ?? .init()
	}
	
	@inlinable
	public var isEmpty: Bool {
		sections.isEmpty
	}
	
	
	@inlinable
	public var numberOfSections: Int {
		sections.count
	}
	
	@inlinable
	public var numberOfItems: Int {
		sections.reduce(0) {
			$0 + $1.items.count
		}
	}
	
	@inlinable
	public func numberOfItems(atSectionIndex index: Int) -> Int {
		if index < sections.count {
			return sections[index].items.count
		} else {
			return 0
		}
	}
	
	@inlinable
	@discardableResult
	public func deleteAllItems() -> ReloadHandler {
		sections.removeAll()
		return reloadHandler.commit()
	}
	
	@inlinable
	@discardableResult
	public func reverseSections() -> ReloadHandler {
		sections.reverse()
		return reloadHandler.commit()
	}
	
	@inlinable
	@discardableResult
	public func reverseRootItems(atSectionIndex index: Int) -> ReloadHandler {
		if index < sections.count {
			sections[index].items.reverse()
			return reloadHandler.commit()
		}
		return reloadHandler
	}
}

// MARK: - SectionIdentifier == CollectionView.AnyHashable
extension CollectionView.DataManager where SectionIdentifier == CollectionView.AnyHashable {
	// 添加已有的section会crash
	// 'NSInternalInconsistencyException', reason: 'Section identifier count does not match data source count. This is most likely due to a hashing issue with the identifiers.'
	@inlinable
	@discardableResult
	public func appendSections<Section>(_ identifiers: [Section]) -> ReloadHandler where Section: Hashable {
		
		var set: Set<CollectionView.AnyHashable> = Set(sections.map { $0.section() })
		
		sections.append(contentsOf: identifiers.map {
			CollectionView.AnyHashable.package($0)
		}.filter {
			set.insert($0).inserted
		}.map({
			.init(anySectionIdentifier:$0)
		}))
		
		return reloadHandler.commit()
	}
	// toIdentifier找不到会crash
	// 'NSInternalInconsistencyException', reason: 'Invalid parameter not satisfying: insertIndex != NSNotFound'
	
	// 如果identifiers已经存在会crash
	// 'NSInternalInconsistencyException', reason: 'Invalid update: destination for section operation [Modern_Collection_Views.OutlineViewController.Section.main] is in the inserted section list for update: <_UIDiffableDataSourceUpdate 0x600002df2c70 - action: INS; destinationIdentifier:Modern_Collection_Views.OutlineViewController.Section.main; destIsSection: 0; identifiers: [Modern_Collection_Views.OutlineViewController.Section.main]>'
	
	// 如果identifiers里有重复
	// 'NSInternalInconsistencyException', reason: 'Fatal: supplied section identifiers are not unique.'
	@usableFromInline
	func insertSections<Insert, Before>(_ identifiers: [Insert], toIdentifier: Before) -> ([CollectionView.AnyHashable], index: Int)? where Insert: Hashable, Before: Hashable {
		let itemsUnique = identifiers.unique().array.map({
			CollectionView.AnyHashable.package($0)
		})
		assert(identifiers.count == itemsUnique.count, "Fatal: supplied section identifiers are not unique.")
		guard let index = sections.firstIndex(where: {
			$0.anySection == toIdentifier
		}) else {
			assertionFailure("Invalid parameter not satisfying: insertIndex != NSNotFound")
			return nil
		}
		var existSectionSet = Set(sections.map {
			$0.anySection
		})
		let insertIdentifierUnique = itemsUnique.filter {
			existSectionSet.insert($0).inserted
		}
		assert(insertIdentifierUnique.count == itemsUnique.count, "Invalid update: destination for section operation \(itemsUnique.filter { !itemsUnique.contains($0) }) is in the inserted section list for update")
		return (itemsUnique, index)
	}
	@inlinable
	@discardableResult
	public func insertSections<Insert, Before>(_ identifiers: [Insert], beforeSection toIdentifier: Before) -> ReloadHandler where Insert: Hashable, Before: Hashable {
		guard let result = insertSections(identifiers, toIdentifier: toIdentifier) else {
			return reloadHandler
		}
		sections.insert(contentsOf: result.0.map({
			.init(anySectionIdentifier: $0)
		}), at: result.index)
		return reloadHandler.commit()
	}
	
	@inlinable
	@discardableResult
	public func insertSections<Insert, After>(_ identifiers: [Insert], afterSection toIdentifier: After) -> ReloadHandler where Insert: Hashable, After: Hashable {
		guard let result = insertSections(identifiers, toIdentifier: toIdentifier) else {
			return reloadHandler
		}
		sections.insert(contentsOf: result.0.map({
			.init(anySectionIdentifier: $0)
		}), at: result.index+1)
		return reloadHandler.commit()
	}
	@inlinable
	public func numberOfItems<Section>(inSection identifier: Section) -> Int where Section: Hashable {
		sections.first {
			$0.anySection == identifier
		}?.items.count ?? 0
	}
	@inlinable
	public func sectionIdentifiers<Section>() -> [Section] where Section: Hashable {
		sections.compactMap {
			$0.trySection()
		}
	}
	@inlinable
	public func indexOfSection<Section>(_ identifier: Section) -> Int? where Section: Hashable {
		sections.firstIndex {
			$0.anySection == identifier
		}
	}
	
	@inlinable
	@discardableResult
	public func deleteSections<Section>(_ identifiers: [Section]) -> ReloadHandler where Section: Hashable {
		sections.removeAll { item in
			identifiers.contains {
				item.anySection == $0
			}
		}
		
		return reloadHandler.commit()
	}
	@inlinable
	@discardableResult
	public func reverseRootItems<Section>(inSection identifier: Section) -> ReloadHandler where Section: Hashable {
		if let index = sections.firstIndex(where: {
			$0.anySection == identifier
		}) {
			sections[index].items.reverse()
		}
		
		return reloadHandler.commit()
	}
	// beforeSection找不到
	// 'NSInternalInconsistencyException', reason: 'Invalid parameter not satisfying: toSection != NSNotFound'
	
	// identifier 找不到
	// 'NSInternalInconsistencyException', reason: 'Invalid parameter not satisfying: fromSection != NSNotFound'
	@usableFromInline
	func moveSection<Moved, Before>(_ identifier: Moved, toSection: Before) -> (Int, Int)? where Moved: Hashable, Before: Hashable {
		guard let movedIndex = sections.firstIndex(where: {
			$0.anySection == identifier
		}) else {
			assertionFailure("Invalid parameter not satisfying: fromSection != NSNotFound")
			return nil
		}
		guard let index = sections.firstIndex(where: {
			$0.anySection == toSection
		}) else {
			assertionFailure("Invalid parameter not satisfying: toSection != NSNotFound")
			return nil
		}
		return (movedIndex, index)
	}
	@inlinable
	@discardableResult
	public func moveSection<Moved, Before>(_ identifier: Moved, beforeSection toSection: Before) -> ReloadHandler where Moved: Hashable, Before: Hashable {
		guard let result = moveSection(identifier, toSection: toSection) else {
			return reloadHandler
		}
		sections.insert(sections.remove(at: result.0), at: result.1)
		return reloadHandler.commit()
	}
	@inlinable
	@discardableResult
	public func moveSection<Moved, After>(_ identifier: Moved, afterSection toSection: After) -> ReloadHandler where Moved: Hashable, After: Hashable {
		
		guard let result = moveSection(identifier, toSection: toSection) else {
			return reloadHandler
		}
		sections.insert(sections.remove(at: result.0), at: result.1+1)
		return reloadHandler.commit()
	}
	
	// NSDiffableDataSourceSectionSnapshot 没有 reload
	// NSDiffableDataSourceSnapshot 的 reload 作用是: UICollectionViewDiffableDataSource 每次 apply 都会对比两次的 snapshot, 除了 hashValue 有变化的之外都不会 reload, 这个时候需要调用 NSDiffableDataSourceSnapshot 的 reload 标记 section/item 为强刷新, 否则即使创建一个新的 snapshot 也没法自动触发 reload
	
	// 如果 reload 的 identifiers 找不到会crash
	// 'NSInternalInconsistencyException', reason: 'Invalid section identifier for reload specified: Modern_Collection_Views.OutlineViewController.Section.next'
	@inlinable
	@discardableResult
	public func reloadSections<Section>(_ identifiers: [Section]) -> ReloadHandler where Section: Hashable {
		func _filter() -> (indexs: [Int], ids: [CollectionView.AnyHashable]) {
			
			var identifiersSet = Set(identifiers.map({
				CollectionView.AnyHashable.package($0)
			}))
			
			var indexs = [Int]()
			var ids = [CollectionView.AnyHashable]()
			for (section, element) in sections.enumerated() {
				if identifiersSet.insert(element.section()).inserted {
					indexs.append(section)
					ids.append(element.section())
				}
			}
			return (indexs, ids)
		}
		if #available(iOS 13.0, *) {
			guard let diff = diffDataSource else {
				return reloadHandler
			}
			let result = _filter()
			let reload = ReloadHandler()
			collectionView?.reloadHandlers.append(reload)
			reload._reload = { [weak collectionView] animatingDifferences, completion in
				var snap = diff.snapshot()
				snap.reloadSections(result.ids)
				diff.apply(snap, animatingDifferences: animatingDifferences, completion: completion.call)
				collectionView?.reloadHandlers.removeAll {
					ObjectIdentifier($0) == ObjectIdentifier(reload)
				}
			}
			return reload
		} else {
			guard collectionView?.dataSource != nil else {
				return reloadHandler
			}
			
			let result = _filter()
			let reload = ReloadHandler()
			collectionView?.reloadHandlers.append(reload)
			reload._reload = { [weak collectionView] animatingDifferences, completion in
				UIView.animate(withDuration: 0, animations: {
					collectionView?.reloadSections(IndexSet(result.indexs))
				}, completion: { _ in
					completion.call()
					collectionView?.reloadHandlers.removeAll {
						ObjectIdentifier($0) == ObjectIdentifier(reload)
					}
				})
			}
			return reload
		}
	}
	
	@available(iOS 14.0, *)
	@inlinable
	public func visibleItems<Section>(in sectionIdentifier: Section) -> [ItemIdentifier] where Section: Hashable {
		guard let index = sections.first(where: {
			$0.anySection == sectionIdentifier
		}) else {
			return []
		}
		guard let diff = diffDataSource else {
			return index.items.map {
				$0.base
			}
		}
		return diff.snapshot(for: .package(sectionIdentifier)).visibleItems
	}
}
// MARK: - SectionType: Hashable
extension CollectionView.DataManager where SectionType: Hashable {
	// 添加已有的section会crash
	// 'NSInternalInconsistencyException', reason: 'Section identifier count does not match data source count. This is most likely due to a hashing issue with the identifiers.'
	@inlinable
	@discardableResult
	public func appendSections(_ identifiers: [SectionType]) -> ReloadHandler {
		
		var set = Set(sections.map {
			$0.anySection
		})
		
		sections.append(contentsOf: identifiers.map {
			CollectionView.AnyHashable.package($0)
		}.filter {
			set.insert($0).inserted
		}.map({
			.init(anySectionIdentifier:$0)
		}))
		
		return reloadHandler.commit()
	}
	// toIdentifier找不到会crash
	// 'NSInternalInconsistencyException', reason: 'Invalid parameter not satisfying: insertIndex != NSNotFound'
	
	// 如果identifiers已经存在会crash
	// 'NSInternalInconsistencyException', reason: 'Invalid update: destination for section operation [Modern_Collection_Views.OutlineViewController.Section.main] is in the inserted section list for update: <_UIDiffableDataSourceUpdate 0x600002df2c70 - action: INS; destinationIdentifier:Modern_Collection_Views.OutlineViewController.Section.main; destIsSection: 0; identifiers: [Modern_Collection_Views.OutlineViewController.Section.main]>'
	
	// 如果identifiers里有重复
	// 'NSInternalInconsistencyException', reason: 'Fatal: supplied section identifiers are not unique.'
	@usableFromInline
	func insertSections(_ identifiers: [SectionType], toIdentifier: SectionType) -> ([CollectionView.AnyHashable], index: Int)? {
		let itemsUnique = identifiers.unique().array.map({
			CollectionView.AnyHashable.package($0)
		})
		assert(identifiers.count == itemsUnique.count, "Fatal: supplied section identifiers are not unique.")
		guard let index = sections.firstIndex(where: {
			$0.anySection == toIdentifier
		}) else {
			assertionFailure("Invalid parameter not satisfying: insertIndex != NSNotFound")
			return nil
		}
		var existSectionSet = Set(sections.map {
			$0.anySection
		})
		let insertIdentifierUnique = itemsUnique.filter {
			existSectionSet.insert($0).inserted
		}
		assert(insertIdentifierUnique.count == itemsUnique.count, "Invalid update: destination for section operation \(itemsUnique.filter { !itemsUnique.contains($0) }) is in the inserted section list for update")
		return (itemsUnique, index)
	}
	@inlinable
	@discardableResult
	public func insertSections(_ identifiers: [SectionType], beforeSection toIdentifier: SectionType) -> ReloadHandler {
		guard let result = insertSections(identifiers, toIdentifier: toIdentifier) else {
			return reloadHandler
		}
		sections.insert(contentsOf: result.0.map({
			.init(anySectionIdentifier: $0)
		}), at: result.index)
		return reloadHandler.commit()
	}
	
	@inlinable
	@discardableResult
	public func insertSections(_ identifiers: [SectionType], afterSection toIdentifier: SectionType) -> ReloadHandler {
		guard let result = insertSections(identifiers, toIdentifier: toIdentifier) else {
			return reloadHandler
		}
		sections.insert(contentsOf: result.0.map({
			.init(anySectionIdentifier: $0)
		}), at: result.index+1)
		return reloadHandler.commit()
	}
	@inlinable
	public func numberOfItems(inSection identifier: SectionType) -> Int {
		sections.first {
			$0.anySection == identifier
		}?.items.count ?? 0
	}
	@inlinable
	public func sectionIdentifiers() -> [SectionType] {
		sections.compactMap {
			$0.trySection()
		}
	}
	@inlinable
	public func indexOfSection(_ identifier: SectionType) -> Int? {
		sections.firstIndex {
			$0.anySection == identifier
		}
	}
	
	@inlinable
	@discardableResult
	public func deleteSections(_ identifiers: [SectionType]) -> ReloadHandler {
		sections.removeAll { item in
			identifiers.contains {
				item.anySection == $0
			}
		}
		
		return reloadHandler.commit()
	}
	@inlinable
	@discardableResult
	public func reverseRootItems(inSection identifier: SectionType) -> ReloadHandler {
		if let index = sections.firstIndex(where: {
			$0.anySection == identifier
		}) {
			sections[index].items.reverse()
		}
		
		return reloadHandler.commit()
	}
	// beforeSection找不到
	// 'NSInternalInconsistencyException', reason: 'Invalid parameter not satisfying: toSection != NSNotFound'
	
	// identifier 找不到
	// 'NSInternalInconsistencyException', reason: 'Invalid parameter not satisfying: fromSection != NSNotFound'
	@usableFromInline
	func moveSection(_ identifier: SectionType, toSection: SectionType) -> (Int, Int)? {
		guard let movedIndex = sections.firstIndex(where: {
			$0.anySection == identifier
		}) else {
			assertionFailure("Invalid parameter not satisfying: fromSection != NSNotFound")
			return nil
		}
		guard let index = sections.firstIndex(where: {
			$0.anySection == toSection
		}) else {
			assertionFailure("Invalid parameter not satisfying: toSection != NSNotFound")
			return nil
		}
		return (movedIndex, index)
	}
	@inlinable
	@discardableResult
	public func moveSection(_ identifier: SectionType, beforeSection toSection: SectionType) -> ReloadHandler {
		guard let result = moveSection(identifier, toSection: toSection) else {
			return reloadHandler
		}
		sections.insert(sections.remove(at: result.0), at: result.1)
		return reloadHandler.commit()
	}
	@inlinable
	@discardableResult
	public func moveSection(_ identifier: SectionType, afterSection toSection: SectionType) -> ReloadHandler {
		
		guard let result = moveSection(identifier, toSection: toSection) else {
			return reloadHandler
		}
		sections.insert(sections.remove(at: result.0), at: result.1+1)
		return reloadHandler.commit()
	}
	
	// NSDiffableDataSourceSectionSnapshot 没有 reload
	// NSDiffableDataSourceSnapshot 的 reload 作用是: UICollectionViewDiffableDataSource 每次 apply 都会对比两次的 snapshot, 除了 hashValue 有变化的之外都不会 reload, 这个时候需要调用 NSDiffableDataSourceSnapshot 的 reload 标记 section/item 为强刷新, 否则即使创建一个新的 snapshot 也没法自动触发 reload
	
	// 如果 reload 的 identifiers 找不到会crash
	// 'NSInternalInconsistencyException', reason: 'Invalid section identifier for reload specified: Modern_Collection_Views.OutlineViewController.Section.next'
	@inlinable
	@discardableResult
	public func reloadSections(_ identifiers: [SectionType]) -> ReloadHandler {
		func _filter() -> (indexs: [Int], ids: [SectionIdentifier]) {
			
			var identifiersSet = Set(identifiers.map({
				CollectionView.AnyHashable.package($0)
			}))
			
			var indexs = [Int]()
			var ids = [SectionIdentifier]()
			for (section, element) in sections.enumerated() {
				if identifiersSet.insert(element.section()).inserted {
					indexs.append(section)
					ids.append(element.section())
				}
			}
			return (indexs, ids)
		}
		if #available(iOS 13.0, *) {
			guard let diff = diffDataSource else {
				return reloadHandler
			}
			let result = _filter()
			let reload = ReloadHandler()
			collectionView?.reloadHandlers.append(reload)
			reload._reload = { [weak collectionView] animatingDifferences, completion in
				var snap = diff.snapshot()
				snap.reloadSections(result.ids)
				diff.apply(snap, animatingDifferences: animatingDifferences, completion: completion.call)
				collectionView?.reloadHandlers.removeAll {
					ObjectIdentifier($0) == ObjectIdentifier(reload)
				}
			}
			return reload
		} else {
			guard collectionView?.dataSource != nil else {
				return reloadHandler
			}
			
			let result = _filter()
			let reload = ReloadHandler()
			collectionView?.reloadHandlers.append(reload)
			reload._reload = { [weak collectionView] animatingDifferences, completion in
				UIView.animate(withDuration: 0, animations: {
					collectionView?.reloadSections(IndexSet(result.indexs))
				}, completion: { _ in
					completion.call()
					collectionView?.reloadHandlers.removeAll {
						ObjectIdentifier($0) == ObjectIdentifier(reload)
					}
				})
			}
			return reload
		}
	}
	
	@available(iOS 14.0, *)
	@inlinable
	public func visibleItems(in sectionIdentifier: SectionType) -> [ItemIdentifier] {
		guard let section = sections.first(where: {
			$0.anySection == sectionIdentifier
		}) else {
			return []
		}
		guard let diff = diffDataSource else {
			return section.items.map {
				$0.base
			}
		}
		return diff.snapshot(for: section.section()).visibleItems
	}
}
// MARK: - 13, SectionType: Hashable
@available(iOS 13.0, *)
extension CollectionView.DataManager where SectionType: Hashable {
	public var diffableDataSource: DiffDataSource {
		diffDataSource!
	}
}

// MARK: - ItemType: Hashable
extension CollectionView.DataManager where ItemType: Hashable {
	@usableFromInline
	func filterAddingItem(set: Set<ItemIdentifier>) {
		var set = set
		var sectionIndex = sections.count-1
		var itemIndex = 0
		while sectionIndex >= 0 {
			itemIndex = sections[sectionIndex].items.count-1
			while itemIndex >= 0  {
				if !set.insert(sections[sectionIndex].items[itemIndex].base).inserted {
					sections[sectionIndex].items.remove(at: itemIndex)
					return
				} else {
					itemIndex -= 1
				}
			}
			sectionIndex -= 1
		}
	}
	
	@inlinable
	@discardableResult
	public func apply(_ items: [ItemIdentifier], atSection index: Int) -> ReloadHandler {
		guard index < sections.count else {
			return reloadHandler
		}
		sections[index].items = items.map {
			.init($0)
		}
		
		return reloadHandler.commit()
	}
	
	@inlinable
	public func itemIdentifier(for indexPath: IndexPath) -> ItemIdentifier? {
		element(for: indexPath) as? ItemIdentifier
	}
	
	// NSDiffableDataSourceSectionSnapshot.index(of:) 拿到的是 allItems 的 index
	@inlinable
	public func indexPath(for itemIdentifier: ItemIdentifier) -> IndexPath? {
		if #available(iOS 13.0, *), let diff = diffDataSource {
			collectionView?.reloadImmediately()
			return diff.indexPath(for: itemIdentifier)
		} else {
			for pair in sections.enumerated() {
				if let itemIndex = pair.element.items.firstIndex(where: {
					$0.base == itemIdentifier
				}) {
					return IndexPath(item: itemIndex, section: pair.offset)
				}
			}
		}
		
		return nil
	}
	
	@inlinable
	@discardableResult
	public func appendItems(_ items: [ItemIdentifier]) -> ReloadHandler {
		guard !sections.isEmpty else {
			assertionFailure("There are currently no sections in the data source. Please add a section first.")
			return reloadHandler
		}
		
		let itemUnique = items.unique()
		filterAddingItem(set: itemUnique.set)
		
		sections[sections.count-1].items.append(contentsOf: itemUnique.array.map {
			.init($0)
		})
		return reloadHandler.commit()
	}
	// 找不到 beforeIdentifier 的话会crash
	// 'NSInternalInconsistencyException', reason: 'Invalid parameter not satisfying: section != NSNotFound'
	@inlinable
	@inline(__always)
	func insertItems(identifier: ItemIdentifier) -> (section: Int, item: Int)? {
		var sectionIndex = 0
		var itemIndex = 0
		while sectionIndex < sections.count {
			itemIndex = 0
			while itemIndex < sections[sectionIndex].items.count {
				if sections[sectionIndex].items[itemIndex].base == identifier {
					return (sectionIndex, itemIndex)
				}
				itemIndex += 1
			}
			sectionIndex += 1
		}
		
		assertionFailure("Invalid parameter not satisfying: section != NSNotFound")
		return nil
	}
	@inlinable
	@discardableResult
	public func insertItems(_ identifiers: [ItemIdentifier], beforeItem beforeIdentifier: ItemIdentifier) -> ReloadHandler {
		guard let result = insertItems(identifier: beforeIdentifier) else {
			return reloadHandler
		}
		
		let itemsUnique = identifiers.unique()
		filterAddingItem(set: itemsUnique.set)
		
		sections[result.section].items.insert(contentsOf: itemsUnique.array.map {
			.init($0)
		}, at: result.item)
		
		return reloadHandler.commit()
	}
	
	@inlinable
	@discardableResult
	public func insertItems(_ identifiers: [ItemIdentifier], afterItem afterIdentifier: ItemIdentifier) -> ReloadHandler {
		guard let result = insertItems(identifier: afterIdentifier) else {
			return reloadHandler
		}
		
		let itemsUnique = identifiers.unique()
		filterAddingItem(set: itemsUnique.set)
		
		sections[result.section].items.insert(contentsOf: itemsUnique.array.map {
			.init($0)
		}, at: result.item + 1)
		
		return reloadHandler.commit()
	}
	
	@inlinable
	public func allItems() -> [ItemIdentifier] {
		sections.flatMap {
			$0.items.flatMap {
				$0.allItems
			}
		}
	}
	
	@inlinable
	public func allItems(atSection index: Int) -> [ItemIdentifier]? {
		if index < sections.count {
			return sections[index].items.flatMap {
				$0.allItems
			}
		}
		return nil
	}
	
	@inlinable
	@discardableResult
	public func deleteItems(_ identifiers: [ItemIdentifier]) -> ReloadHandler {
		for identifier in identifiers {
			var section = 0
			while section < sections.count {
				var index = sections[section].items.count-1
				while section > 0 {
					let item = sections[section].items[index]
					if item.base == identifier {
						sections[section].items.remove(at: index)
					} else {
						item.removeAllSubItems(identifier)
					}
					index -= 1
				}
				section += 1
			}
		}
		
		return reloadHandler.commit()
	}
	
	// 同一个 NSDiffableDataSourceSnapshot 不同 section 是不会存在相同的 item 的
	// 如果 identifier 找不到会crash
	// 'NSInternalInconsistencyException', reason: 'Invalid parameter not satisfying: fromIndex != NSNotFound'
	
	// 如果toIdentifier找不到会crash
	// 'NSInternalInconsistencyException', reason: 'Invalid parameter not satisfying: toIndex != NSNotFound'
	@inlinable
	@inline(__always)
	func moveItem(_ identifier: ItemIdentifier, toIdentifier: ItemIdentifier) -> (from: (section: Int, item: Int), to: (section: Int, item: Int))? {
		var sectionIndex = 0
		var itemIndex = 0
		var from: (section: Int, item: Int)?
		var to: (section: Int, item: Int)?
		
		while sectionIndex < sections.count {
			itemIndex = 0
			while itemIndex < sections[sectionIndex].items.count {
				let current = sections[sectionIndex].items[itemIndex].base
				if current == identifier {
					from = (sectionIndex, itemIndex)
				} else if current == toIdentifier {
					to = (sectionIndex, itemIndex)
				}
				if let from = from, let to = to {
					return (from, to)
				}
				itemIndex += 1
			}
			sectionIndex += 1
		}
		assert(from != nil, "Invalid parameter not satisfying: fromIndex != NSNotFound")
		assert(to != nil, "Invalid parameter not satisfying: toIndex != NSNotFound")
		return nil
	}
	@inlinable
	@discardableResult
	public func moveItem(_ identifier: ItemIdentifier, beforeItem beforeIdentifier: ItemIdentifier) -> ReloadHandler {
		guard let (from, to) = moveItem(identifier, toIdentifier: beforeIdentifier) else {
			return reloadHandler
		}
		
		sections[to.section].items.insert(sections[from.section].items.remove(at: from.item), at: to.item)
		return reloadHandler.commit()
	}
	
	@inlinable
	@discardableResult
	public func moveItem(_ identifier: ItemIdentifier, afterItem afterIdentifier: ItemIdentifier) -> ReloadHandler {
		guard let (from, to) = moveItem(identifier, toIdentifier: afterIdentifier) else {
			return reloadHandler
		}
		
		sections[to.section].items.insert(sections[from.section].items.remove(at: from.item), at: to.item+1)
		return reloadHandler.commit()
	}
	
	@inlinable
	@discardableResult
	public func reloadItems(_ identifiers: [ItemIdentifier]) -> ReloadHandler {
		func _filter() -> (indexPaths: [IndexPath], ids: [ItemIdentifier]) {
			var identifiersSet = Set(identifiers)
			
			var indexPaths = [IndexPath]()
			var ids = [ItemIdentifier]()
			for (sectionIndex, element) in sections.enumerated() {
				for (itemIndex, element) in element.items.enumerated() {
					if identifiersSet.insert(element.base).inserted {
						indexPaths.append(IndexPath(item: itemIndex, section: sectionIndex))
						ids.append(element.base)
					}
				}
			}
			return (indexPaths, ids)
		}
		if #available(iOS 13.0, *) {
			guard let diff = diffDataSource else {
				return reloadHandler
			}
			
			let result = _filter()
			
			let reload = ReloadHandler()
			collectionView?.reloadHandlers.append(reload)
			reload._reload = { [weak collectionView] animatingDifferences, completion in
				var snap = diff.snapshot()
				snap.reloadItems(result.ids)
				diff.apply(snap, animatingDifferences: animatingDifferences, completion: completion.call)
				collectionView?.reloadHandlers.removeAll {
					ObjectIdentifier($0) == ObjectIdentifier(reload)
				}
			}
			return reload
		} else {
			guard collectionView?.dataSource != nil else {
				return reloadHandler
			}
			
			let result = _filter()
			
			let reload = ReloadHandler()
			collectionView?.reloadHandlers.append(reload)
			reload._reload = { [weak collectionView] animatingDifferences, completion in
				UIView.animate(withDuration: 0, animations: {
					collectionView?.reloadItems(at: result.indexPaths)
				}, completion: { _ in
					completion.call()
					collectionView?.reloadHandlers.removeAll {
						ObjectIdentifier($0) == ObjectIdentifier(reload)
					}
				})
			}
			return reload
		}
	}
	
	@inlinable
	public func contains(_ item: ItemIdentifier) -> Bool {
		sections.contains {
			$0.items.contains {
				$0.contains(item)
			}
		}
	}
	
	// MARK: - iOS14的内容
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	@discardableResult
	public func appendChildItems(_ childItems: [ItemIdentifier], to parent: ItemIdentifier?) -> ReloadHandler {
		
		let itemsUnique = childItems.unique()
		filterAddingItem(set: itemsUnique.set)
		guard let parent = parent else {
			if !sections.isEmpty {
				sections[sections.count-1].items.append(contentsOf: itemsUnique.array.map {
					.init($0)
				})
			}
			return reloadHandler.commit()
		}
		useDiffDataSource = true
		func find(item: CollectionView.ItemData<ItemIdentifier>) -> CollectionView.ItemData<ItemIdentifier>? {
			if item.base == parent {
				return item
			} else {
				for item in item.subItems {
					if let found = find(item: item) {
						return found
					}
				}
			}
			return nil
		}
		{
			for section in sections {
				for item in section.items {
					if let found = find(item: item) {
						found.subItems.append(contentsOf: itemsUnique.array.map({
							.init($0)
						}))
						return
					}
				}
			}
		}()
		return reloadHandler.commit()
	}
	
	// expand 的对象找不到不会有任何效果
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	@discardableResult
	public func expand(parents: [ItemIdentifier]) -> ReloadHandler {
		
		guard let diff = diffDataSource else { return reloadHandler }
		collectionView?.reloadImmediately()
		let reload = ReloadHandler()
		collectionView?.reloadHandlers.append(reload)
		reload._reload = { [weak collectionView] animatingDifferences, completion in
			var _completion: (() -> Void)? = {
				completion.call()
				collectionView?.reloadHandlers.removeAll {
					ObjectIdentifier($0) == ObjectIdentifier(reload)
				}
			}
			for section in self.sections {
				var snapshot = diff.snapshot(for: section.section())
				snapshot.expand(parents)
				diff.apply(snapshot, to: section.section(), animatingDifferences: animatingDifferences, completion: _completion)
				_completion = nil
			}
		}
		return reload.commit()
	}
	
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	@discardableResult
	public func collapse(parents: [ItemIdentifier]) -> ReloadHandler {
		
		guard let diff = diffDataSource else { return reloadHandler }
		collectionView?.reloadImmediately()
		let reload = ReloadHandler()
		collectionView?.reloadHandlers.append(reload)
		reload._reload = { [weak collectionView] animatingDifferences, completion in
			var _completion: (() -> Void)? = {
				completion.call()
				collectionView?.reloadHandlers.removeAll {
					ObjectIdentifier($0) == ObjectIdentifier(reload)
				}
			}
			for section in self.sections {
				var snapshot = diff.snapshot(for: section.section())
				snapshot.collapse(parents)
				diff.apply(snapshot, to: section.section(), animatingDifferences: animatingDifferences, completion: _completion)
				_completion = nil
			}
		}
		return reload.commit()
	}
	
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	public func isExpanded(_ item: ItemIdentifier) -> Bool {
		guard let diff = diffDataSource else { return false }
		collectionView?.reloadImmediately()
		return sections.contains {
			diff.snapshot(for: $0.section()).isExpanded(item)
		}
	}
	// level 是从0开始
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	public func level(of item: ItemIdentifier) -> Int {
		guard let diff = diffDataSource else { return 0 }
		collectionView?.reloadImmediately()
		return sections.map {
			diff.snapshot(for: $0.section()).level(of: item)
		}.max() ?? 0
	}
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	public func parent(of child: ItemIdentifier) -> ItemIdentifier? {
		
		guard let diff = diffDataSource else { return nil }
		collectionView?.reloadImmediately()
		for section in sections {
			let snapshot = diff.snapshot(for: section.section())
			if let parent = snapshot.parent(of: child) {
				return parent
			}
		}
		return nil
	}
	
	@available(iOS 14.0, *)
	@inlinable
	public func visibleItems() -> [ItemIdentifier] {
		guard let diff = diffDataSource else {
			return sections.flatMap {
				$0.items.map {
					$0.base
				}
			}
		}
		collectionView?.reloadImmediately()
		return sections.flatMap {
			diff.snapshot(for: $0.section()).visibleItems
		}
	}
	
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	public func visibleItems(atSection index: Int) -> [ItemIdentifier]? {
		guard index < sections.count else {
			return nil
		}
		guard let diff = diffDataSource else {
			return sections[index].items.map {
				$0.base
			}
		}
		collectionView?.reloadImmediately()
		return diff.snapshot(for: sections[index].section()).visibleItems
	}
	
	// item 找不到会crash
	// 'NSInternalInconsistencyException', reason: 'Invalid parameter not satisfying: index != NSNotFound'
	@available(iOS 14.0, *)
	@inlinable
	public func isVisible(_ item: ItemIdentifier) -> Bool {
		guard let diff = diffDataSource else {
			return sections.contains {
				$0.items.contains {
					$0.base == item
				}
			}
		}
		guard sections.contains(where:{
			$0.items.contains {
				$0.contains(item)
			}
		}) else {
			assertionFailure("Invalid parameter not satisfying: index != NSNotFound")
			return false
		}
		collectionView?.reloadImmediately()
		return sections.contains {
			diff.snapshot(for: $0.section()).isVisible(item)
		}
	}
	
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	public func rootItems() -> [ItemIdentifier] {
		sections.flatMap {
			$0.items.map {
				$0.base
			}
		}
	}
	
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	public func rootItems(atSection index: Int) -> [ItemIdentifier]? {
		guard index < sections.count else {
			return nil
		}
		return sections[index].items.map {
			$0.base
		}
	}
}
// MARK: - ItemType: Hashable, SectionIdentifier == AnyHashable
extension CollectionView.DataManager where ItemType: Hashable, SectionIdentifier == CollectionView.AnyHashable {
	@inlinable
	@discardableResult
	public func apply(_ items: [ItemIdentifier]) -> ReloadHandler {
		sections = [.init(sectionIdentifier: UUID(), items: items)]
		return reloadHandler.commit()
	}
	
	@inlinable
	@discardableResult
	public func apply(_ sections: [[ItemIdentifier]]) -> ReloadHandler {
		self.sections = sections.map {
			.init(sectionIdentifier: UUID(), items: $0)
		}
		return reloadHandler.commit()
	}
	@inlinable
	@discardableResult
	public func apply<Section>(_ items: [ItemIdentifier], updatedSection sectionIdentifier: Section) -> ReloadHandler where Section: Hashable {
		if let index = sections.firstIndex(where: {
			$0.anySection == sectionIdentifier
		}) {
			sections[index].items = items.map {
				.init($0)
			}
		} else {
			sections.append(.init(sectionIdentifier: sectionIdentifier, items: items))
		}
		
		return reloadHandler.commit()
	}
	
	// NSDiffableDataSourceSnapshot 为空会crash
	// 'NSInternalInconsistencyException', reason: 'There are currently no sections in the data source. Please add a section first.'
	
	// 如果toSction找不到会crash
	// 'NSInternalInconsistencyException', reason: 'Invalid parameter not satisfying: section != NSNotFound'
	@inlinable
	@discardableResult
	public func appendItems<Section>(_ items: [ItemIdentifier], toSection sectionIdentifier: Section) -> ReloadHandler where Section: Hashable {
		guard !sections.isEmpty else {
			assertionFailure("There are currently no sections in the data source. Please add a section first.")
			return reloadHandler
		}
		
		guard let sectionIndex = sections.firstIndex(where: {
			$0.anySection == sectionIdentifier
		}) else {
			assertionFailure("Invalid parameter not satisfying: section != NSNotFound")
			return reloadHandler
		}
		
		let itemUnique = items.unique()
		filterAddingItem(set: itemUnique.set)
		
		sections[sectionIndex].items.append(contentsOf: itemUnique.array.map {
			.init($0)
		})
		return reloadHandler.commit()
	}
	@inlinable
	public func allItems<Section>(inSection identifier: Section) -> [ItemIdentifier]? where Section: Hashable {
		sections.first {
			$0.anySection == identifier
		}?.items.flatMap {
			$0.allItems
		}
	}
	@inlinable
	public func sectionIdentifier<Section>(containingItem identifier: ItemIdentifier) -> Section? where Section: Hashable {
		for section in sections {
			if section.items.contains(where: {
				$0.contains(identifier)
			}) {
				return section.trySection()
			}
		}
		return nil
	}
	
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	public func visibleItems<Section>(inSection identifier: Section) -> [ItemIdentifier]? where Section : Hashable {
		guard let diff = diffDataSource else {
			return sections.first {
				$0.anySection == identifier
			}?.items.map {
				$0.base
			}
		}
		collectionView?.reloadImmediately()
		return sections.first {
			$0.anySection == identifier
		}.map {
			diff.snapshot(for: $0.section()).visibleItems
		}
	}
	
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	public func rootItems<Section>(inSection identifier: Section) -> [ItemIdentifier]? where Section : Hashable {
		sections.first {
			$0.anySection == identifier
		}?.items.map {
			$0.base
		}
	}
}
// MARK: - ItemType: Hashable, SectionType: Hashable
extension CollectionView.DataManager where ItemType: Hashable, SectionType: Hashable {

	@inlinable
	@discardableResult
	public func apply(_ sections: [(section: SectionType, items: [ItemIdentifier])]) -> ReloadHandler {
		self.sections = sections.map { (section, items) in
			.init(sectionIdentifier: section, items: items)
		}
		
		return reloadHandler.commit()
	}
	@inlinable
	@discardableResult
	public func apply(_ items: [ItemIdentifier], updatedSection sectionIdentifier: SectionType) -> ReloadHandler {
		if let index = sections.firstIndex(where: {
			$0.anySection == sectionIdentifier
		}) {
			sections[index].items = items.map {
				.init($0)
			}
		} else {
			sections.append(.init(sectionIdentifier: sectionIdentifier, items: items))
		}
		
		return reloadHandler.commit()
	}
	
	// NSDiffableDataSourceSnapshot 为空会crash
	// 'NSInternalInconsistencyException', reason: 'There are currently no sections in the data source. Please add a section first.'
	
	// 如果toSction找不到会crash
	// 'NSInternalInconsistencyException', reason: 'Invalid parameter not satisfying: section != NSNotFound'
	@inlinable
	@discardableResult
	public func appendItems(_ items: [ItemIdentifier], toSection sectionIdentifier: SectionType) -> ReloadHandler {
		guard !sections.isEmpty else {
			assertionFailure("There are currently no sections in the data source. Please add a section first.")
			return reloadHandler
		}
		
		guard let sectionIndex = sections.firstIndex(where: {
			$0.anySection == sectionIdentifier
		}) else {
			assertionFailure("Invalid parameter not satisfying: section != NSNotFound")
			return reloadHandler
		}
		
		let itemUnique = items.unique()
		filterAddingItem(set: itemUnique.set)
		
		sections[sectionIndex].items.append(contentsOf: itemUnique.array.map {
			.init($0)
		})
		return reloadHandler.commit()
	}
	@inlinable
	public func allItems(inSection identifier: SectionType) -> [ItemIdentifier]? {
		sections.first {
			$0.anySection == identifier
		}?.items.flatMap {
			$0.allItems
		}
	}
	@inlinable
	public func sectionIdentifier(containingItem identifier: ItemIdentifier) -> SectionType? {
		for section in sections {
			if section.items.contains(where: {
				$0.contains(identifier)
			}) {
				return section.trySection()
			}
		}
		return nil
	}
	
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	public func visibleItems(inSection identifier: SectionType) -> [ItemIdentifier]? {
		guard let diff = diffDataSource else {
			return sections.first {
				$0.anySection == identifier
			}?.items.map {
				$0.base
			}
		}
		collectionView?.reloadImmediately()
		return sections.first {
			$0.anySection == identifier
		}.map {
			diff.snapshot(for: $0.section()).visibleItems
		}
	}
	
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	public func rootItems(inSection identifier: SectionType) -> [ItemIdentifier]? {
		sections.first {
			$0.anySection == identifier
		}?.items.map {
			$0.base
		}
	}
}

// MARK: - ItemIdentifier == AnyHashable
extension CollectionView.DataManager where ItemIdentifier == CollectionView.AnyHashable {
	@usableFromInline
	func filterAddingItem<Item>(set: Set<Item>) where Item: Hashable {
		var set = set
		var sectionIndex = sections.count-1
		var itemIndex = 0
		while sectionIndex >= 0 {
			itemIndex = sections[sectionIndex].items.count-1
			while itemIndex >= 0  {
				if let item = sections[sectionIndex].items[itemIndex].base.base as? Item, !set.insert(item).inserted {
					sections[sectionIndex].items.remove(at: itemIndex)
					return
				} else {
					itemIndex -= 1
				}
			}
			sectionIndex -= 1
		}
	}
	
	@inlinable
	@discardableResult
	public func apply<Item>(_ items: [Item], atSection index: Int) -> ReloadHandler where Item: Hashable {
		guard index < sections.count else {
			return reloadHandler
		}
		sections[index].items = items.map {
			.init(.package($0))
		}
		
		return reloadHandler.commit()
	}
	
	@inlinable
	public func itemIdentifier<Item>(for indexPath: IndexPath) -> Item? where Item : Hashable {
		element(for: indexPath) as? Item
	}
	
	@inlinable
	public func indexPath<Item>(for itemIdentifier: Item) -> IndexPath? where Item : Hashable {
		if #available(iOS 13.0, *), let diff = diffDataSource {
			collectionView?.reloadImmediately()
			return diff.indexPath(for: .package(itemIdentifier))
		} else {
			for pair in sections.enumerated() {
				if let itemIndex = pair.element.items.firstIndex(where: {
					$0.base == itemIdentifier
				}) {
					return IndexPath(item: itemIndex, section: pair.offset)
				}
			}
		}
		
		return nil
	}
	
	@inlinable
	@discardableResult
	public func appendItems<Item>(_ items: [Item]) -> ReloadHandler where Item: Hashable {
		guard !sections.isEmpty else {
			assertionFailure("There are currently no sections in the data source. Please add a section first.")
			return reloadHandler
		}
		
		let itemUnique = items.unique()
		filterAddingItem(set: itemUnique.set)
		
		sections[sections.count-1].items.append(contentsOf: itemUnique.array.map {
			.init(.package($0))
		})
		return reloadHandler.commit()
	}
	
	@inlinable
	@inline(__always)
	func insertItems<Item>(identifier: Item) -> (section: Int, item: Int)? where Item: Hashable {
		var sectionIndex = 0
		var itemIndex = 0
		while sectionIndex < sections.count {
			itemIndex = 0
			while itemIndex < sections[sectionIndex].items.count {
				if let item = sections[sectionIndex].items[itemIndex].base.base as? Item, item == identifier {
					return (sectionIndex, itemIndex)
				}
				itemIndex += 1
			}
			sectionIndex += 1
		}
		
		assertionFailure("Invalid parameter not satisfying: section != NSNotFound")
		return nil
	}
	@inlinable
	@discardableResult
	public func insertItems<Insert, Before>(_ identifiers: [Insert], beforeItem beforeIdentifier: Before) -> ReloadHandler where Insert: Hashable, Before: Hashable {
		guard let result = insertItems(identifier: beforeIdentifier) else {
			return reloadHandler
		}
		
		let itemsUnique = identifiers.unique()
		filterAddingItem(set: itemsUnique.set)
		
		sections[result.section].items.insert(contentsOf: itemsUnique.array.map {
			.init(.package($0))
		}, at: result.item)
		
		return reloadHandler.commit()
	}
	// TODO:    得测试一下NSDiffableDataSourceSnapshot找不到的话会怎么样
	@inlinable
	@discardableResult
	public func insertItems<Insert, After>(_ identifiers: [Insert], afterItem afterIdentifier: After) -> ReloadHandler where Insert: Hashable, After: Hashable {
		guard let result = insertItems(identifier: afterIdentifier) else {
			return reloadHandler
		}
		
		let itemsUnique = identifiers.unique()
		filterAddingItem(set: itemsUnique.set)
		
		sections[result.section].items.insert(contentsOf: itemsUnique.array.map {
			.init(.package($0))
		}, at: result.item + 1)
		
		return reloadHandler.commit()
	}
	
	@inlinable
	public func allItems<Item>() -> [Item] where Item: Hashable{
		sections.flatMap {
			$0.items.flatMap {
				$0.allItems.compactMap {
					$0.base as? Item
				}
			}
		}
	}
	
	@inlinable
	public func allItems<Item>(atSectionIndex index: Int) -> [Item]? where Item: Hashable {
		if index < sections.count {
			return sections[index].items.flatMap {
				$0.allItems.compactMap {
					$0.base as? Item
				}
			}
		}
		
		return nil
	}
	
	@inlinable
	@discardableResult
	public func deleteItems<Item>(_ identifiers: [Item]) -> ReloadHandler where Item: Hashable {
		for identifier in identifiers {
			var section = 0
			while section < sections.count {
				var index = sections[section].items.count-1
				while section > 0 {
					let item = sections[section].items[index]
					if item.base == identifier {
						sections[section].items.remove(at: index)
					} else {
						item.removeAllSubItems(identifier)
					}
					index -= 1
				}
				section += 1
			}
		}
		
		return reloadHandler.commit()
	}
	
	@inlinable
	@inline(__always)
	func moveItem<Moved, Before>(_ identifier: Moved, toIdentifier: Before) -> (from: (section: Int, item: Int), to: (section: Int, item: Int))? where Moved: Hashable, Before: Hashable {
		var sectionIndex = 0
		var itemIndex = 0
		var from: (section: Int, item: Int)?
		var to: (section: Int, item: Int)?
		
		while sectionIndex < sections.count {
			itemIndex = 0
			while itemIndex < sections[sectionIndex].items.count {
				let current = sections[sectionIndex].items[itemIndex].base
				if current == identifier {
					from = (sectionIndex, itemIndex)
				} else if current == toIdentifier {
					to = (sectionIndex, itemIndex)
				}
				if let from = from, let to = to {
					return (from, to)
				}
				itemIndex += 1
			}
			sectionIndex += 1
		}
		assert(from != nil, "Invalid parameter not satisfying: fromIndex != NSNotFound")
		assert(to != nil, "Invalid parameter not satisfying: toIndex != NSNotFound")
		return nil
	}
	@inlinable
	@discardableResult
	public func moveItem<Moved, Before>(_ identifier: Moved, beforeItem beforeIdentifier: Before) -> ReloadHandler where Moved: Hashable, Before: Hashable {
		guard let (from, to) = moveItem(identifier, toIdentifier: beforeIdentifier) else {
			return reloadHandler
		}
		
		sections[to.section].items.insert(sections[from.section].items.remove(at: from.item), at: to.item)
		return reloadHandler.commit()
	}
	@inlinable
	@discardableResult
	public func moveItem<Moved, After>(_ identifier: Moved, afterItem afterIdentifier: After) -> ReloadHandler where Moved: Hashable, After: Hashable {
		guard let (from, to) = moveItem(identifier, toIdentifier: afterIdentifier) else {
			return reloadHandler
		}
		
		sections[to.section].items.insert(sections[from.section].items.remove(at: from.item), at: to.item+1)
		return reloadHandler.commit()
	}
	
	// TODO:    测试一下NSDiffableDataSourceSnapshot.reloadItems有什么用
	@inlinable
	@discardableResult
	public func reloadItems<Item>(_ identifiers: [Item]) -> ReloadHandler where Item: Hashable {
		func _filter() -> (indexPaths: [IndexPath], ids: [Item]) {
			var identifiersSet = Set(identifiers)
			
			var indexPaths = [IndexPath]()
			var ids = [Item]()
			for (sectionIndex, element) in sections.enumerated() {
				for (itemIndex, element) in element.items.enumerated() {
					if let item = element.base.base as? Item, identifiersSet.insert(item).inserted {
						indexPaths.append(IndexPath(item: itemIndex, section: sectionIndex))
						ids.append(item)
					}
				}
			}
			return (indexPaths, ids)
		}
		if #available(iOS 13.0, *) {
			guard let diff = diffDataSource else {
				return reloadHandler
			}
			
			let result = _filter()
			
			let reload = ReloadHandler()
			collectionView?.reloadHandlers.append(reload)
			reload._reload = { [weak collectionView] animatingDifferences, completion in
				var snap = diff.snapshot()
				snap.reloadItems(result.ids.map {
					.package($0)
				})
				diff.apply(snap, animatingDifferences: animatingDifferences, completion: completion.call)
				collectionView?.reloadHandlers.removeAll {
					ObjectIdentifier($0) == ObjectIdentifier(reload)
				}
			}
			return reload
		} else {
			guard collectionView?.dataSource != nil else {
				return reloadHandler
			}
			
			let result = _filter()
			
			let reload = ReloadHandler()
			collectionView?.reloadHandlers.append(reload)
			reload._reload = { [weak collectionView] animatingDifferences, completion in
				UIView.animate(withDuration: 0, animations: {
					collectionView?.reloadItems(at: result.indexPaths)
				}, completion: { _ in
					completion.call()
					collectionView?.reloadHandlers.removeAll {
						ObjectIdentifier($0) == ObjectIdentifier(reload)
					}
				})
			}
			return reload
		}
	}
	
	@inlinable
	public func contains<Item>(_ item: Item) -> Bool where Item : Hashable {
		sections.contains {
			$0.items.contains {
				$0.contains(item)
			}
		}
	}
	
	// MARK: - iOS14的内容
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	@discardableResult
	public func appendChildItems<Child, Parent>(_ childItems: [Child], to parent: Parent) -> ReloadHandler where Child: Hashable, Parent: Hashable {
		
		let itemsUnique = childItems.unique()
		filterAddingItem(set: itemsUnique.set)
		
		useDiffDataSource = true
		func find(item: CollectionView.ItemData<ItemIdentifier>) -> CollectionView.ItemData<ItemIdentifier>? {
			if item.base == parent {
				return item
			} else {
				for item in item.subItems {
					if let found = find(item: item) {
						return found
					}
				}
			}
			return nil
		}
		{
			for section in sections {
				for item in section.items {
					if let found = find(item: item) {
						found.subItems.append(contentsOf: itemsUnique.array.map({
							.init(.package($0))
						}))
						return
					}
				}
			}
		}()
		return reloadHandler.commit()
	}
	
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	@discardableResult
	public func expand<Parent>(parents: [Parent]) -> ReloadHandler where Parent: Hashable {
		
		guard let diff = diffDataSource else { return reloadHandler }
		collectionView?.reloadImmediately()
		let reload = ReloadHandler()
		collectionView?.reloadHandlers.append(reload)
		reload._reload = { [weak collectionView] animatingDifferences, completion in
			var _completion: (() -> Void)? = {
				completion.call()
				collectionView?.reloadHandlers.removeAll {
					ObjectIdentifier($0) == ObjectIdentifier(reload)
				}
			}
			for section in self.sections {
				var snapshot = diff.snapshot(for: section.section())
				snapshot.expand(parents.map {
					.package($0)
				})
				diff.apply(snapshot, to: section.section(), animatingDifferences: animatingDifferences, completion: _completion)
				_completion = nil
			}
		}
		return reload.commit()
	}
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	@discardableResult
	public func collapse<Parent>(parents: [Parent]) -> ReloadHandler where Parent: Hashable {
		
		guard let diff = diffDataSource else { return reloadHandler }
		collectionView?.reloadImmediately()
		let reload = ReloadHandler()
		collectionView?.reloadHandlers.append(reload)
		reload._reload = { [weak collectionView] animatingDifferences, completion in
			var _completion: (() -> Void)? = {
				completion.call()
				collectionView?.reloadHandlers.removeAll {
					ObjectIdentifier($0) == ObjectIdentifier(reload)
				}
			}
			for section in self.sections {
				var snapshot = diff.snapshot(for: section.section())
				snapshot.collapse(parents.map {
					.package($0)
				})
				diff.apply(snapshot, to: section.section(), animatingDifferences: animatingDifferences, completion: _completion)
				_completion = nil
			}
		}
		return reload.commit()
	}
	
	
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	public func isExpanded<Parent>(_ item: Parent) -> Bool where Parent: Hashable {
		guard let diff = diffDataSource else { return false }
		collectionView?.reloadImmediately()
		return sections.contains {
			diff.snapshot(for: $0.section()).isExpanded(.package(item))
		}
	}
	
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	public func level<Item>(of item: Item) -> Int where Item: Hashable {
		guard let diff = diffDataSource else { return 0 }
		collectionView?.reloadImmediately()
		return sections.map {
			diff.snapshot(for: $0.section()).level(of: .package(item))
		}.max() ?? 0
	}
	
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	public func parent<Child, Parent>(of child: Child) -> Parent? where Child: Hashable, Parent: Hashable {
		guard let diff = diffDataSource else { return nil }
		collectionView?.reloadImmediately()
		for section in sections {
			let snapshot = diff.snapshot(for: section.section())
			if let parent = snapshot.parent(of: .package(child)) as? Parent {
				return parent
			}
		}
		return nil
	}
	
	@available(iOS 14.0, *)
	@inlinable
	public func visibleItems<Item>() -> [Item] where Item: Hashable {
		guard let diff = diffDataSource else {
			return sections.flatMap {
				$0.items.compactMap({
					$0.base as? Item
				})
			}
		}
		collectionView?.reloadImmediately()
		return sections.flatMap {
			diff.snapshot(for: $0.section()).visibleItems.compactMap {
				$0.base as? Item
			}
		}
	}
	
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	public func visibleItems<Item>(atSection index: Int) -> [Item]? where Item: Hashable {
		guard index < sections.count else {
			return nil
		}
		guard let diff = diffDataSource else {
			return sections[index].items.compactMap {
				$0.base.base as? Item
			}
		}
		collectionView?.reloadImmediately()
		return diff.snapshot(for: sections[index].section()).visibleItems.compactMap {
			$0.base as? Item
		}
	}
	
	@available(iOS 14.0, *)
	@inlinable
	public func isVisible<Item>(_ item: Item) -> Bool where Item: Hashable {
		guard let diff = diffDataSource else {
			return sections.contains {
				$0.items.contains {
					$0.base == item
				}
			}
		}
		guard sections.contains(where:{
			$0.items.contains {
				$0.contains(item)
			}
		}) else {
			assertionFailure("Invalid parameter not satisfying: index != NSNotFound")
			return false
		}
		collectionView?.reloadImmediately()
		return sections.contains {
			diff.snapshot(for: $0.section()).isVisible(.package(item))
		}
	}
	
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	public func rootItems<Item>() -> [Item] where Item: Hashable {
		sections.flatMap {
			$0.items.compactMap {
				$0.base.base as? Item
			}
		}
	}
	
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	public func rootItems<Item>(atSectionIndex index: Int) -> [Item]? where Item: Hashable {
		guard index < sections.count else {
			return nil
		}
		return sections[index].items.compactMap {
			$0.base.base as? Item
		}
	}
}
// MARK: - ItemIdentifier, SectionIdentifier == AnyHashable
extension CollectionView.DataManager where ItemIdentifier == CollectionView.AnyHashable, SectionIdentifier == CollectionView.AnyHashable {
	@inlinable
	@discardableResult
	public func apply<Item>(_ items: [Item]) -> ReloadHandler where Item: Hashable {
		sections = [.init(sectionIdentifier: UUID(), items: items.map {
			.package($0)
		})]
		return reloadHandler.commit()
	}
	@inlinable
	@discardableResult
	public func apply<Item>(_ sections: [[Item]]) -> ReloadHandler where Item: Hashable {
		self.sections = sections.map {
			.init(sectionIdentifier: UUID(), items: $0.map{
				.package($0)
			})
		}
		
		return reloadHandler.commit()
	}
	
	@inlinable
	@discardableResult
	public func apply<Section, Item>(_ items: [Item], updatedSection sectionIdentifier: Section) -> ReloadHandler where Item: Hashable, Section: Hashable {
		if let index = sections.firstIndex(where: {
			$0.anySection == sectionIdentifier
		}) {
			sections[index].items = items.map {
				.init(.package($0))
			}
		} else {
			sections.append(.init(sectionIdentifier: sectionIdentifier, items: items.map{
				.package($0)
			}))
		}
		return reloadHandler.commit()
	}
	@inlinable
	@discardableResult
	public func appendItems<Section, Item>(_ items: [Item], toSection sectionIdentifier: Section) -> ReloadHandler where Item: Hashable, Section: Hashable {
		guard !sections.isEmpty else {
			assertionFailure("There are currently no sections in the data source. Please add a section first.")
			return reloadHandler
		}
		
		guard let sectionIndex = sections.firstIndex(where: {
			$0.anySection == sectionIdentifier
		}) else {
			assertionFailure("Invalid parameter not satisfying: section != NSNotFound")
			return reloadHandler
		}
		
		let itemUnique = items.unique()
		filterAddingItem(set: itemUnique.set)
		
		sections[sectionIndex].items.append(contentsOf: itemUnique.array.map {
			.init(.package($0))
		})
		return reloadHandler.commit()
	}
	@inlinable
	public func allItems<Section, Item>(inSection identifier: Section) -> [Item]? where Item: Hashable, Section: Hashable {
		sections.first {
			$0.anySection == identifier
		}?.items.flatMap {
			$0.allItems.compactMap {
				$0.base as? Item
			}
		}
	}
	
	@inlinable
	public func sectionIdentifier<Section, Item>(containingItem identifier: Item) -> Section? where Item: Hashable , Section: Hashable {
		for section in sections {
			if section.items.contains(where: {
				$0.contains(identifier)
			}) {
				return section.trySection()
			}
		}
		return nil
	}
	
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	public func visibleItems<Section, Item>(inSection identifier: Section) -> [Item]? where Item: Hashable, Section : Hashable {
		guard let diff = diffDataSource else {
			return sections.first {
				$0.anySection == identifier
			}?.items.compactMap {
				$0.base.base as? Item
			}
		}
		collectionView?.reloadImmediately()
		return sections.first {
			$0.anySection == identifier
		}.map {
			diff.snapshot(for: $0.section()).visibleItems.compactMap {
				$0.base as? Item
			}
		}
	}
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	public func rootItems<Section, Item>(inSection identifier: Section) -> [Item]? where Item: Hashable, Section: Hashable {
		sections.first {
			$0.anySection == identifier
		}?.items.compactMap {
			$0.base.base as? Item
		}
	}
}
// MARK: - ItemIdentifier == AnyHashable, SectionType: Hashable
extension CollectionView.DataManager where ItemIdentifier == CollectionView.AnyHashable, SectionType: Hashable {
	@inlinable
	@discardableResult
	public func apply<Item>(_ items: [Item], updatedSection sectionIdentifier: SectionType) -> ReloadHandler where Item: Hashable {
		if let index = sections.firstIndex(where: {
			$0.anySection == sectionIdentifier
		}) {
			sections[index].items = items.map {
				.init(.package($0))
			}
		} else {
			sections.append(.init(sectionIdentifier: sectionIdentifier, items: items.map{
				.package($0)
			}))
		}
		return reloadHandler.commit()
	}
	@inlinable
	@discardableResult
	public func appendItems<Item>(_ items: [Item], toSection sectionIdentifier: SectionType) -> ReloadHandler where Item: Hashable {
		guard !sections.isEmpty else {
			assertionFailure("There are currently no sections in the data source. Please add a section first.")
			return reloadHandler
		}
		
		guard let sectionIndex = sections.firstIndex(where: {
			$0.anySection == sectionIdentifier
		}) else {
			assertionFailure("Invalid parameter not satisfying: section != NSNotFound")
			return reloadHandler
		}
		
		let itemUnique = items.unique()
		filterAddingItem(set: itemUnique.set)
		
		sections[sectionIndex].items.append(contentsOf: itemUnique.array.map {
			.init(.package($0))
		})
		return reloadHandler.commit()
	}
	@inlinable
	public func allItems<Item>(inSection identifier: SectionType) -> [Item]? where Item: Hashable {
		sections.first {
			$0.anySection == identifier
		}?.items.flatMap {
			$0.allItems.compactMap {
				$0.base as? Item
			}
		}
	}
	
	@inlinable
	public func sectionIdentifier<Item>(containingItem identifier: Item) -> SectionType? where Item: Hashable  {
		for section in sections {
			if section.items.contains(where: {
				$0.contains(identifier)
			}) {
				return section.trySection()
			}
		}
		return nil
	}
	
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	public func visibleItems<Item>(inSection identifier: SectionType) -> [Item]? where Item: Hashable, SectionType : Hashable {
		guard let diff = diffDataSource else {
			return sections.first {
				$0.anySection == identifier
			}?.items.compactMap {
				$0.base.base as? Item
			}
		}
		collectionView?.reloadImmediately()
		return sections.first {
			$0.anySection == identifier
		}.map {
			diff.snapshot(for: $0.section()).visibleItems.compactMap {
				$0.base as? Item
			}
		}
	}
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	public func rootItems<Item>(inSection identifier: SectionType) -> [Item]? where Item: Hashable {
		sections.first {
			$0.anySection == identifier
		}?.items.compactMap {
			$0.base.base as? Item
		}
	}
}

