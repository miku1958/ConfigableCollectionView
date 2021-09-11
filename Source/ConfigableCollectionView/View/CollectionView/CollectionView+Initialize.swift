//
//  CollectionView+Initialize.swift
//  ConfigableCollectionView
//
//  Created by 庄黛淳华 on 2020/7/28.
//

import UIKit

extension CollectionView {
	@_disfavoredOverload
	public convenience init(layout: UICollectionViewLayout) {
		fatalError(#"Please use "Any" or "Type comfirms to Hashable" as the ItemType/SectionType"#)
	}
	@inline(__always)
	@_disfavoredOverload
	public var dataManager: DataManager<AnyHashable, AnyHashable> {
		fatalError("")
	}
}

extension CollectionView where ItemType == Any, SectionType: Hashable {
	public convenience init(layout: UICollectionViewLayout) {
		self.init(frame: .zero, collectionViewLayout: layout, dataManagerInit: {
			DataManager<SectionType, AnyHashable>(collectionView: $0)
		})
	}
	@inline(__always)
	public var dataManager: DataManager<SectionType, AnyHashable> {
		_dataManager as! DataManager<SectionType, AnyHashable>
	}
}
extension CollectionView where ItemType == Any, SectionType == Any {
	public convenience init(layout: UICollectionViewLayout) {
		self.init(frame: .zero, collectionViewLayout: layout, dataManagerInit: {
			DataManager<AnyHashable, AnyHashable>(collectionView: $0)
		})
	}
	@inline(__always)
	public var dataManager: DataManager<AnyHashable, AnyHashable> {
		_dataManager as! DataManager<AnyHashable, AnyHashable>
	}
}

extension CollectionView where ItemType: Hashable, SectionType: Hashable {
	public convenience init(layout: UICollectionViewLayout) {
		self.init(frame: .zero, collectionViewLayout: layout, dataManagerInit: {
			DataManager<SectionType, ItemType>(collectionView: $0)
		})
	}
	@inline(__always)
	public var dataManager: DataManager<SectionType, ItemType> {
		_dataManager as! DataManager<SectionType, ItemType>
	}
}
extension CollectionView where ItemType: Hashable, SectionType == Any {
	public convenience init(layout: UICollectionViewLayout) {
		self.init(frame: .zero, collectionViewLayout: layout, dataManagerInit: {
			DataManager<AnyHashable, ItemType>(collectionView: $0)
		})
	}
	@inline(__always)
	public var dataManager: DataManager<AnyHashable, ItemType> {
		_dataManager as! DataManager<AnyHashable, ItemType>
	}
}
