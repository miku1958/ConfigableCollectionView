//
//  DataManager_Generic_Implementation.swift
//  ConfigableCollectionView
//
//  Created by 庄黛淳华 on 2020/7/26.
//

import Foundation

// MARK: - _items
extension CollectionView.DataManager {
	@inlinable
	@inline(__always)
	func _numberOfItems<Section>(inSection identifier: Section) -> Int where Section: Hashable {
		sections.first {
			$0.anySection == identifier
		}?.items.count ?? 0
	}
	@inlinable
	@inline(__always)
	func _reverseRootItems<Section>(inSection identifier: Section) -> ReloadHandler where Section: Hashable {
		if let index = sections.firstIndex(where: {
			$0.anySection == identifier
		}) {
			sections[index].items.reverse()
		}
		
		return reloadHandler.commit()
	}
	
	@inlinable
	@inline(__always)
	func filterAddingItem<Item>(set: Set<Item>) where Item: Hashable {
		var set = set
		var sectionIndex = sections.count-1
		var itemIndex = 0
		while sectionIndex >= 0 {
			itemIndex = sections[sectionIndex].items.count-1
			while itemIndex >= 0  {
				if let item = sections[sectionIndex].items[itemIndex].tryBase() as Item?, !set.insert(item).inserted {
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
	@inline(__always)
	func _indexPath(for itemIdentifier: ItemIdentifier) -> IndexPath? {
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
	
	// 找不到 beforeIdentifier 的话会crash
	// 'NSInternalInconsistencyException', reason: 'Invalid parameter not satisfying: section != NSNotFound'
	@inlinable
	@inline(__always)
	func _insertItems<Item, To>(_ identifiers: [Item], to: To, indexOffset: Int, map: (Item) -> CollectionView.ItemData<ItemIdentifier>) -> ReloadHandler where Item: Hashable, To: Hashable {
		func filter() -> (section: Int, item: Int)? {
			var sectionIndex = 0
			var itemIndex = 0
			while sectionIndex < sections.count {
				itemIndex = 0
				while itemIndex < sections[sectionIndex].items.count {
					if sections[sectionIndex].items[itemIndex].tryBase() == to {
						return (sectionIndex, itemIndex)
					}
					itemIndex += 1
				}
				sectionIndex += 1
			}
			assertionFailure("Invalid parameter not satisfying: section != NSNotFound")
			return nil
		}
		guard let result = filter() else {
			return reloadHandler
		}
		let itemsUnique = identifiers.unique()
		filterAddingItem(set: itemsUnique.set)
		
		sections[result.section].items.insert(contentsOf: itemsUnique.array.map(map), at: result.item+indexOffset)
		
		return reloadHandler.commit()
	}
	
	@inlinable
	@inline(__always)
	func _deleteItems<Item>(_ identifiers: [Item]) -> ReloadHandler where Item: Hashable {
		for identifier in identifiers {
			var section = 0
			while section < sections.count {
				var index = sections[section].items.count-1
				while section > 0 {
					let item = sections[section].items[index]
					if item.tryBase() == identifier {
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
	func _moveItem(_ identifier: ItemIdentifier, toIdentifier: ItemIdentifier) -> ReloadHandler {
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
					sections[to.section].items.insert(sections[from.section].items.remove(at: from.item), at: to.item)
					return reloadHandler.commit()
				}
				itemIndex += 1
			}
			sectionIndex += 1
		}
		assert(from != nil, "Invalid parameter not satisfying: fromIndex != NSNotFound")
		assert(to != nil, "Invalid parameter not satisfying: toIndex != NSNotFound")
		return reloadHandler
	}
	
	@inlinable
	@inline(__always)
	func _reloadItems<Item>(_ identifiers: [Item], map: (Item) -> ItemIdentifier) -> ReloadHandler where Item: Hashable {
		func filter() -> (indexPaths: [IndexPath], ids: [ItemIdentifier]) {
			var identifiersSet = Set(identifiers)
			
			var indexPaths = [IndexPath]()
			var ids = [ItemIdentifier]()
			for (sectionIndex, element) in sections.enumerated() {
				for (itemIndex, element) in element.items.enumerated() {
					if let item = element.tryBase() as Item?, identifiersSet.insert(item).inserted {
						indexPaths.append(IndexPath(item: itemIndex, section: sectionIndex))
						ids.append(map(item))
					}
				}
			}
			return (indexPaths, ids)
		}
		if #available(iOS 13.0, *) {
			guard let diff = diffDataSource else {
				return reloadHandler
			}
			
			let result = filter()
			
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
			
			let result = filter()
			
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
	// MARK: - append
	// NSDiffableDataSourceSnapshot 为空会crash
	// 'NSInternalInconsistencyException', reason: 'There are currently no sections in the data source. Please add a section first.'
	
	// 如果toSction找不到会crash
	// 'NSInternalInconsistencyException', reason: 'Invalid parameter not satisfying: section != NSNotFound'
	@inlinable
	@inline(__always)
	func _appendItems<Section, Item>(_ items: [Item], toSection sectionIdentifier: Section, map: (Item) -> CollectionView.ItemData<ItemIdentifier>) -> ReloadHandler where Item: Hashable, Section: Hashable {
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
			map($0)
		})
		return reloadHandler.commit()
	}
	
	@inlinable
	@inline(__always)
	func _appendItems<Item>(_ items: [Item], map: (Item) -> CollectionView.ItemData<ItemIdentifier>) -> ReloadHandler where Item: Hashable{
		guard !sections.isEmpty else {
			assertionFailure("There are currently no sections in the data source. Please add a section first.")
			return reloadHandler
		}
		
		let itemUnique = items.unique()
		filterAddingItem(set: itemUnique.set)
		
		sections[sections.count-1].items.append(contentsOf: itemUnique.array.map(map))
		return reloadHandler.commit()
	}
	
	@inlinable
	@inline(__always)
	func _contains<Item>(_ item: Item) -> Bool where Item : Hashable {
		sections.contains {
			$0.items.contains {
				$0.contains(item)
			}
		}
	}
	
	// MARK: - allItems
	@inlinable
	@inline(__always)
	func _allItems<Item>() -> [Item] where Item: Hashable{
		sections.flatMap {
			$0.items.flatMap {
				$0.allItems()
			}
		}
	}
	
	@inlinable
	@inline(__always)
	func _allItems<Item>(atSectionIndex index: Int) -> [Item]? where Item: Hashable {
		if index < sections.count {
			return sections[index].items.flatMap {
				$0.allItems()
			}
		}
		return nil
	}
	
	@inlinable
	@inline(__always)
	func _allItems<Section, Item>(inSection identifier: Section) -> [Item]? where Item: Hashable, Section: Hashable {
		sections.first {
			$0.anySection == identifier
		}?.items.flatMap {
			$0.allItems()
		}
	}
	#if swift(>=5.3)
	// MARK: - iOS14的内容
	@inlinable
	@inline(__always)
	func _appendChildItems<Child, Parent>(_ childItems: [Child], to parent: Parent, map: (Child) -> CollectionView.ItemData<ItemIdentifier>) -> ReloadHandler where Child: Hashable, Parent: Hashable {
		
		let itemsUnique = childItems.unique()
		filterAddingItem(set: itemsUnique.set)
		
		useDiffDataSource = true
		func find(item: CollectionView.ItemData<ItemIdentifier>) -> CollectionView.ItemData<ItemIdentifier>? {
			if item.tryBase() == parent {
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
						found.subItems.append(contentsOf: itemsUnique.array.map(map))
						return
					}
				}
			}
		}()
		return reloadHandler.commit()
	}
	
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	@inline(__always)
	func _expand(parents: [ItemIdentifier]) -> ReloadHandler {
		
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
	@inline(__always)
	func _collapse(parents: [ItemIdentifier]) -> ReloadHandler {
		
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
	@inline(__always)
	func _isExpanded(_ item: ItemIdentifier) -> Bool {
		guard let diff = diffDataSource else { return false }
		collectionView?.reloadImmediately()
		return sections.contains {
			diff.snapshot(for: $0.section()).isExpanded(item)
		}
	}
	
	// level 是从0开始
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	@inline(__always)
	func _level(of item: ItemIdentifier) -> Int {
		guard let diff = diffDataSource else { return 0 }
		collectionView?.reloadImmediately()
		return sections.map {
			diff.snapshot(for: $0.section()).level(of: item)
		}.max() ?? 0
	}
	
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	@inline(__always)
	func _parent<Parent>(of child: ItemIdentifier) -> Parent? where Parent: Hashable {
		guard let diff = diffDataSource else { return nil }
		collectionView?.reloadImmediately()
		for section in sections {
			guard
				let parent = diff.snapshot(for: section.section()).parent(of: child)
			else {
				continue
			}
			
			if let parent = parent as? CollectionView.AnyHashable {
				return parent.base as? Parent
			} else {
				return parent as? Parent
			}
		}
		return nil
	}
	
	// item 找不到会crash
	// 'NSInternalInconsistencyException', reason: 'Invalid parameter not satisfying: index != NSNotFound'
	@available(iOS 14.0, *)
	@inlinable
	@inline(__always)
	func _isVisible(_ item: ItemIdentifier) -> Bool {
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
	// MARK: - visibleItems
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	@inline(__always)
	func _visibleItems<Section, Item>(inSection identifier: Section, compactMap: ((ItemIdentifier) -> Item?)?) -> [Item]? where Item: Hashable, Section : Hashable {
		guard let diff = diffDataSource else {
			return sections.first {
				$0.anySection == identifier
			}?.items.compactMap {
				$0.tryBase()
			}
		}
		collectionView?.reloadImmediately()
		return sections.first {
			$0.anySection == identifier
		}.map {
			let items = diff.snapshot(for: $0.section()).visibleItems
			if let compactMap = compactMap {
				return items.compactMap(compactMap)
			} else {
				return items as! [Item]
			}
		}
	}
	@available(iOS 14.0, *)
	@inlinable
	@inline(__always)
	func _visibleItems<Item>(compactMap: ((ItemIdentifier) -> Item?)?) -> [Item] where Item: Hashable {
		guard let diff = diffDataSource else {
			return sections.flatMap {
				$0.items.compactMap({
					$0.tryBase()
				})
			}
		}
		collectionView?.reloadImmediately()
		func flatMap(items: [ItemIdentifier]) -> [Item] {
			if let compactMap = compactMap {
				return items.compactMap(compactMap)
			} else {
				return items as! [Item]
			}
		}
		return sections.flatMap {
			flatMap(items: diff.snapshot(for: $0.section()).visibleItems)
		}
	}
	@available(iOS 14.0, tvOS 14.0, *)
	@inlinable
	@inline(__always)
	func _visibleItems<Item>(atSection index: Int, compactMap: ((ItemIdentifier) -> Item?)?) -> [Item]? where Item: Hashable {
		guard index < sections.count else {
			return nil
		}
		guard let diff = diffDataSource else {
			return sections[index].items.compactMap {
				$0.tryBase()
			}
		}
		collectionView?.reloadImmediately()
		let items = diff.snapshot(for: sections[index].section()).visibleItems
		if let compactMap = compactMap {
			return items.compactMap(compactMap)
		} else {
			return items as? [Item]
		}
	}
	// MARK: - rootItems
	@inlinable
	@inline(__always)
	func _rootItems<Section, Item>(inSection identifier: Section) -> [Item]? where Item: Hashable, Section: Hashable {
		sections.first {
			$0.anySection == identifier
		}?.items.compactMap {
			$0.tryBase()
		}
	}
	@inlinable
	@inline(__always)
	func _rootItems<Item>() -> [Item] where Item: Hashable {
		sections.flatMap {
			$0.items.compactMap {
				$0.tryBase()
			}
		}
	}
	
	@inlinable
	@inline(__always)
	func _rootItems<Item>(atSectionIndex index: Int) -> [Item]? where Item: Hashable {
		guard index < sections.count else {
			return nil
		}
		return sections[index].items.compactMap {
			$0.tryBase()
		}
	}
	#endif
}
// MARK: - _Sections
extension CollectionView.DataManager {
	// 添加已有的section会crash
	// 'NSInternalInconsistencyException', reason: 'Section identifier count does not match data source count. This is most likely due to a hashing issue with the identifiers.'
	@inlinable
	@inline(__always)
	func _appendSections(new identifiers: [CollectionView.AnyHashable], to set: Set<CollectionView.AnyHashable>) -> ReloadHandler {
		var set = set
		sections.append(contentsOf: identifiers.filter {
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
	@inlinable
	@inline(__always)
	func _insertSections<Insert, To>(_ identifiers: [Insert], toIdentifier: To, indexOffset: Int)  -> ReloadHandler  where Insert: Hashable, To: Hashable {
		let itemsUnique = identifiers.unique().array.map({
			CollectionView.AnyHashable.package($0)
		})
		assert(identifiers.count == itemsUnique.count, "Fatal: supplied section identifiers are not unique.")
		guard let index = sections.firstIndex(where: {
			$0.anySection == toIdentifier
		}) else {
			assertionFailure("Invalid parameter not satisfying: insertIndex != NSNotFound")
			return reloadHandler
		}
		var existSectionSet = Set(sections.map {
			$0.anySection
		})
		let insertIdentifierUnique = itemsUnique.filter {
			existSectionSet.insert($0).inserted
		}
		assert(insertIdentifierUnique.count == itemsUnique.count, "Invalid update: destination for section operation \(itemsUnique.filter { !itemsUnique.contains($0) }) is in the inserted section list for update")
		
		sections.insert(contentsOf: itemsUnique.map({
			.init(anySectionIdentifier: $0)
		}), at: index+indexOffset)
		return reloadHandler.commit()
	}
	
	@inlinable
	@inline(__always)
	func _sectionIdentifiers<Section>() -> [Section] where Section: Hashable {
		sections.compactMap {
			$0.trySection()
		}
	}
	
	@inlinable
	@inline(__always)
	func _indexOfSection<Section>(_ identifier: Section) -> Int? where Section: Hashable {
		sections.firstIndex {
			$0.anySection == identifier
		}
	}
	
	@inlinable
	@inline(__always)
	func _deleteSections<Section>(_ identifiers: [Section]) -> ReloadHandler where Section: Hashable {
		sections.removeAll { item in
			identifiers.contains {
				item.anySection == $0
			}
		}
		
		return reloadHandler.commit()
	}
	
	// beforeSection找不到
	// 'NSInternalInconsistencyException', reason: 'Invalid parameter not satisfying: toSection != NSNotFound'
	
	// identifier 找不到
	// 'NSInternalInconsistencyException', reason: 'Invalid parameter not satisfying: fromSection != NSNotFound'
	@inlinable
	@inline(__always)
	func _moveSection<Moved, To>(_ identifier: Moved, toSection: To, indexOffset: Int) -> ReloadHandler where Moved: Hashable, To: Hashable {
		guard let movedIndex = sections.firstIndex(where: {
			$0.anySection == identifier
		}) else {
			assertionFailure("Invalid parameter not satisfying: fromSection != NSNotFound")
			return reloadHandler
		}
		guard let index = sections.firstIndex(where: {
			$0.anySection == toSection
		}) else {
			assertionFailure("Invalid parameter not satisfying: toSection != NSNotFound")
			return reloadHandler
		}
		
		sections.insert(sections.remove(at: movedIndex), at: index+indexOffset)
		return reloadHandler.commit()
	}
	
	// NSDiffableDataSourceSectionSnapshot 没有 reload
	// NSDiffableDataSourceSnapshot 的 reload 作用是: UICollectionViewDiffableDataSource 每次 apply 都会对比两次的 snapshot, 除了 hashValue 有变化的之外都不会 reload, 这个时候需要调用 NSDiffableDataSourceSnapshot 的 reload 标记 section/item 为强刷新, 否则即使创建一个新的 snapshot 也没法自动触发 reload
	
	// 如果 reload 的 identifiers 找不到会crash
	// 'NSInternalInconsistencyException', reason: 'Invalid section identifier for reload specified: Modern_Collection_Views.OutlineViewController.Section.next'
	@inlinable
	@inline(__always)
	func _reloadSections<Section>(_ identifiers: [Section]) -> ReloadHandler where Section: Hashable {
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
	
	@inlinable
	@inline(__always)
	func _sectionIdentifier<Section, Item>(containingItem identifier: Item) -> Section? where Item: Hashable , Section: Hashable {
		for section in sections {
			if section.items.contains(where: {
				$0.contains(identifier)
			}) {
				return section.trySection()
			}
		}
		return nil
	}
}

// MARK: - _apply
extension CollectionView.DataManager {
	@inlinable
	@inline(__always)
	func _applyItems<Item>(_ items: [Item], map: (Item) -> CollectionView.ItemData<ItemIdentifier>) -> ReloadHandler where Item: Hashable {
		sections = [.init(sectionIdentifier: UUID(), items: items.map(map))]
		return reloadHandler.commit()
	}
	
	@inlinable
	@inline(__always)
	func _applyItems<Section, Item>(_ items: [Item], updatedSection sectionIdentifier: Section, map: (Item) -> CollectionView.ItemData<ItemIdentifier>) -> ReloadHandler where Section: Hashable, Item: Hashable {
		if let index = sections.firstIndex(where: {
			$0.anySection == sectionIdentifier
		}) {
			sections[index].items = items.map(map)
		} else {
			sections.append(.init(sectionIdentifier: sectionIdentifier, items: items.map(map)))
		}
		return reloadHandler.commit()
	}
	@inlinable
	@inline(__always)
	func _applyItems<Item>(_ items: [Item], atSection index: Int, map: (Item) -> CollectionView.ItemData<ItemIdentifier>) -> ReloadHandler where Item: Hashable {
		guard index < sections.count else {
			return reloadHandler
		}
		sections[index].items = items.map(map)
		
		return reloadHandler.commit()
	}
	
	@inlinable
	@inline(__always)
	func _applySections<Item>(_ sections: [[Item]], map: (Item) -> CollectionView.ItemData<ItemIdentifier>) -> ReloadHandler where Item: Hashable {
		self.sections = sections.map {
			.init(sectionIdentifier: UUID(), items: $0.map(map))
		}
		
		return reloadHandler.commit()
	}
	@inlinable
	@inline(__always)
	func _applySections<Section, Item>(_ sections: [(section: Section, items: [Item])], map: (Item) -> CollectionView.ItemData<ItemIdentifier>) -> ReloadHandler where Section: Hashable, Item: Hashable {
		self.sections = sections.map { (section, items) in
			.init(sectionIdentifier: section, items: items.map(map))
		}
		
		return reloadHandler.commit()
	}
}
