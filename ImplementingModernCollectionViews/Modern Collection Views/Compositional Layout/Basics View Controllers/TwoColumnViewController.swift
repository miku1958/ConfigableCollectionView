/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A two column grid described by compositional layout
*/

import UIKit
import ConfigableCollectionView

class TwoColumnViewController: UIViewController {

    enum Section {
        case main
    }

    #if OfficialDemo
    var dataSource: UICollectionViewDiffableDataSource<Section, Int>! = nil
    var collectionView: UICollectionView! = nil
    #else
    private(set) lazy var collectionView = CollectionView<Section, Int>(layout: createLayout())
    #endif

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Two-Column Grid"
        configureHierarchy()
        configureDataSource()
    }
}

extension TwoColumnViewController {
    /// - Tag: TwoColumn
    func createLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                             heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .absolute(44))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 2)
        let spacing = CGFloat(10)
        group.interItemSpacing = .fixed(spacing)

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = spacing
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10)

        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }
}

extension TwoColumnViewController {
    func configureHierarchy() {
        #if OfficialDemo
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        #else
        collectionView.frame = view.bounds
        #endif
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .systemBackground
        view.addSubview(collectionView)
    }
    func configureDataSource() {
        #if OfficialDemo
        let cellRegistration = UICollectionView.CellRegistration<TextCell, Int> { (cell, indexPath, identifier) in
            // Populate the cell with our item description.
            cell.label.text = "\(identifier)"
            cell.contentView.backgroundColor = .cornflowerBlue
            cell.layer.borderColor = UIColor.black.cgColor
            cell.layer.borderWidth = 1
            cell.label.textAlignment = .center
            cell.label.font = UIFont.preferredFont(forTextStyle: .title1)
        }
        
        dataSource = UICollectionViewDiffableDataSource<Section, Int>(collectionView: collectionView) {
            (collectionView: UICollectionView, indexPath: IndexPath, identifier: Int) -> UICollectionViewCell? in
            // Return the cell.
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: identifier)
        }

        // initial data
        var snapshot = NSDiffableDataSourceSnapshot<Section, Int>()
        snapshot.appendSections([.main])
        snapshot.appendItems(Array(0..<94))
        dataSource.apply(snapshot, animatingDifferences: false)
        #else
        collectionView.register(
            view: {
                TextCell()
            },
            .config {
				let cell = $0.view
				let identifier = $0.data
                cell.label.text = "\(identifier)"
                cell.contentView.backgroundColor = .cornflowerBlue
                cell.layer.borderColor = UIColor.black.cgColor
                cell.layer.borderWidth = 1
                cell.label.textAlignment = .center
                cell.label.font = UIFont.preferredFont(forTextStyle: .title1)
            }
        )
        collectionView.dataManager.applyItems(Array(0..<94), updatedSection: Section.main)
            .on(animatingDifferences: false)
        #endif
    }
}
