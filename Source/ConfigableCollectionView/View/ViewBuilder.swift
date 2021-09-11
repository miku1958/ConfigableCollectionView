//
//  ViewBuilder.swift
//  ConfigableCollectionView
//
//  Created by 庄黛淳华 on 2020/7/22.
//

import UIKit

public protocol ViewProtocol { }

extension UIView: ViewProtocol { }
extension Optional: ViewProtocol { }

@resultBuilder
public struct ViewBuilder {
	public static func buildBlock<Content>(_ content: Content) -> Content where Content: ViewProtocol {
		content
	}
	
	public static func buildIf<Content>(_ content: Content?) -> Content? where Content: ViewProtocol {
		content
	}
}
