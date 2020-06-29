//
//  NSObject.swift
//  ConfigableCollectionView
//
//  Created by 庄黛淳华 on 2020/6/29.
//

import Foundation

protocol Mapable {
	
}
extension Mapable {
	@inline(__always) public func map<T>(_ transform: (Self) throws -> T) rethrows -> T {
		try transform(self)
	}
}
extension NSObject: Mapable { }
