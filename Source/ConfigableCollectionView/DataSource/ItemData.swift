//
//  ItemData.swift
//  ConfigableCollectionView
//
//  Created by 庄黛淳华 on 2020/7/25.
//

import UIKit

extension CollectionView {
	@usableFromInline
	class ItemData<ItemIdentifier> {
		@usableFromInline
		let base: ItemIdentifier
		@usableFromInline
		var subItems: [ItemData] = []
		
		@usableFromInline
		init(_ base: ItemIdentifier) {
			self.base = base
		}
	}
}
extension CollectionView.ItemData where ItemIdentifier == CollectionView.AnyHashable {
	@usableFromInline
	convenience init<Item>(_ base: Item) where Item: Hashable {
		self.init(.package(base))
	}
}
extension CollectionView.ItemData {
	@usableFromInline
	func tryBase<Item>() -> Item? {
		if let base = base as? Item {
			return base
		} else if let base = (base as? CollectionView.AnyHashable)?.base as? Item {
			return base
		} else {
			return nil
		}
	}
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
		if let base = base as? CollectionView.AnyHashable {
			if let value = value as? CollectionView.AnyHashable {
				if base == value {
					return true
				}
			} else {
				if base == value {
					return true
				}
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
			if let base = item.base as? CollectionView.AnyHashable {
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

extension CollectionView.ItemData: Equatable where ItemIdentifier: Equatable {
	@usableFromInline
	static func == (lhs: CollectionView.ItemData<ItemIdentifier>, rhs: CollectionView.ItemData<ItemIdentifier>) -> Bool {
		lhs.base == rhs.base && lhs.subItems == rhs.subItems
	}
}

extension CollectionView.ItemData: CustomDebugStringConvertible {
	public var debugDescription: String {
		if let convert = base as? CustomDebugStringConvertible {
			return convert.debugDescription
		} else {
			return "\(base)"
		}
	}
}
