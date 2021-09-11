//
//  CollectionViewSupplementaryView.swift
//  ConfigableCollectionView
//
//  Created by 庄黛淳华 on 2020/7/24.
//

import UIKit

//class CollectionViewSupplementaryView: UICollectionReusableView {
//    var subview: UIView?
//    var createSubview: (() -> UIView?)? {
//        didSet {
//            subview?.removeFromSuperview()
//            if let view = createSubview?() {
//                subview = view
//                addSubview(view)
//                
//                view.translatesAutoresizingMaskIntoConstraints = false
//                NSLayoutConstraint.activate([
//                    view.topAnchor.constraint(equalTo: self.topAnchor),
//                    view.leadingAnchor.constraint(equalTo: self.leadingAnchor),
//                    view.bottomAnchor.constraint(equalTo: self.bottomAnchor),
//                    view.trailingAnchor.constraint(equalTo: self.trailingAnchor)
//                ])
//            }
//        }
//    }
//    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
//        subview?.point(inside: point, with: event) ?? super.point(inside: point, with: event)
//    }
//    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
//        if isUserInteractionEnabled, !isHidden, alpha>0.01 {
//            return subview?.hitTest(point, with: event) ?? super.hitTest(point, with: event)
//        } else {
//            return nil
//        }
//    }
//}
