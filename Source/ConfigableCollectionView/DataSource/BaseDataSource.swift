//
//  BaseDataSource.swift
//  ConfigableCollectionView
//
//  Created by 庄黛淳华 on 2020/7/12.
//

import UIKit

extension CollectionView {
	class BaseDataSource<SectionIdentifier, ItemIdentifier>: NSObject, UICollectionViewDataSource where SectionIdentifier: Hashable, ItemIdentifier: Hashable {
        var sections: [SectionData<ItemIdentifier>] {
            guard let dataManager = _collectionView?._dataManager as? DataManager<SectionIdentifier, ItemIdentifier> else { return [] }
            return dataManager.sections
        }
		weak var _collectionView: CollectionView?
		
		init(collectionView: CollectionView) {
			_collectionView = collectionView
			collectionView.reloadHandler._baseReload = { [weak collectionView] animatingDifferences, completion in
				UIView.animate(withDuration: 0, animations: {
					collectionView?.reloadData()
				}, completion: { _ in
                    completion.call()
				})
			}
		}
		
		func numberOfSections(in collectionView: UICollectionView) -> Int {
			sections.count
		}
		func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
			sections[section].items.count
		}
		
		func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
			_collectionView?.cell(at: indexPath, item: nil) ?? collectionView.dequeueReusableCell(withReuseIdentifier: emptyCellIdentifier, for: indexPath)
		}
	}
}
