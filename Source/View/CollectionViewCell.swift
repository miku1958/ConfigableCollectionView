//
//  CollectionViewCell.swift
//  ConfigableCollectionView
//
//  Created by 庄黛淳华 on 2020/2/24.
//  Copyright © 2020 庄黛淳华. All rights reserved.
//

import UIKit

public class CollectionViewCell: UICollectionViewCell {
	public private(set) var subview: UIView?
	/// (UICellConfigurationState) -> Void
	var updateUICellConfigurationState: ((Any) -> Void)?
	var createSubview: (() -> UIView?)? {
		didSet {
			subview?.removeFromSuperview()
			if let view = createSubview?() {
				subview = view
				contentView.addSubview(view)
				
				view.translatesAutoresizingMaskIntoConstraints = false
				NSLayoutConstraint.activate([
					view.topAnchor.constraint(equalTo: self.contentView.topAnchor),
					view.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor),
					view.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor),
					view.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor)
				])
			}
		}
	}
}

extension CollectionViewCell {
	public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
		subview?.point(inside: point, with: event) ?? super.point(inside: point, with: event)
	}
	public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
		if isUserInteractionEnabled, !isHidden, alpha>0.01 {
			return subview?.hitTest(point, with: event) ?? super.hitTest(point, with: event)
		} else {
			return nil
		}
	}
	#if swift(>=5.3)
	@available(iOS 14.0, *)
	public override func updateConfiguration(using state: UICellConfigurationState) {
		updateUICellConfigurationState?(state)
	}
	#endif
}
