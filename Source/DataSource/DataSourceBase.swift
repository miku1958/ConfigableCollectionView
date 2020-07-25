//
//  DataSourceBase.swift
//  ConfigableCollectionView
//
//  Created by 庄黛淳华 on 2020/7/12.
//

import UIKit

extension CollectionView {
	@usableFromInline
	struct SectionData<ItemIdentifier> {
		@usableFromInline
		let anySection: AnyHashable
		
		@inline(__always)
		@usableFromInline
		func section<Section>() -> Section {
			if let section = anySection as? Section {
				return section
			} else if let section = anySection.base as? Section {
				return section
			} else {
				fatalError("wtf are you doing")
			}
		}
		@inline(__always)
		@usableFromInline
		func trySection<Section>() -> Section? {
			anySection.base as? Section
		}
		@usableFromInline
		var items: [ItemData<ItemIdentifier>]
		@usableFromInline
		init<Section>(sectionIdentifier: Section, items: [ItemIdentifier] = []) where Section: Hashable {
			self.anySection = .package(sectionIdentifier)
			self.items = items.map({
				ItemData($0)
			})
		}
		@usableFromInline
		init(anySectionIdentifier: AnyHashable) {
			self.anySection = anySectionIdentifier
			self.items = []
		}
	}
	@usableFromInline
	class ItemData<ItemIdentifier> {
		@usableFromInline
		let base: ItemIdentifier
		@usableFromInline
		init(_ base: ItemIdentifier) {
			self.base = base
		}
		@usableFromInline
		var subItems: [ItemData] = []
		@usableFromInline
		var allItems: [ItemIdentifier] {
			var result = [base]
			for sub in subItems {
				result.append(contentsOf: sub.allItems)
			}
			return result
		}
		@usableFromInline
		func contains<Item>(_ value: Item) -> Bool where Item: Hashable {
			if let base = base as? AnyHashable {
				if base == value {
					return true
				}
			} else if (base as? Item) == value {
				return true
			}
			
			for item in subItems {
				if item.contains(value) {
					return true
				}
			}
			return false
		}
		@usableFromInline
		func removeAllSubItems<Item>(_ value: Item) where Item: Hashable {
			var index = subItems.count-1
			while index >= 0 {
				let item = subItems[index]
				if let base = item.base as? AnyHashable {
					if base == value {
						subItems.remove(at: index)
					} else {
						item.removeAllSubItems(value)
					}
				} else {
					if (item.base as? Item) == value {
						subItems.remove(at: index)
					} else {
						item.removeAllSubItems(value)
					}
				}
				index -= 1
			}
		}
	}
	
	class DataSourceBase<SectionIdentifier, ItemIdentifier>: NSObject, UICollectionViewDataSource where SectionIdentifier: Hashable, ItemIdentifier: Hashable {
        var sections: [SectionData<ItemIdentifier>] {
            guard let dataManager = _collectionView?._dataManager as? DataManager<SectionIdentifier, ItemIdentifier> else { return [] }
            return dataManager.sections
        }
		weak var _collectionView: CollectionView?
		
		init(collectionView: CollectionView) {
			_collectionView = collectionView
			collectionView.reloadHandlers.first?._reload = { [weak collectionView] animatingDifferences, completion in
				UIView.animate(withDuration: 0, animations: {
					collectionView?.reloadData()
				}, completion: { _ in
                    completion.call()
				})
			}
		}
		
		func numberOfSections(in collectionView: UICollectionView) -> Int {
			sections.count
		}
		func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
			sections[section].items.count
		}
		
		func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
			_collectionView?.cell(at: indexPath, item: nil) ?? collectionView.dequeueReusableCell(withReuseIdentifier: "empty", for: indexPath)
		}
	}
}
