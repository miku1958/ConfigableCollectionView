//
//  ViewBuilder.swift
//  ConfigableCollectionView
//
//  Created by 庄黛淳华 on 2020/7/22.
//

import Foundation
import SwiftUI

public protocol View { }

extension UIView: View { }
extension Optional: View { }
@_functionBuilder
public struct ViewBuilder {
	public static func buildBlock<Content>(_ content: Content) -> Content where Content: View {
		content
	}
	
	public static func buildIf<Content>(_ content: Content?) -> Content? where Content: View {
		content
	}
}
