/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Per-section specific layout example
*/

import UIKit
import ConfigableCollectionView

class DistinctSectionsViewController: UIViewController {

    enum SectionLayoutKind: Int, CaseIterable {
        case list, grid5, grid3
        var columnCount: Int {
            switch self {
            case .grid3:
                return 3

            case .grid5:
                return 5

            case .list:
                return 1
            }
        }
    }

    #if OfficialDemo
    var dataSource: UICollectionViewDiffableDataSource<SectionLayoutKind, Int>! = nil
    var collectionView: UICollectionView! = nil
    #else
    private(set) lazy var collectionView = CollectionView<SectionLayoutKind, Int>(layout: createLayout())
    #endif

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Distinct Sections"
        configureHierarchy()
        configureDataSource()
    }
}

extension DistinctSectionsViewController {
    /// - Tag: PerSection
    func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { (sectionIndex: Int,
            layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in

            guard let sectionLayoutKind = SectionLayoutKind(rawValue: sectionIndex) else { return nil }
            let columns = sectionLayoutKind.columnCount

            // The group auto-calculates the actual item width to make
            // the requested number of columns fit, so this widthDimension is ignored.
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                 heightDimension: .fractionalHeight(1.0))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2)

            let groupHeight = columns == 1 ?
                NSCollectionLayoutDimension.absolute(44) :
                NSCollectionLayoutDimension.fractionalWidth(0.2)
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                  heightDimension: groupHeight)
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: columns)

            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)
            return section
        }
        return layout
    }
}

extension DistinctSectionsViewController {
    func configureHierarchy() {
        #if OfficialDemo
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        #else
        collectionView.frame = view.bounds
        #endif
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .systemBackground
        view.addSubview(collectionView)
        collectionView.delegate = self
    }
    func configureDataSource() {
        #if OfficialDemo
        let listCellRegistration = UICollectionView.CellRegistration<ListCell, Int> { (cell, indexPath, identifier) in
            // Populate the cell with our item description.
            cell.label.text = "\(identifier)"
        }
        
        let textCellRegistration = UICollectionView.CellRegistration<TextCell, Int> { (cell, indexPath, identifier) in
            // Populate the cell with our item description.
            cell.label.text = "\(identifier)"
            cell.contentView.backgroundColor = .cornflowerBlue
            cell.contentView.layer.borderColor = UIColor.black.cgColor
            cell.contentView.layer.borderWidth = 1
            cell.contentView.layer.cornerRadius = SectionLayoutKind(rawValue: indexPath.section)! == .grid5 ? 8 : 0
            cell.label.textAlignment = .center
            cell.label.font = UIFont.preferredFont(forTextStyle: .title1)
        }
        
        dataSource = UICollectionViewDiffableDataSource<SectionLayoutKind, Int>(collectionView: collectionView) {
            (collectionView: UICollectionView, indexPath: IndexPath, identifier: Int) -> UICollectionViewCell? in
            // Return the cell.
            return SectionLayoutKind(rawValue: indexPath.section)! == .list ?
            collectionView.dequeueConfiguredReusableCell(using: listCellRegistration, for: indexPath, item: identifier) :
            collectionView.dequeueConfiguredReusableCell(using: textCellRegistration, for: indexPath, item: identifier)
        }

        // initial data
        let itemsPerSection = 10
        var snapshot = NSDiffableDataSourceSnapshot<SectionLayoutKind, Int>()
        SectionLayoutKind.allCases.forEach {
            snapshot.appendSections([$0])
            let itemOffset = $0.rawValue * itemsPerSection
            let itemUpperbound = itemOffset + itemsPerSection
            snapshot.appendItems(Array(itemOffset..<itemUpperbound))
        }
        dataSource.apply(snapshot, animatingDifferences: false)
        #else
        collectionView.register(
            view: {
                ListCell()
            },
            .config {
				let cell = $0.view
				let identifier = $0.data
                cell.label.text = "\(identifier)"
            },
            .when {
                SectionLayoutKind(rawValue: $0.indexPath.section)! == .list
            }
        )
        collectionView.register(
            view: {
                TextCell()
            },
            .config {
				let cell = $0.view
				let identifier = $0.data
				let indexPath = $0.indexPath
                cell.label.text = "\(identifier)"
                cell.contentView.backgroundColor = .cornflowerBlue
                cell.contentView.layer.borderColor = UIColor.black.cgColor
                cell.contentView.layer.borderWidth = 1
                cell.contentView.layer.cornerRadius = SectionLayoutKind(rawValue: indexPath.section)! == .grid5 ? 8 : 0
                cell.label.textAlignment = .center
                cell.label.font = UIFont.preferredFont(forTextStyle: .title1)
            }
        )
        // initial data
        let itemsPerSection = 10
        
        SectionLayoutKind.allCases.forEach {
            let itemOffset = $0.rawValue * itemsPerSection
            let itemUpperbound = itemOffset + itemsPerSection
            let items = Array(itemOffset..<itemUpperbound)
            collectionView.dataManager.applyItems(items, updatedSection: $0)
                .on(animatingDifferences: false)
        }
        #endif
    }
}

extension DistinctSectionsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}
