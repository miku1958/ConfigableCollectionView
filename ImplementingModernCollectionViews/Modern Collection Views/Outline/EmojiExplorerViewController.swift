/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A collection view that uses a different layout for each section
*/

import UIKit
import ConfigableCollectionView

class EmojiExplorerViewController: UIViewController {
    
    enum Section: Int, Hashable, CaseIterable, CustomStringConvertible {
        case recents, outline, list
        
        var description: String {
            switch self {
            case .recents: return "Recents"
            case .outline: return "Outline"
            case .list: return "List"
            }
        }
    }
    
    struct Item: Hashable {
        let title: String?
        let emoji: Emoji?
        let hasChildren: Bool
        init(emoji: Emoji? = nil, title: String? = nil, hasChildren: Bool = false) {
            self.emoji = emoji
            self.title = title
            self.hasChildren = hasChildren
        }
        private let identifier = UUID()
    }
    
    var starredEmojis = Set<Item>()
    
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
}

extension EmojiExplorerViewController {
    
    func configureNavItem() {
        navigationItem.title = "Emoji Explorer"
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
        
        let sectionProvider = { (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            
            guard let sectionKind = Section(rawValue: sectionIndex) else { return nil }
            
            let section: NSCollectionLayoutSection
            
            // orthogonal scrolling section of images
            if sectionKind == .recents {
                
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5)
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.28), heightDimension: .fractionalWidth(0.2))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                section = NSCollectionLayoutSection(group: group)
                section.interGroupSpacing = 10
                section.orthogonalScrollingBehavior = .continuousGroupLeadingBoundary
                section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
                
                // outline
            } else if sectionKind == .outline {
                section = NSCollectionLayoutSection.list(using: .init(appearance: .sidebar), layoutEnvironment: layoutEnvironment)
                section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 0, trailing: 10)
                
                // list
            } else if sectionKind == .list {
                var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
                configuration.leadingSwipeActionsConfigurationProvider = { [weak self] (indexPath) in
                    guard let self = self else { return nil }
                    #if OfficialDemo
                    guard let item = self.dataSource.itemIdentifier(for: indexPath) else { return nil }
                    #else
                    guard let item = self.collectionView.dataManager.itemIdentifier(for: indexPath) else { return nil }
                    #endif
                    return self.leadingSwipeActionConfigurationForListCellItem(item)
                }
                section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: layoutEnvironment)
            } else {
                fatalError("Unknown section!")
            }
            
            return section
        }
        return UICollectionViewCompositionalLayout(sectionProvider: sectionProvider)
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
    
    func accessoriesForListCellItem(_ item: Item) -> [UICellAccessory] {
        let isStarred = self.starredEmojis.contains(item)
        var accessories = [UICellAccessory.disclosureIndicator()]
        if isStarred {
            let star = UIImageView(image: UIImage(systemName: "star.fill"))
            accessories.append(.customView(configuration: .init(customView: star, placement: .trailing())))
        }
        return accessories
    }
    
    func leadingSwipeActionConfigurationForListCellItem(_ item: Item) -> UISwipeActionsConfiguration? {
        let isStarred = self.starredEmojis.contains(item)
        let starAction = UIContextualAction(style: .normal, title: nil) {
            [weak self] (_, _, completion) in
            guard let self = self else {
                completion(false)
                return
            }
            
            // Don't check again for the starred state. We promised in the UI what this action will do.
            // If the starred state has changed by now, we do nothing, as the set will not change.
            if isStarred {
                self.starredEmojis.remove(item)
            } else {
                self.starredEmojis.insert(item)
            }
            
            // Reconfigure the cell of this item
            // Make sure we get the current index path of the item.
            #if OfficialDemo
            if let currentIndexPath = self.dataSource.indexPath(for: item) {
                if let cell = self.collectionView.cellForItem(at: currentIndexPath) as? UICollectionViewListCell {
                    UIView.animate(withDuration: 0.2) {
                        cell.accessories = self.accessoriesForListCellItem(item)
                    }
                }
            }
            #else
            if let currentIndexPath = self.collectionView.dataManager.indexPath(for: item) {
                if let cell = self.collectionView.cellForItem(at: currentIndexPath) as? UICollectionViewListCell {
                    UIView.animate(withDuration: 0.2) {
                        cell.accessories = self.accessoriesForListCellItem(item)
                    }
                }
            }
            #endif
            
            completion(true)
        }
        starAction.image = UIImage(systemName: isStarred ? "star.slash" : "star.fill")
        starAction.backgroundColor = .systemBlue
        return UISwipeActionsConfiguration(actions: [starAction])
    }
    
    #if OfficialDemo
    func configuredGridCell() -> UICollectionView.CellRegistration<UICollectionViewCell, Emoji> {
        return UICollectionView.CellRegistration<UICollectionViewCell, Emoji> { (cell, indexPath, emoji) in
            var content = UIListContentConfiguration.cell()
            content.text = emoji.text
            content.textProperties.font = .boldSystemFont(ofSize: 38)
            content.textProperties.alignment = .center
            content.directionalLayoutMargins = .zero
            cell.contentConfiguration = content
            var background = UIBackgroundConfiguration.listPlainCell()
            background.cornerRadius = 8
            background.strokeColor = .systemGray3
            background.strokeWidth = 1.0 / cell.traitCollection.displayScale
            cell.backgroundConfiguration = background
        }
    }
    #else
    func configuredGridCell(_ cell: UICollectionViewCell, emoji: Emoji) {
        var content = UIListContentConfiguration.cell()
        content.text = emoji.text
        content.textProperties.font = .boldSystemFont(ofSize: 38)
        content.textProperties.alignment = .center
        content.directionalLayoutMargins = .zero
        cell.contentConfiguration = content
        var background = UIBackgroundConfiguration.listPlainCell()
        background.cornerRadius = 8
        background.strokeColor = .systemGray3
        background.strokeWidth = 1.0 / cell.traitCollection.displayScale
        cell.backgroundConfiguration = background
    }
    #endif

    #if OfficialDemo
    func configuredOutlineHeaderCell() -> UICollectionView.CellRegistration<UICollectionViewListCell, String> {
        return UICollectionView.CellRegistration<UICollectionViewListCell, String> { (cell, indexPath, title) in
            var content = cell.defaultContentConfiguration()
            content.text = title
            cell.contentConfiguration = content
            cell.accessories = [.outlineDisclosure(options: .init(style: .header))]
        }
    }
    #else
    func configuredOutlineHeaderCell(_ cell:UICollectionViewListCell, title: String) {
        var content = cell.defaultContentConfiguration()
        content.text = title
        cell.contentConfiguration = content
        cell.accessories = [.outlineDisclosure(options: .init(style: .header))]
    }
    #endif

    
    #if OfficialDemo
    func configuredOutlineCell() -> UICollectionView.CellRegistration<UICollectionViewListCell, Emoji> {
        return UICollectionView.CellRegistration<UICollectionViewListCell, Emoji> { (cell, indexPath, emoji) in
            var content = cell.defaultContentConfiguration()
            content.text = emoji.text
            content.secondaryText = emoji.title
            cell.contentConfiguration = content
            cell.accessories = [.disclosureIndicator()]
        }
    }
    #else
    func configuredOutlineCell(_ cell: UICollectionViewListCell, emoji: Emoji) {
        var content = cell.defaultContentConfiguration()
        content.text = emoji.text
        content.secondaryText = emoji.title
        cell.contentConfiguration = content
        cell.accessories = [.disclosureIndicator()]
    }
    #endif

    
    #if OfficialDemo
    func configuredListCell() -> UICollectionView.CellRegistration<UICollectionViewListCell, Item> {
        return UICollectionView.CellRegistration<UICollectionViewListCell, Item> { [weak self] (cell, indexPath, item) in
            guard let self = self, let emoji = item.emoji else { return }
            var content = UIListContentConfiguration.valueCell()
            content.text = emoji.text
            content.secondaryText = String(describing: emoji.category)
            cell.contentConfiguration = content
            cell.accessories = self.accessoriesForListCellItem(item)
        }
    }
    #else
    func configuredListCell(_ cell: UICollectionViewListCell, item: Item) {
        guard let emoji = item.emoji else { return }
        var content = UIListContentConfiguration.valueCell()
        content.text = emoji.text
        content.secondaryText = String(describing: emoji.category)
        cell.contentConfiguration = content
        cell.accessories = self.accessoriesForListCellItem(item)
    }
    #endif

    
    func configureDataSource() {
        // data source
        #if OfficialDemo
        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) {
            (collectionView, indexPath, item) -> UICollectionViewCell? in
            guard let section = Section(rawValue: indexPath.section) else { fatalError("Unknown section") }
            switch section {
            case .recents:
                return collectionView.dequeueConfiguredReusableCell(using: self.configuredGridCell(), for: indexPath, item: item.emoji)
            case .list:
                return collectionView.dequeueConfiguredReusableCell(using: self.configuredListCell(), for: indexPath, item: item)
            case .outline:
                if item.hasChildren {
                    return collectionView.dequeueConfiguredReusableCell(using: self.configuredOutlineHeaderCell(), for: indexPath, item: item.title!)
                } else {
                    return collectionView.dequeueConfiguredReusableCell(using: self.configuredOutlineCell(), for: indexPath, item: item.emoji)
                }
            }
        }
        #else
        collectionView.register(
            view: {
                UICollectionViewCell()
            },
            .config(compactMap: \.emoji) { [weak self] in
                self?.configuredGridCell($0.view, emoji: $0.data)
            },
            .when {
                Section(rawValue: $0.indexPath.section) == .recents
            }
        )
        collectionView.register(
            view: {
                UICollectionViewListCell()
            },
            .config { [weak self] in
                self?.configuredListCell($0.view, item: $0.data)
            },
            .when {
                Section(rawValue: $0.indexPath.section) == .list
            }
        )
        collectionView.register(
            view: {
                UICollectionViewListCell()
            },
            .config { [weak self] in
                self?.configuredOutlineHeaderCell($0.view, title: $0.data.title ?? "")
            },
            .when {
                Section(rawValue: $0.indexPath.section) == .outline && $0.data.hasChildren
            }
        )
        collectionView.register(
            view: {
                UICollectionViewListCell()
            },
            .config(compactMap: \.emoji) { [weak self] in
                self?.configuredOutlineCell($0.view, emoji: $0.data)
            },
            .when {
                Section(rawValue: $0.indexPath.section) == .outline && !$0.data.hasChildren
            }
        )
        #endif
    }
    
    func applyInitialSnapshots() {
        #if OfficialDemo
        // set the order for our sections

        let sections = Section.allCases
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections(sections)
        dataSource.apply(snapshot, animatingDifferences: false)
        
        // recents (orthogonal scroller)
        
        let recentItems = Emoji.Category.recents.emojis.map { Item(emoji: $0) }
        var recentsSnapshot = NSDiffableDataSourceSectionSnapshot<Item>()
        recentsSnapshot.append(recentItems)
        dataSource.apply(recentsSnapshot, to: .recents, animatingDifferences: false)

        // list of all + outlines
        
        var allSnapshot = NSDiffableDataSourceSectionSnapshot<Item>()
        var outlineSnapshot = NSDiffableDataSourceSectionSnapshot<Item>()
        
        for category in Emoji.Category.allCases where category != .recents {
            // append to the "all items" snapshot
            let allSnapshotItems = category.emojis.map { Item(emoji: $0) }
            allSnapshot.append(allSnapshotItems)
            
            // setup our parent/child relations
            let rootItem = Item(title: String(describing: category), hasChildren: true)
            outlineSnapshot.append([rootItem])
            let outlineItems = category.emojis.map { Item(emoji: $0) }
            outlineSnapshot.append(outlineItems, to: rootItem)
        }
        
        dataSource.apply(recentsSnapshot, to: .recents, animatingDifferences: false)
        dataSource.apply(allSnapshot, to: .list, animatingDifferences: false)
        dataSource.apply(outlineSnapshot, to: .outline, animatingDifferences: false)
        
        // prepopulate starred emojis
        
        for _ in 0..<5 {
            if let item = allSnapshot.items.randomElement() {
                self.starredEmojis.insert(item)
            }
        }
        #else
        // set the order for our sections
        
        let sections = Section.allCases
        collectionView.dataManager.appendSections(sections)
            .on(animatingDifferences: false)
        
        // recents (orthogonal scroller)
        
        let recentItems = Emoji.Category.recents.emojis.map { Item(emoji: $0) }
        collectionView.dataManager.appendItems(recentItems, toSection: Section.recents)
        
        // list of all + outlines
        
        for category in Emoji.Category.allCases where category != .recents {
            // append to the "all items" snapshot
            let allSnapshotItems = category.emojis.map { Item(emoji: $0) }
            collectionView.dataManager.appendItems(allSnapshotItems, toSection: Section.list)
            
            // setup our parent/child relations
            let rootItem = Item(title: String(describing: category), hasChildren: true)
            collectionView.dataManager.appendItems([rootItem], toSection: Section.outline)
            let outlineItems = category.emojis.map { Item(emoji: $0) }
            collectionView.dataManager.appendChildItems(outlineItems, to: rootItem)
        }
        
        // prepopulate starred emojis
        
        for _ in 0..<5 {
            if let item = collectionView.dataManager.allItems(inSection: Section.list)?.randomElement() {
                self.starredEmojis.insert(item)
            }
        }
        #endif
    }
}

extension EmojiExplorerViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        #if OfficialDemo
        guard let emoji = self.dataSource.itemIdentifier(for: indexPath)?.emoji else {
            collectionView.deselectItem(at: indexPath, animated: true)
            return
        }
        #else
        guard let emoji = self.collectionView.dataManager.itemIdentifier(for: indexPath)?.emoji else {
            collectionView.deselectItem(at: indexPath, animated: true)
            return
        }
        #endif
        let detailViewController = EmojiDetailViewController(with: emoji)
        self.navigationController?.pushViewController(detailViewController, animated: true)
    }
}
