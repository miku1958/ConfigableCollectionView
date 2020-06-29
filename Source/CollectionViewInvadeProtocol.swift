//
//  CollectionViewInvadeProtocol.swift
//  ConfigableCollectionView
//
//  Created by 庄黛淳华 on 2020/5/18.
//  Copyright © 2020 庄黛淳华. All rights reserved.
//

import Foundation

/// CollectionView通用的方法调用前拦截器
public protocol CollectionViewInvadeProtocol {
	static func didselected(view: UIView, call: @escaping () -> Void)
}
public extension CollectionViewInvadeProtocol {
	static func didselected(view: UIView, call: @escaping () -> Void) {
		
	}
}
