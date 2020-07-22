//
//  DataSourceBase.swift
//  ConfigableCollectionView
//
//  Created by 庄黛淳华 on 2020/7/12.
//

import UIKit

extension CollectionView {
	@usableFromInline
	struct SectionData<ItemType> {
		@usableFromInline
		let section: AnyHashable
		@usableFromInline
		var items: [ItemData<ItemType>]
		@usableFromInline
		init<SectionIdentifierType>(sectionIdentifier: SectionIdentifierType, items: [ItemType] = []) where SectionIdentifierType: Hashable {
			self.section = AnyHashable(sectionIdentifier)
			self.items = items.map({
				ItemData($0)
			})
		}
		@usableFromInline
		init(anySectionIdentifier: AnyHashable) {
			self.section = anySectionIdentifier
			self.items = []
		}
	}
	@usableFromInline
	class ItemData<BaseType> {
		@usableFromInline
		let base: BaseType
		@usableFromInline
		init(_ base: BaseType) {
			self.base = base
		}
		@usableFromInline
		var subItems: [ItemData] = []
		@usableFromInline
		var allItems: [BaseType] {
			var result = [base]
			for sub in subItems {
				result.append(contentsOf: sub.allItems)
			}
			return result
		}
		@usableFromInline
		func contains<ItemIdentifierType>(_ value: ItemIdentifierType) -> Bool where ItemIdentifierType: Hashable {
			if let base = base as? AnyHashable {
				if base == value {
					return true
				}
			} else if (base as? ItemIdentifierType) == value {
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
		func removeAllSubItems<ItemIdentifierType>(_ value: ItemIdentifierType) where ItemIdentifierType: Hashable {
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
					if (item.base as? ItemIdentifierType) == value {
						subItems.remove(at: index)
					} else {
						item.removeAllSubItems(value)
					}
				}
				index -= 1
			}
		}
	}
	class DataSourceBase<DataType>: NSObject, UICollectionViewDataSource {
		var sections = [SectionData<DataType>]()
		weak var _collectionView: CollectionView?
		
		init(collectionView: CollectionView) {
			_collectionView = collectionView
			collectionView.reloadHandlers.first?._reload = { [weak collectionView] animatingDifferences, completion in
				UIView.animate(withDuration: 0, animations: {
					collectionView?.reloadData()
				}, completion: { _ in
					completion?()
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
