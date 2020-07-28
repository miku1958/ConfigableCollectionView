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


// apply是覆盖, 当提供的sectionIdentifier找不到时则添加到末尾, 除此之外会覆盖所有数据
// append是添加, 所以需要sectionIdentifier
protocol CollectionViewDataManager {
	var lastIndexPath: IndexPath? { get }
	func element(for indexPath: IndexPath) -> Any?
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
		var _baseDataSource: UICollectionViewDataSource?
		
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
		collectionView?.reloadHandler._baseReload = { [weak collectionView] animatingDifferences, completion in
			guard let collectionView = collectionView else {
				return
			}
			
			let dataManager = collectionView._dataManager as! Self
			#if swift(>=5.3)
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
				return
			}
			#endif
			if #available(iOS 13.0, *) {
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
		var itemCount = 0
		var section = numberOfSections
		if #available(iOS 14.0, *), useDiffDataSource {
			reloadHandler.reloadImmediately()
		}
		while itemCount == 0 {
			section -= 1
			guard section >= 0 else {
				return nil
			}
			if #available(iOS 14.0, *), useDiffDataSource, let diffDataSource = diffDataSource {
				itemCount = diffDataSource.snapshot(for: sections[section].section()).visibleItems.count
			} else {
				itemCount = numberOfRootItems(atSectionIndex: section)
			}
		}
		guard itemCount > 0 else {
			return nil
		}
		return IndexPath(item: itemCount-1, section: section)
	}
	@inlinable
	@inline(__always)
	func element(for indexPath: IndexPath) -> Any? {
		guard indexPath.item >= 0, indexPath.section >= 0, indexPath.section < sections.count else {
			return nil
		}
		var item: Any?
		if #available(iOS 13.0, *), let diffDataSource = diffDataSource {
			item = diffDataSource.itemIdentifier(for: indexPath)
		}
		if item == nil, indexPath.item < sections[indexPath.section].items.count {
			item = sections[indexPath.section].items[indexPath.item].base
		}
		if let item = item as? CollectionView.AnyHashable {
			return item.base
		} else {
			return item
		}
	}
	
	
	@inline(__always)
	func prepareBaseDataSource() -> UICollectionViewDataSource? {
		guard let collectionView = collectionView else {
			return nil
		}
		_baseDataSource = CollectionView.BaseDataSource<SectionIdentifier, ItemIdentifier>(collectionView: collectionView)
		return _baseDataSource
	}
	@available(iOS 13.0, *)
	@inline(__always)
	func prepareDiffDataSource() {
		guard let collectionView = collectionView else {
			return
		}
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
	
	@usableFromInline
	@inline(__always)
	func prepareDatasource() -> UICollectionViewDataSource? {
		if #available(iOS 13.0, *) {
			if _diffDataSource == nil {
				prepareDiffDataSource()
			}
			return diffDataSource
		} else {
			return prepareBaseDataSource()
		}
	}
}

extension CollectionView.DataManager: CollectionViewDataManager {
	@usableFromInline
	@inline(__always)
	var reloadHandler: ReloadHandler {
		collectionView?.reloadHandler ?? .init()
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
	public var numberOfRootItems: Int {
		sections.reduce(0) {
			$0 + $1.items.count
		}
	}
	
	@inlinable
	public func numberOfRootItems(atSectionIndex index: Int) -> Int {
		if index >= 0, index < sections.count {
			return sections[index].items.count
		} else {
			return 0
		}
	}
	
	@inlinable
	@discardableResult
	public func deleteAllItems() -> ReloadHandler {
		sections.removeAll()
		useDiffDataSource = false
		if #available(iOS 13.0, *), let diffDataSource = diffDataSource {
			return reloadHandler.commit(temporaryReload: { animatingDifferences, completion in
				diffDataSource.apply(.init(), animatingDifferences: animatingDifferences, completion: completion.call)
			})
		}
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
		guard index >= 0, index < sections.count else {
			return reloadHandler
		}
		sections[index].items.reverse()
		return reloadHandler.commit()
	}
}

// MARK: - 13, SectionType: Hashable
@available(iOS 13.0, *)
extension CollectionView.DataManager where SectionType: Hashable {
	public var diffableDataSource: DiffDataSource {
		diffDataSource!
	}
}
