//
//  Array.swift
//  ConfigableCollectionView
//
//  Created by 庄黛淳华 on 2020/7/20.
//

import Foundation

extension Array where Element: Hashable {
	@usableFromInline
	func unique() -> (array: [Element], set: Set<Element>) {
		var set = Set<Element>(minimumCapacity: count)
		let array = filter {
			set.insert($0).inserted
		}
		return (array, set)
	}
}

extension Array where Element == () -> Void {
    @usableFromInline
    func call() {
        for call in self {
            call()
        }
    }
}
