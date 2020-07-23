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
protocol CollectionViewDataManager {
	var lastIndexPath: IndexPath? { get }
	func element(for indexPath: IndexPath) -> Any
}

extension CollectionView {
	public class DataManager<DataType> where DataType: Hashable {
		@usableFromInline
		weak var collectionView: CollectionView?
		@usableFromInline
		var sections = [SectionData<DataType>]()
		@usableFromInline
		var useDiffDataSource = false
		var _diffDataSource: Any?
		
		@available(iOS 13.0, *)
		@usableFromInline
		typealias DiffDataSource = UICollectionViewDiffableDataSource<CollectionView.AnyHashable, DataType>
		
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
				var completion = completion
				for section in dataManager.sections {
					var snapshot = NSDiffableDataSourceSectionSnapshot<DataType>()
					func addItems(_ items: [CollectionView.ItemData<DataType>], to parent: CollectionView.ItemData<DataType>?) {
						snapshot.append(items.map({
							$0.base
						}), to: parent?.base)
						for item in items where !item.subItems.isEmpty {
							addItems(item.subItems, to: item)
						}
					}
					
					addItems(section.items, to: nil)
					dataManager.diffDataSource?.apply(snapshot, to: section.section, animatingDifferences: animatingDifferences, completion: completion)
					completion = nil
				}
			} else if #available(iOS 13.0, *) {
				var snapshot = NSDiffableDataSourceSnapshot<CollectionView.AnyHashable, DataType>()
				
				snapshot.appendSections(dataManager.sections.map({
					$0.section
				}))
				for section in dataManager.sections {
					snapshot.appendItems(section.items.map({
						$0.base
					}), toSection: section.section)
				}
				dataManager.diffDataSource?.apply(snapshot, animatingDifferences: animatingDifferences, completion: completion)
			} else if let dataSource = collectionView.dataSource as? CollectionView.DataSourceBase<DataType> {
				dataSource.sections = dataManager.sections
				UIView.animate(withDuration: 0, animations: {
					collectionView.reloadData()
				}, completion: { _ in
					completion?()
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
			return item as Any
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
				let cellProvider: DiffDataSource.CellProvider
				if DataType.self == CollectionView.AnyHashable.self {
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
			let dataSource = CollectionView.DataSourceBase<DataType>(collectionView: collectionView)
			return dataSource
		}
	}
}
// visibleItems是展开的item合集
extension CollectionView.DataManager: CollectionViewDataManager {
	@usableFromInline
	@inline(__always)
	var reloadHandler: _CollectionViewReloadHandler {
		collectionView?.reloadHandlers.first ?? .init()
	}
	
	@inlinable
	public var isEmpty: Bool {
		sections.isEmpty
	}
	// 添加已有的section会crash
	// 'NSInternalInconsistencyException', reason: 'Section identifier count does not match data source count. This is most likely due to a hashing issue with the identifiers.'
	@inlinable
	@discardableResult
	public func appendSections<SectionIdentifierType>(_ identifiers: [SectionIdentifierType]) -> _CollectionViewReloadHandler where SectionIdentifierType: Hashable {
		
		var set = Set(sections.map { $0.section })
		
		sections.append(contentsOf: identifiers.map {
			CollectionView.AnyHashable($0)
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
	func insertSections<InsertType, BeforeType>(_ identifiers: [InsertType], toIdentifier: BeforeType) -> ([CollectionView.AnyHashable], index: Int)? where InsertType: Hashable, BeforeType: Hashable {
		let itemsUnique = identifiers.unique().array.map({
			CollectionView.AnyHashable($0)
		})
		assert(identifiers.count == itemsUnique.count, "Fatal: supplied section identifiers are not unique.")
		guard let index = sections.firstIndex(where: {
			$0.section == toIdentifier
		}) else {
			assertionFailure("Invalid parameter not satisfying: insertIndex != NSNotFound")
			return nil
		}
		var existSectionSet = Set(sections.map {
			$0.section
		})
		let insertIdentifierUnique = itemsUnique.filter {
			existSectionSet.insert($0).inserted
		}
		assert(insertIdentifierUnique.count == itemsUnique.count, "Invalid update: destination for section operation \(itemsUnique.filter { !itemsUnique.contains($0) }) is in the inserted section list for update")
		return (itemsUnique, index)
	}
	@inlinable
	@discardableResult
	public func insertSections<InsertType, BeforeType>(_ identifiers: [InsertType], beforeSection toIdentifier: BeforeType) -> _CollectionViewReloadHandler where InsertType: Hashable, BeforeType: Hashable {
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
	public func insertSections<InsertType, AfterType>(_ identifiers: [InsertType], afterSection toIdentifier: AfterType) -> _CollectionViewReloadHandler where InsertType: Hashable, AfterType: Hashable {
		guard let result = insertSections(identifiers, toIdentifier: toIdentifier) else {
			return reloadHandler
		}
		sections.insert(contentsOf: result.0.map({
			.init(anySectionIdentifier: $0)
		}), at: result.index+1)
		return reloadHandler.commit()
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
	public func numberOfItems<SectionIdentifierType>(inSection identifier: SectionIdentifierType) -> Int where SectionIdentifierType: Hashable {
		sections.first {
			$0.section == identifier
		}?.items.count ?? 0
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
	public func indexOfSection<SectionIdentifierType>(_ identifier: SectionIdentifierType) -> Int? where SectionIdentifierType: Hashable {
		sections.firstIndex {
			$0.section == identifier
		}
	}
	
	@inlinable
	@discardableResult
	public func deleteSections<SectionIdentifierType>(_ identifiers: [SectionIdentifierType]) -> _CollectionViewReloadHandler where SectionIdentifierType: Hashable {
		sections.removeAll { item in
			identifiers.contains {
				item.section == $0
			}
		}
		
		return reloadHandler.commit()
	}
	
	@inlinable
	@discardableResult
	public func deleteAllItems() -> _CollectionViewReloadHandler {
		sections.removeAll()
		return reloadHandler.commit()
	}
	
	@inlinable
	@discardableResult
	public func reverseSections() -> _CollectionViewReloadHandler {
		sections.reverse()
		return reloadHandler.commit()
	}
	@inlinable
	@discardableResult
	public func reverseRootItems<SectionIdentifierType>(inSection identifier: SectionIdentifierType) -> _CollectionViewReloadHandler where SectionIdentifierType: Hashable {
		if let index = sections.firstIndex(where: {
			$0.section == identifier
		}) {
			sections[index].items.reverse()
		}
		
		return reloadHandler.commit()
	}
	@inlinable
	@discardableResult
	public func reverseRootItems(atSectionIndex index: Int) -> _CollectionViewReloadHandler {
		if index < sections.count {
			sections[index].items.reverse()
			return reloadHandler.commit()
		}
		return reloadHandler
	}
	
	// beforeSection找不到
	// 'NSInternalInconsistencyException', reason: 'Invalid parameter not satisfying: toSection != NSNotFound'
	
	// identifier 找不到
	// 'NSInternalInconsistencyException', reason: 'Invalid parameter not satisfying: fromSection != NSNotFound'
	@usableFromInline
	func moveSection<SectionIdentifierType, BeforeType>(_ identifier: SectionIdentifierType, toSection: BeforeType) -> (Int, Int)? where SectionIdentifierType: Hashable, BeforeType: Hashable {
		guard let movedIndex = sections.firstIndex(where: {
			$0.section == identifier
		}) else {
			assertionFailure("Invalid parameter not satisfying: fromSection != NSNotFound")
			return nil
		}
		guard let index = sections.firstIndex(where: {
			$0.section == toSection
		}) else {
			assertionFailure("Invalid parameter not satisfying: toSection != NSNotFound")
			return nil
		}
		return (movedIndex, index)
	}
	@inlinable
	@discardableResult
	public func moveSection<SectionIdentifierType, BeforeType>(_ identifier: SectionIdentifierType, beforeSection toSection: BeforeType) -> _CollectionViewReloadHandler where SectionIdentifierType: Hashable, BeforeType: Hashable {
		guard let result = moveSection(identifier, toSection: toSection) else {
			return reloadHandler
		}
		sections.insert(sections.remove(at: result.0), at: result.1)
		return reloadHandler.commit()
	}
	@inlinable
	@discardableResult
	public func moveSection<SectionIdentifierType, AfterType>(_ identifier: SectionIdentifierType, afterSection toSection: AfterType) -> _CollectionViewReloadHandler where SectionIdentifierType: Hashable, AfterType: Hashable {
		
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
	public func reloadSections<SectionIdentifierType>(_ identifiers: [SectionIdentifierType]) -> _CollectionViewReloadHandler where SectionIdentifierType: Hashable {
		func _filter() -> (indexs: [Int], ids: [CollectionView.AnyHashable]) {
			
			var identifiersSet = Set(identifiers.map({
				CollectionView.AnyHashable($0)
			}))
			
			var indexs = [Int]()
			var ids = [CollectionView.AnyHashable]()
			for (section, element) in sections.enumerated() {
				if identifiersSet.insert(element.section).inserted {
					indexs.append(section)
					ids.append(element.section)
				}
			}
			return (indexs, ids)
		}
		if #available(iOS 13.0, *) {
			guard let diff = diffDataSource else {
				return reloadHandler
			}
			let result = _filter()
			let reload = _CollectionViewReloadHandler()
			collectionView?.reloadHandlers.append(reload)
			reload._reload = { [weak collectionView] animatingDifferences, completion in
				var snap = diff.snapshot()
				snap.reloadSections(result.ids)
				diff.apply(snap, animatingDifferences: animatingDifferences, completion: completion)
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
			let reload = _CollectionViewReloadHandler()
			collectionView?.reloadHandlers.append(reload)
			reload._reload = { [weak collectionView] animatingDifferences, completion in
				UIView.animate(withDuration: 0, animations: {
					collectionView?.reloadSections(IndexSet(result.indexs))
				}, completion: { _ in
					completion?()
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
	public func visibleItems<SectionIdentifierType>(in sectionIdentifier: SectionIdentifierType) -> [DataType] where SectionIdentifierType: Hashable {
		guard let index = sections.first(where: {
			$0.section == sectionIdentifier
		}) else {
			return []
		}
		guard let diff = diffDataSource else {
			return index.items.map {
				$0.base
			}
		}
		return diff.snapshot(for: .init(sectionIdentifier)).visibleItems
	}
}

// MARK: - DataManager VerifyType == Void
extension CollectionView.DataManager where VerifyType == Void {
	@usableFromInline
	func filterAddingItem(set: Set<DataType>) {
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
	public func apply(_ datas: [DataType]) -> _CollectionViewReloadHandler {
		sections = [.init(sectionIdentifier: 0, items: datas)]
		return reloadHandler.commit()
	}
	@inlinable
	@discardableResult
	public func apply<SectionIdentifierType>(_ datas: [DataType], toSection sectionIdentifier: SectionIdentifierType) -> _CollectionViewReloadHandler where SectionIdentifierType: Hashable {
		sections = [.init(sectionIdentifier: sectionIdentifier, items: datas)]
		return reloadHandler.commit()
	}

	@inlinable
	@discardableResult
	public func apply(_ sections: [[DataType]]) -> _CollectionViewReloadHandler {
		self.sections = sections.enumerated().map {
			.init(sectionIdentifier: $0.offset, items: $0.element)
		}
		return reloadHandler.commit()
	}
	
	@inlinable
	public func itemIdentifier(for indexPath: IndexPath) -> DataType? {
		element(for: indexPath) as? DataType
	}
	
	// NSDiffableDataSourceSectionSnapshot.index(of:) 拿到的是 allItems 的 index
	@inlinable
	public func indexPath(for itemIdentifier: DataType) -> IndexPath? {
		if #available(iOS 13.0, *), let diff = diffDataSource {
			collectionView?.forceReload()
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
	
	// NSDiffableDataSourceSnapshot 为空会crash
	// 'NSInternalInconsistencyException', reason: 'There are currently no sections in the data source. Please add a section first.'
	
	// 如果toSction找不到会crash
	// 'NSInternalInconsistencyException', reason: 'Invalid parameter not satisfying: section != NSNotFound'
	@inlinable
	@discardableResult
	public func append<SectionIdentifierType>(items: [DataType], toSection sectionIdentifier: SectionIdentifierType) -> _CollectionViewReloadHandler where SectionIdentifierType: Hashable {
		guard !sections.isEmpty else {
			assertionFailure("There are currently no sections in the data source. Please add a section first.")
			return reloadHandler
		}
		
		guard let sectionIndex = sections.firstIndex(where: {
			$0.section == sectionIdentifier
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
	@discardableResult
	public func append(_ items: [DataType]) -> _CollectionViewReloadHandler {
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
	func insertItems(identifier: DataType) -> (section: Int, item: Int)? {
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
	public func insertItems(_ identifiers: [DataType], beforeItem beforeIdentifier: DataType) -> _CollectionViewReloadHandler {
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
	public func insertItems(_ identifiers: [DataType], afterItem afterIdentifier: DataType) -> _CollectionViewReloadHandler {
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
	public func allItems() -> [DataType] {
		sections.flatMap {
			$0.items.flatMap {
				$0.allItems
			}
		}
	}
	@inlinable
	public func allItems<SectionIdentifierType>(inSection identifier: SectionIdentifierType) -> [DataType]? where SectionIdentifierType: Hashable {
		sections.first {
			$0.section == identifier
		}?.items.flatMap {
			$0.allItems
		}
	}
	
	@inlinable
	public func allItems(atSection index: Int) -> [DataType]? {
		if index < sections.count {
			return sections[index].items.flatMap {
				$0.allItems
			}
		}
		return nil
	}
	
	@inlinable
	public func sectionIdentifier<SectionIdentifierType>(containingItem identifier: DataType) -> SectionIdentifierType? where SectionIdentifierType: Hashable {
		for section in sections {
			if section.items.contains(where: {
				$0.contains(identifier)
			}) {
				return section.section.base as? SectionIdentifierType
			}
		}
		return nil
	}
	
	@inlinable
	@discardableResult
	public func deleteItems(_ identifiers: [DataType]) -> _CollectionViewReloadHandler {
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
	func moveItem(_ identifier: DataType, toIdentifier: DataType) -> (from: (section: Int, item: Int), to: (section: Int, item: Int))? {
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
	public func moveItem(_ identifier: DataType, beforeItem beforeIdentifier: DataType) -> _CollectionViewReloadHandler {
		guard let (from, to) = moveItem(identifier, toIdentifier: beforeIdentifier) else {
			return reloadHandler
		}
		
		sections[to.section].items.insert(sections[from.section].items.remove(at: from.item), at: to.item)
		return reloadHandler.commit()
	}
	
	@inlinable
	@discardableResult
	public func moveItem(_ identifier: DataType, afterItem afterIdentifier: DataType) -> _CollectionViewReloadHandler {
		guard let (from, to) = moveItem(identifier, toIdentifier: afterIdentifier) else {
			return reloadHandler
		}
		
		sections[to.section].items.insert(sections[from.section].items.remove(at: from.item), at: to.item+1)
		return reloadHandler.commit()
	}
	
	@inlinable
	@discardableResult
	public func reloadItems(_ identifiers: [DataType]) -> _CollectionViewReloadHandler {
		func _filter() -> (indexPaths: [IndexPath], ids: [DataType]) {
			var identifiersSet = Set(identifiers)
			
			var indexPaths = [IndexPath]()
			var ids = [DataType]()
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
			
			let reload = _CollectionViewReloadHandler()
			collectionView?.reloadHandlers.append(reload)
			reload._reload = { [weak collectionView] animatingDifferences, completion in
				var snap = diff.snapshot()
				snap.reloadItems(result.ids)
				diff.apply(snap, animatingDifferences: animatingDifferences, completion: completion)
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
			
			let reload = _CollectionViewReloadHandler()
			collectionView?.reloadHandlers.append(reload)
			reload._reload = { [weak collectionView] animatingDifferences, completion in
				UIView.animate(withDuration: 0, animations: {
					collectionView?.reloadItems(at: result.indexPaths)
				}, completion: { _ in
					completion?()
					collectionView?.reloadHandlers.removeAll {
						ObjectIdentifier($0) == ObjectIdentifier(reload)
					}
				})
			}
			return reload
		}
	}
	
	@inlinable
	public func contains(_ item: DataType) -> Bool {
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
	public func append(childItems: [DataType], to parent: DataType) -> _CollectionViewReloadHandler {
		
		let itemsUnique = childItems.unique()
		filterAddingItem(set: itemsUnique.set)
		
		useDiffDataSource = true
		func find(item: CollectionView.ItemData<DataType>) -> CollectionView.ItemData<DataType>? {
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
	public func expand(parents: [DataType]) -> _CollectionViewReloadHandler {
		
		guard let diff = diffDataSource else { return reloadHandler }
		collectionView?.forceReload()
		let reload = _CollectionViewReloadHandler()
		collectionView?.reloadHandlers.append(reload)
		reload._reload = { [weak collectionView] animatingDifferences, completion in
			var _completion: (() -> Void)? = {
				completion?()
				collectionView?.reloadHandlers.removeAll {
					ObjectIdentifier($0) == ObjectIdentifier(reload)
				}
			}
			for section in self.sections {
				var snapshot = diff.snapshot(for: section.section)
				snapshot.expand(parents)
				diff.apply(snapshot, to: section.section, animatingDifferences: animatingDifferences, completion: _completion)
				_completion = nil
			}
		}
		return reload.commit()
	}
	
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	@discardableResult
	public func collapse(parents: [DataType]) -> _CollectionViewReloadHandler {
		
		guard let diff = diffDataSource else { return reloadHandler }
		collectionView?.forceReload()
		let reload = _CollectionViewReloadHandler()
		collectionView?.reloadHandlers.append(reload)
		reload._reload = { [weak collectionView] animatingDifferences, completion in
			var _completion: (() -> Void)? = {
				completion?()
				collectionView?.reloadHandlers.removeAll {
					ObjectIdentifier($0) == ObjectIdentifier(reload)
				}
			}
			for section in self.sections {
				var snapshot = diff.snapshot(for: section.section)
				snapshot.collapse(parents)
				diff.apply(snapshot, to: section.section, animatingDifferences: animatingDifferences, completion: _completion)
				_completion = nil
			}
		}
		return reload.commit()
	}
	
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	public func isExpanded(_ item: DataType) -> Bool {
		guard let diff = diffDataSource else { return false }
		collectionView?.forceReload()
		return sections.contains {
			diff.snapshot(for: $0.section).isExpanded(item)
		}
	}
	// level 是从0开始
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	public func level(of item: DataType) -> Int {
		guard let diff = diffDataSource else { return 0 }
		collectionView?.forceReload()
		return sections.map {
			diff.snapshot(for: $0.section).level(of: item)
		}.max() ?? 0
	}
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	public func parent(of child: DataType) -> DataType? {
		
		guard let diff = diffDataSource else { return nil }
		collectionView?.forceReload()
		for section in sections {
			let snapshot = diff.snapshot(for: section.section)
			if let parent = snapshot.parent(of: child) {
				return parent
			}
		}
		return nil
	}

	@available(iOS 14.0, *)
	@inlinable
	public func visibleItems() -> [DataType] {
		guard let diff = diffDataSource else {
			return sections.flatMap {
				$0.items.map {
					$0.base
				}
			}
		}
		collectionView?.forceReload()
		return sections.flatMap {
			diff.snapshot(for: $0.section).visibleItems
		}
	}
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	public func visibleItems<SectionIdentifierType>(inSection identifier: SectionIdentifierType) -> [DataType]? where SectionIdentifierType : Hashable {
		guard let diff = diffDataSource else {
			return sections.first {
				$0.section == identifier
			}?.items.map {
				$0.base
			}
		}
		collectionView?.forceReload()
		return sections.first {
			$0.section == identifier
		}.map {
			diff.snapshot(for: $0.section).visibleItems
		}
	}
	
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	public func visibleItems(atSection index: Int) -> [DataType]? {
		guard index < sections.count else {
			return nil
		}
		guard let diff = diffDataSource else {
			return sections[index].items.map {
				$0.base
			}
		}
		collectionView?.forceReload()
		return diff.snapshot(for: sections[index].section).visibleItems
	}
	
	// item 找不到会crash
	// 'NSInternalInconsistencyException', reason: 'Invalid parameter not satisfying: index != NSNotFound'
	@available(iOS 14.0, *)
	@inlinable
	public func isVisible(_ item: DataType) -> Bool {
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
		collectionView?.forceReload()
		return sections.contains {
			diff.snapshot(for: $0.section).isVisible(item)
		}
	}
	
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	public func rootItems() -> [DataType] {
		sections.flatMap {
			$0.items.map {
				$0.base
			}
		}
	}
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	public func rootItems<SectionIdentifierType>(inSection identifier: SectionIdentifierType) -> [DataType]? where SectionIdentifierType : Hashable {
		sections.first {
			$0.section == identifier
		}?.items.map {
			$0.base
		}
	}
	
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	public func rootItems(atSection index: Int) -> [DataType]? {
		guard index < sections.count else {
			return nil
		}
		return sections[index].items.map {
			$0.base
		}
	}
}
// MARK: - DataManager DataType == AnyHashable
extension CollectionView.DataManager where DataType == CollectionView.AnyHashable {
	@usableFromInline
	func filterAddingItem<ItemIdentifierType>(set: Set<ItemIdentifierType>)  where ItemIdentifierType: Hashable {
		var set = set
		var sectionIndex = sections.count-1
		var itemIndex = 0
		while sectionIndex >= 0 {
			itemIndex = sections[sectionIndex].items.count-1
			while itemIndex >= 0  {
				if let item = sections[sectionIndex].items[itemIndex].base.base as? ItemIdentifierType, !set.insert(item).inserted {
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
	public func apply<ItemIdentifierType>(_ datas: [ItemIdentifierType]) -> _CollectionViewReloadHandler where ItemIdentifierType: Hashable {
		sections = [.init(sectionIdentifier: 0, items: datas.map {
			.init($0)
		})]
		return reloadHandler.commit()
	}
	@inlinable
	@discardableResult
	public func apply<ItemIdentifierType, SectionIdentifierType>(_ datas: [ItemIdentifierType], toSection sectionIdentifier: SectionIdentifierType) -> _CollectionViewReloadHandler where ItemIdentifierType: Hashable, SectionIdentifierType: Hashable {
		sections = [.init(sectionIdentifier: sectionIdentifier, items: datas.map{
			.init($0)
		})]
		
		return reloadHandler.commit()
	}

	@inlinable
	@discardableResult
	public func apply<ItemIdentifierType>(_ sections: [[ItemIdentifierType]]) -> _CollectionViewReloadHandler where ItemIdentifierType: Hashable {
		self.sections = sections.enumerated().map {
			.init(sectionIdentifier: $0.offset, items: $0.element.map{
				.init($0)
			})
		}
		
		return reloadHandler.commit()
	}
	@inlinable
	public func itemIdentifier<ItemIdentifierType>(for indexPath: IndexPath) -> ItemIdentifierType? where ItemIdentifierType : Hashable {
		element(for: indexPath) as? ItemIdentifierType
	}
	
	@inlinable
	public func indexPath<ItemIdentifierType>(for itemIdentifier: ItemIdentifierType) -> IndexPath? where ItemIdentifierType : Hashable {
		if #available(iOS 13.0, *), let diff = diffDataSource {
			collectionView?.forceReload()
			return diff.indexPath(for: .init(itemIdentifier))
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
	public func append<ItemIdentifierType, SectionIdentifierType>(_ items: [ItemIdentifierType], toSection sectionIdentifier: SectionIdentifierType) -> _CollectionViewReloadHandler where ItemIdentifierType: Hashable, SectionIdentifierType: Hashable {
		guard !sections.isEmpty else {
			assertionFailure("There are currently no sections in the data source. Please add a section first.")
			return reloadHandler
		}
		
		guard let sectionIndex = sections.firstIndex(where: {
			$0.section == sectionIdentifier
		}) else {
			assertionFailure("Invalid parameter not satisfying: section != NSNotFound")
			return reloadHandler
		}
		
		let itemUnique = items.unique()
		filterAddingItem(set: itemUnique.set)
		
		sections[sectionIndex].items.append(contentsOf: itemUnique.array.map {
			.init(.init($0))
		})
		return reloadHandler.commit()
	}
	@inlinable
	@discardableResult
	public func append<ItemIdentifierType>(_ items: [ItemIdentifierType]) -> _CollectionViewReloadHandler where ItemIdentifierType: Hashable {
		guard !sections.isEmpty else {
			assertionFailure("There are currently no sections in the data source. Please add a section first.")
			return reloadHandler
		}
		
		let itemUnique = items.unique()
		filterAddingItem(set: itemUnique.set)
		
		sections[sections.count-1].items.append(contentsOf: itemUnique.array.map {
			.init(.init($0))
		})
		return reloadHandler.commit()
	}
	
	@inlinable
	@inline(__always)
	func insertItems<ItemIdentifierType>(identifier: ItemIdentifierType) -> (section: Int, item: Int)? where ItemIdentifierType: Hashable {
		var sectionIndex = 0
		var itemIndex = 0
		while sectionIndex < sections.count {
			itemIndex = 0
			while itemIndex < sections[sectionIndex].items.count {
				if let item = sections[sectionIndex].items[itemIndex].base.base as? ItemIdentifierType, item == identifier {
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
	public func insertItems<InsertType, BeforeType>(_ identifiers: [InsertType], beforeItem beforeIdentifier: BeforeType) -> _CollectionViewReloadHandler where InsertType: Hashable, BeforeType: Hashable {
		guard let result = insertItems(identifier: beforeIdentifier) else {
			return reloadHandler
		}
		
		let itemsUnique = identifiers.unique()
		filterAddingItem(set: itemsUnique.set)
		
		sections[result.section].items.insert(contentsOf: itemsUnique.array.map {
			.init(.init($0))
		}, at: result.item)
		
		return reloadHandler.commit()
	}
	// TODO:    得测试一下NSDiffableDataSourceSnapshot找不到的话会怎么样
	@inlinable
	@discardableResult
	public func insertItems<InsertType, AfterType>(_ identifiers: [InsertType], afterItem afterIdentifier: AfterType) -> _CollectionViewReloadHandler where InsertType: Hashable, AfterType: Hashable {
		guard let result = insertItems(identifier: afterIdentifier) else {
			return reloadHandler
		}
		
		let itemsUnique = identifiers.unique()
		filterAddingItem(set: itemsUnique.set)
		
		sections[result.section].items.insert(contentsOf: itemsUnique.array.map {
			.init(.init($0))
		}, at: result.item + 1)
		
		return reloadHandler.commit()
	}
	
	@inlinable
	public func allItems<ItemIdentifierType>() -> [ItemIdentifierType] where ItemIdentifierType: Hashable{
		sections.flatMap {
			$0.items.flatMap {
				$0.allItems.compactMap {
					$0.base as? ItemIdentifierType
				}
			}
		}
	}
	@inlinable
	public func allItems<ItemIdentifierType, SectionIdentifierType>(inSection identifier: SectionIdentifierType) -> [ItemIdentifierType]? where ItemIdentifierType: Hashable, SectionIdentifierType: Hashable {
		sections.first {
			$0.section == identifier
		}?.items.flatMap {
			$0.allItems.compactMap {
				$0.base as? ItemIdentifierType
			}
		}
	}
	@inlinable
	public func allItems<ItemIdentifierType>(atSectionIndex index: Int) -> [ItemIdentifierType]? where ItemIdentifierType: Hashable {
		if index < sections.count {
			return sections[index].items.flatMap {
				$0.allItems.compactMap {
					$0.base as? ItemIdentifierType
				}
			}
		}
		
		return nil
	}

	@inlinable
	public func sectionIdentifier<ItemIdentifierType, SectionIdentifierType>(containingItem identifier: ItemIdentifierType) -> SectionIdentifierType? where ItemIdentifierType: Hashable , SectionIdentifierType: Hashable {
		for section in sections {
			if section.items.contains(where: {
				$0.contains(identifier)
			}) {
				return section.section.base as? SectionIdentifierType
			}
		}
		return nil
	}
	@inlinable
	@discardableResult
	public func deleteItems<ItemIdentifierType>(_ identifiers: [ItemIdentifierType]) -> _CollectionViewReloadHandler where ItemIdentifierType: Hashable {
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
	func moveItem<MovedType, BeforeType>(_ identifier: MovedType, toIdentifier: BeforeType) -> (from: (section: Int, item: Int), to: (section: Int, item: Int))? where MovedType: Hashable, BeforeType: Hashable {
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
	public func moveItem<MovedType, BeforeType>(_ identifier: MovedType, beforeItem beforeIdentifier: BeforeType) -> _CollectionViewReloadHandler where MovedType: Hashable, BeforeType: Hashable {
		guard let (from, to) = moveItem(identifier, toIdentifier: beforeIdentifier) else {
			return reloadHandler
		}
		
		sections[to.section].items.insert(sections[from.section].items.remove(at: from.item), at: to.item)
		return reloadHandler.commit()
	}
	@inlinable
	@discardableResult
	public func moveItem<MovedType, AfterType>(_ identifier: MovedType, afterItem afterIdentifier: AfterType) -> _CollectionViewReloadHandler where MovedType: Hashable, AfterType: Hashable {
		guard let (from, to) = moveItem(identifier, toIdentifier: afterIdentifier) else {
			return reloadHandler
		}
		
		sections[to.section].items.insert(sections[from.section].items.remove(at: from.item), at: to.item+1)
		return reloadHandler.commit()
	}
	
	// TODO:    测试一下NSDiffableDataSourceSnapshot.reloadItems有什么用
	@inlinable
	@discardableResult
	public func reloadItems<ItemIdentifierType>(_ identifiers: [ItemIdentifierType]) -> _CollectionViewReloadHandler where ItemIdentifierType: Hashable {
		func _filter() -> (indexPaths: [IndexPath], ids: [ItemIdentifierType]) {
			var identifiersSet = Set(identifiers)
			
			var indexPaths = [IndexPath]()
			var ids = [ItemIdentifierType]()
			for (sectionIndex, element) in sections.enumerated() {
				for (itemIndex, element) in element.items.enumerated() {
					if let item = element.base.base as? ItemIdentifierType, identifiersSet.insert(item).inserted {
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
			
			let reload = _CollectionViewReloadHandler()
			collectionView?.reloadHandlers.append(reload)
			reload._reload = { [weak collectionView] animatingDifferences, completion in
				var snap = diff.snapshot()
				snap.reloadItems(result.ids.map {
					.init($0)
				})
				diff.apply(snap, animatingDifferences: animatingDifferences, completion: completion)
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
			
			let reload = _CollectionViewReloadHandler()
			collectionView?.reloadHandlers.append(reload)
			reload._reload = { [weak collectionView] animatingDifferences, completion in
				UIView.animate(withDuration: 0, animations: {
					collectionView?.reloadItems(at: result.indexPaths)
				}, completion: { _ in
					completion?()
					collectionView?.reloadHandlers.removeAll {
						ObjectIdentifier($0) == ObjectIdentifier(reload)
					}
				})
			}
			return reload
		}
	}
	
	@inlinable
	public func contains<ItemIdentifierType>(_ item: ItemIdentifierType) -> Bool where ItemIdentifierType : Hashable {
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
	public func append<ChildType, ParentType>(_ childItems: [ChildType], to parent: ParentType) -> _CollectionViewReloadHandler where ChildType: Hashable, ParentType: Hashable {
		
		let itemsUnique = childItems.unique()
		filterAddingItem(set: itemsUnique.set)
		
		useDiffDataSource = true
		func find(item: CollectionView.ItemData<DataType>) -> CollectionView.ItemData<DataType>? {
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
							.init(.init($0))
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
	public func expand<ParentType>(parents: [ParentType]) -> _CollectionViewReloadHandler where ParentType: Hashable {
		
		guard let diff = diffDataSource else { return reloadHandler }
		collectionView?.forceReload()
		let reload = _CollectionViewReloadHandler()
		collectionView?.reloadHandlers.append(reload)
		reload._reload = { [weak collectionView] animatingDifferences, completion in
			var _completion: (() -> Void)? = {
				completion?()
				collectionView?.reloadHandlers.removeAll {
					ObjectIdentifier($0) == ObjectIdentifier(reload)
				}
			}
			for section in self.sections {
				var snapshot = diff.snapshot(for: section.section)
				snapshot.expand(parents.map {
					.init($0)
				})
				diff.apply(snapshot, to: section.section, animatingDifferences: animatingDifferences, completion: _completion)
				_completion = nil
			}
		}
		return reload.commit()
	}
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	@discardableResult
	public func collapse<ParentType>(parents: [ParentType]) -> _CollectionViewReloadHandler where ParentType: Hashable {
		
		guard let diff = diffDataSource else { return reloadHandler }
		collectionView?.forceReload()
		let reload = _CollectionViewReloadHandler()
		collectionView?.reloadHandlers.append(reload)
		reload._reload = { [weak collectionView] animatingDifferences, completion in
			var _completion: (() -> Void)? = {
				completion?()
				collectionView?.reloadHandlers.removeAll {
					ObjectIdentifier($0) == ObjectIdentifier(reload)
				}
			}
			for section in self.sections {
				var snapshot = diff.snapshot(for: section.section)
				snapshot.collapse(parents.map {
					.init($0)
				})
				diff.apply(snapshot, to: section.section, animatingDifferences: animatingDifferences, completion: _completion)
				_completion = nil
			}
		}
		return reload.commit()
	}

	
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	public func isExpanded<ParentType>(_ item: ParentType) -> Bool where ParentType: Hashable {
		guard let diff = diffDataSource else { return false }
		collectionView?.forceReload()
		return sections.contains {
			diff.snapshot(for: $0.section).isExpanded(.init(item))
		}
	}
	
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	public func level<ItemIdentifierType>(of item: ItemIdentifierType) -> Int where ItemIdentifierType: Hashable {
		guard let diff = diffDataSource else { return 0 }
		collectionView?.forceReload()
		return sections.map {
			diff.snapshot(for: $0.section).level(of: .init(item))
		}.max() ?? 0
	}
	
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	public func parent<ChildType, ParentType>(of child: ChildType) -> ParentType? where ChildType: Hashable, ParentType: Hashable {
		guard let diff = diffDataSource else { return nil }
		collectionView?.forceReload()
		for section in sections {
			let snapshot = diff.snapshot(for: section.section)
			if let parent = snapshot.parent(of: .init(child)) as? ParentType {
				return parent
			}
		}
		return nil
	}
	
	@available(iOS 14.0, *)
	@inlinable
	public func visibleItems<ItemIdentifierType>() -> [ItemIdentifierType] where ItemIdentifierType: Hashable {
		guard let diff = diffDataSource else {
			return sections.flatMap {
				$0.items.compactMap({
					$0.base as? ItemIdentifierType
				})
			}
		}
		collectionView?.forceReload()
		return sections.flatMap {
			diff.snapshot(for: $0.section).visibleItems.compactMap {
				$0.base as? ItemIdentifierType
			}
		}
	}
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	public func visibleItems<ItemIdentifierType, SectionIdentifierType>(inSection identifier: SectionIdentifierType) -> [ItemIdentifierType]? where ItemIdentifierType: Hashable, SectionIdentifierType : Hashable {
		guard let diff = diffDataSource else {
			return sections.first {
				$0.section == identifier
			}?.items.compactMap {
				$0.base.base as? ItemIdentifierType
			}
		}
		collectionView?.forceReload()
		return sections.first {
			$0.section == identifier
		}.map {
			diff.snapshot(for: $0.section).visibleItems.compactMap {
				$0.base as? ItemIdentifierType
			}
		}
	}
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	public func visibleItems<ItemIdentifierType>(atSection index: Int) -> [ItemIdentifierType]? where ItemIdentifierType: Hashable {
		guard index < sections.count else {
			return nil
		}
		guard let diff = diffDataSource else {
			return sections[index].items.compactMap {
				$0.base.base as? ItemIdentifierType
			}
		}
		collectionView?.forceReload()
		return diff.snapshot(for: sections[index].section).visibleItems.compactMap {
			$0.base as? ItemIdentifierType
		}
	}
	
	@available(iOS 14.0, *)
	@inlinable
	public func isVisible<ItemIdentifierType>(_ item: ItemIdentifierType) -> Bool where ItemIdentifierType: Hashable {
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
		collectionView?.forceReload()
		return sections.contains {
			diff.snapshot(for: $0.section).isVisible(.init(item))
		}
	}
	
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	public func rootItems<ItemIdentifierType>() -> [ItemIdentifierType] where ItemIdentifierType: Hashable {
		sections.flatMap {
			$0.items.compactMap {
				$0.base.base as? ItemIdentifierType
			}
		}
	}
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	public func rootItems<ItemIdentifierType, SectionIdentifierType>(inSection identifier: SectionIdentifierType) -> [ItemIdentifierType]? where ItemIdentifierType: Hashable, SectionIdentifierType: Hashable {
		sections.first {
			$0.section == identifier
		}?.items.compactMap {
			$0.base.base as? ItemIdentifierType
		}
	}
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	public func rootItems<ItemIdentifierType>(atSectionIndex index: Int) -> [ItemIdentifierType]? where ItemIdentifierType: Hashable {
		guard index < sections.count else {
			return nil
		}
		return sections[index].items.compactMap {
			$0.base.base as? ItemIdentifierType
		}
	}
}
