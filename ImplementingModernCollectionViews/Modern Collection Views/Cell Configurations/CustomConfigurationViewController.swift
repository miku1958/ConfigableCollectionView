/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A basic compositional layout with cells that use custom configurations.
*/

import UIKit
import ConfigableCollectionView

private enum Section: Hashable {
    case main
}

private struct Item: Hashable {
    let image: UIImage?
    init(imageName: String) {
        self.image = UIImage(systemName: imageName)
    }
    private let identifier = UUID()
    
    static let all = Array(repeating: [
        "trash", "folder", "paperplane", "book", "tag", "camera", "pin",
        "lock.shield", "cube.box", "gift", "eyeglasses", "lightbulb"
    ], count: 25).flatMap { $0 }.shuffled().map { Item(imageName: $0) }
}

class CustomConfigurationViewController: UIViewController {
    
    #if OfficialDemo
    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>! = nil
    private var collectionView: UICollectionView! = nil
    #else
    private lazy var collectionView = CollectionView<Section, Item>(layout: createLayout())
    #endif
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Custom Configurations"
        configureHierarchy()
        configureDataSource()
    }
}

extension CustomConfigurationViewController {
    private func createLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .estimated(44), heightDimension: .estimated(44))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(44))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        group.interItemSpacing = .flexible(10)
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 10
        section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        return UICollectionViewCompositionalLayout(section: section)
    }
}

extension CustomConfigurationViewController {
    private func configureHierarchy() {
        #if OfficialDemo
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        #else
        collectionView.frame = view.bounds
        #endif
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .systemBackground
        view.addSubview(collectionView)
    }
    private func configureDataSource() {
        #if OfficialDemo
        let cellRegistration = UICollectionView.CellRegistration<CustomConfigurationCell, Item> { (cell, indexPath, item) in
            cell.image = item.image
        }
        
        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) {
            (collectionView: UICollectionView, indexPath: IndexPath, item: Item) -> UICollectionViewCell? in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }
        
        // initial data
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        snapshot.appendItems(Item.all)
        dataSource.apply(snapshot, animatingDifferences: false)
        #else
        collectionView.register(
            view: {
                CustomContentView()
            },
            .config {
                $0.view.configuration.image = $0.data.image
                $0.view.configuration.updated(for: $0.configurationState)
            }
        )
        // initial data
        collectionView.dataManager.applyItems(Item.all, updatedSection: .main)
            .on(animatingDifferences: false)
        #endif
    }
}

#if OfficialDemo
class CustomConfigurationCell: UICollectionViewCell {
    var image: UIImage? {
        didSet {
            setNeedsUpdateConfiguration()
        }
    }
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        backgroundConfiguration = CustomBackgroundConfiguration.configuration(for: state)
        
        var content = CustomContentConfiguration().updated(for: state)
        content.image = image
        contentConfiguration = content
    }
}
#endif
