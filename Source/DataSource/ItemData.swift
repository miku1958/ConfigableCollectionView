//
//  ItemData.swift
//  ConfigableCollectionView
//
//  Created by 庄黛淳华 on 2020/7/25.
//

import Foundation

extension CollectionView {
	@usableFromInline
	class ItemData<ItemIdentifier> {
		@usableFromInline
		let base: ItemIdentifier
		@usableFromInline
		func tryBase<Item>() -> Item? {
			if let base = base as? Item {
				return base
			} else if let base = (base as? AnyHashable)?.base as? Item {
				return base
			} else {
				return nil
			}
		}
		@usableFromInline
		init(_ base: ItemIdentifier) {
			self.base = base
		}
		@usableFromInline
		var subItems: [ItemData] = []
		@usableFromInline
		func allItems<Item>() -> [Item] {
			var result = [Item]()
			if let base = base as? Item {
				result.append(base)
			}
			for sub in subItems {
				result.append(contentsOf: sub.allItems())
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
}
