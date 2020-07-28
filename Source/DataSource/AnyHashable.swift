//
//  AnyHashable.swift
//  ConfigableCollectionView
//
//  Created by 庄黛淳华 on 2020/7/19.
//

import Foundation
extension CollectionView {
	// print(Swift.AnyHashable(Int(1)) == Swift.AnyHashable(Int8(1))) // true, 所以手动写一个AnyHashable
	public struct AnyHashable: Hashable {
		/// The value wrapped by this instance.
		///
		/// The `base` property can be cast back to its original type using one of
		/// the type casting operators (`as?`, `as!`, or `as`).
		@usableFromInline
		var base: Any
		var baseType: Any.Type
		public var hashValue: Int
		
		/// Creates a type-erased hashable value that wraps the given instance.
		///
		/// - Parameter base: A hashable value to wrap.
		private init<H>(_ base: H) where H : Hashable {
			self.base = base
			self.baseType = H.self
			self.hashValue = base.hashValue
		}
		@usableFromInline
		static func package<H>(_ base: H) -> AnyHashable where H : Hashable {
			if let any = base as? AnyHashable {
				return any
			} else {
				return .init(base)
			}
		}
	}
}

extension CollectionView.AnyHashable {
	public static func == (lhs: Self, rhs: Self) -> Bool {
		guard
			lhs.baseType == rhs.baseType,
			lhs.hashValue == rhs.hashValue
		else {
			return false
		}
		return true
	}
	@usableFromInline
	static func == <R>(lhs: Self, rhs: R) -> Bool where R: Hashable {
		guard
			lhs.baseType == R.self,
			lhs.hashValue == rhs.hashValue
		else {
			return false
		}
		return true
	}
}

extension CollectionView.AnyHashable: CustomDebugStringConvertible {
	public var debugDescription: String {
		if let convert = base as? CustomDebugStringConvertible {
			return convert.debugDescription
		} else {
			return "\(base)"
		}
	}
}
