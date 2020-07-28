/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A collection view that uses a list layout
*/

import UIKit
import ConfigableCollectionView

class EmojiExplorerListViewController: UIViewController {
    
    typealias Section = Emoji.Category
    
    struct Item: Hashable {
        let title: String
        let emoji: Emoji
        init(emoji: Emoji, title: String) {
            self.emoji = emoji
            self.title = title
        }
        private let identifier = UUID()
    }
    #if OfficialDemo
    var collectionView: UICollectionView!
    var dataSource: UICollectionViewDiffableDataSource<Section, Item>!
    #else
    lazy var collectionView = CollectionView<Section, Item>(layout: createLayout())
    #endif

    override func viewDidLoad() {
        super.viewDidLoad()
    
        configureNavItem()
        configureHierarchy()
        configureDataSource()
        applyInitialSnapshots()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let indexPath = self.collectionView.indexPathsForSelectedItems?.first {
            if let coordinator = self.transitionCoordinator {
                coordinator.animate(alongsideTransition: { context in
                    self.collectionView.deselectItem(at: indexPath, animated: true)
                }) { (context) in
                    if context.isCancelled {
                        self.collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                    }
                }
            } else {
                self.collectionView.deselectItem(at: indexPath, animated: animated)
            }
        }
    }
}

extension EmojiExplorerListViewController {
    
    func configureNavItem() {
        navigationItem.title = "Emoji Explorer - List"
        navigationItem.largeTitleDisplayMode = .always
    }
    
    func configureHierarchy() {
        #if OfficialDemo
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .systemGroupedBackground
        collectionView.delegate = self
        view.addSubview(collectionView)
        #else
        collectionView.frame = view.bounds
        view.addSubview(collectionView)
        collectionView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        collectionView.backgroundColor = .systemGroupedBackground
        collectionView.delegate = self
        #endif
    }
    
    func createLayout() -> UICollectionViewLayout {
        let configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        return UICollectionViewCompositionalLayout.list(using: configuration)
    }
    
    func configureDataSource() {
        #if OfficialDemo
        // list cell
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Emoji> { (cell, indexPath, emoji) in
            var contentConfiguration = UIListContentConfiguration.valueCell()
            contentConfiguration.text = emoji.text
            contentConfiguration.secondaryText = String(describing: emoji.category)
            cell.contentConfiguration = contentConfiguration

            cell.accessories = [.disclosureIndicator()]
        }
        
        // data source
        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) {
            (collectionView, indexPath, item) -> UICollectionViewCell? in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item.emoji)
        }
        #else
        collectionView.register(
            view: {
                UICollectionViewListCell()
            },
            .config(map: \.emoji) {
				let cell = $0.view
				let emoji = $0.data
                var contentConfiguration = UIListContentConfiguration.valueCell()
                contentConfiguration.text = emoji.text
                contentConfiguration.secondaryText = String(describing: emoji.category)
                cell.contentConfiguration = contentConfiguration
                
                cell.accessories = [.disclosureIndicator()]
            },
            .tap { [weak self] in
				guard let self = self else { return }
				let item = $0.data
				let indexPath = $0.indexPath
				self.collectionView.deselectItem(at: indexPath, animated: true)
                let emoji = item.emoji
                let detailViewController = EmojiDetailViewController(with: emoji)
                self.navigationController?.pushViewController(detailViewController, animated: true)
            }
        )
        #endif
    }
    
    func applyInitialSnapshots() {
        #if OfficialDemo
        for category in Emoji.Category.allCases.reversed() {
            var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<Item>()
            let items = category.emojis.map { Item(emoji: $0, title: String(describing: category)) }
            sectionSnapshot.append(items)
            dataSource.apply(sectionSnapshot, to: category, animatingDifferences: false)
        }
        #else
        for category in Emoji.Category.allCases.reversed() {
            let items = category.emojis.map { Item(emoji: $0, title: String(describing: category)) }
            collectionView.dataManager.applyItems(items, updatedSection: category)
        }
        #endif
    }
}

extension EmojiExplorerListViewController: UICollectionViewDelegate {
    #if OfficialDemo
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let emoji = self.dataSource.itemIdentifier(for: indexPath)?.emoji else {
            collectionView.deselectItem(at: indexPath, animated: true)
            return
        }
        let detailViewController = EmojiDetailViewController(with: emoji)
        self.navigationController?.pushViewController(detailViewController, animated: true)
    }
    #endif
}

