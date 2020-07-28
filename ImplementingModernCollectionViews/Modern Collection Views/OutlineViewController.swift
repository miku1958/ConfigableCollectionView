/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A simple outline view for the sample app's main UI
*/

import UIKit
import ConfigableCollectionView

class OutlineViewController: UIViewController {

    enum Section {
        case main
    }

    class OutlineItem: Hashable {
        let title: String
        let subitems: [OutlineItem]
        let outlineViewController: UIViewController.Type?

        init(title: String,
             viewController: UIViewController.Type? = nil,
             subitems: [OutlineItem] = []) {
            self.title = title
            self.subitems = subitems
            self.outlineViewController = viewController
        }
        func hash(into hasher: inout Hasher) {
            hasher.combine(identifier)
        }
        static func == (lhs: OutlineItem, rhs: OutlineItem) -> Bool {
            return lhs.identifier == rhs.identifier
        }
        private let identifier = UUID()
    }

	#if OfficialDemo
	var dataSource: UICollectionViewDiffableDataSource<Section, OutlineItem>! = nil
	var outlineCollectionView: UICollectionView! = nil
	#else
	lazy var outlineCollectionView = CollectionView<Section, OutlineItem>(layout: generateLayout())
	#endif

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Modern Collection Views"
        configureCollectionView()
        configureDataSource()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            let snapshot = self.initialSnapshot()
            self.outlineCollectionView.dataManager.diffableDataSource.apply(snapshot, to: .main, animatingDifferences: false)
        }
    }
    
    private lazy var menuItems: [OutlineItem] = {
        return [
            OutlineItem(title: "Compositional Layout", subitems: [
                OutlineItem(title: "Getting Started", subitems: [
                    OutlineItem(title: "Grid", viewController: GridViewController.self),
                    OutlineItem(title: "Inset Items Grid",
                                viewController: InsetItemsGridViewController.self),
                    OutlineItem(title: "Two-Column Grid", viewController: TwoColumnViewController.self),
                    OutlineItem(title: "Per-Section Layout", subitems: [
                        OutlineItem(title: "Distinct Sections",
                                    viewController: DistinctSectionsViewController.self),
                        OutlineItem(title: "Adaptive Sections",
                                    viewController: AdaptiveSectionsViewController.self)
                        ])
                    ]),
                OutlineItem(title: "Advanced Layouts", subitems: [
                    OutlineItem(title: "Supplementary Views", subitems: [
                        OutlineItem(title: "Item Badges",
                                    viewController: ItemBadgeSupplementaryViewController.self),
                        OutlineItem(title: "Section Headers/Footers",
                                    viewController: SectionHeadersFootersViewController.self),
                        OutlineItem(title: "Pinned Section Headers",
                                    viewController: PinnedSectionHeaderFooterViewController.self)
                        ]),
                    OutlineItem(title: "Section Background Decoration",
                                viewController: SectionDecorationViewController.self),
                    OutlineItem(title: "Nested Groups",
                                viewController: NestedGroupsViewController.self),
                    OutlineItem(title: "Orthogonal Sections", subitems: [
                        OutlineItem(title: "Orthogonal Sections",
                                    viewController: OrthogonalScrollingViewController.self),
                        OutlineItem(title: "Orthogonal Section Behaviors",
                                    viewController: OrthogonalScrollBehaviorViewController.self)
                        ])
                    ]),
                OutlineItem(title: "Conference App", subitems: [
                    OutlineItem(title: "Videos",
                                viewController: ConferenceVideoSessionsViewController.self),
                    OutlineItem(title: "News", viewController: ConferenceNewsFeedViewController.self)
                    ])
            ]),
            OutlineItem(title: "Diffable Data Source", subitems: [
                OutlineItem(title: "Mountains Search", viewController: MountainsViewController.self),
                OutlineItem(title: "Settings: Wi-Fi", viewController: WiFiSettingsViewController.self),
                OutlineItem(title: "Insertion Sort Visualization",
                            viewController: InsertionSortViewController.self),
                OutlineItem(title: "UITableView: Editing",
                            viewController: TableViewEditingViewController.self)
                ]),
            OutlineItem(title: "Lists", subitems: [
                OutlineItem(title: "Simple List", viewController: SimpleListViewController.self),
                OutlineItem(title: "Reorderable List", viewController: ReorderableListViewController.self),
                OutlineItem(title: "List Appearances", viewController: ListAppearancesViewController.self),
                OutlineItem(title: "List with Custom Cells", viewController: CustomCellListViewController.self)
            ]),
            OutlineItem(title: "Outlines", subitems: [
                OutlineItem(title: "Emoji Explorer", viewController: EmojiExplorerViewController.self),
                OutlineItem(title: "Emoji Explorer - List", viewController: EmojiExplorerListViewController.self)
            ]),
            OutlineItem(title: "Cell Configurations", subitems: [
                OutlineItem(title: "Custom Configurations", viewController: CustomConfigurationViewController.self)
            ])
        ]
    }()
    
}

extension OutlineViewController {

    func configureCollectionView() {
		#if OfficialDemo
        let collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: generateLayout())
        view.addSubview(collectionView)
        collectionView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        collectionView.backgroundColor = .systemGroupedBackground
        self.outlineCollectionView = collectionView
        collectionView.delegate = self
		#else
		outlineCollectionView.frame = view.bounds
		view.addSubview(outlineCollectionView)
		outlineCollectionView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
		outlineCollectionView.backgroundColor = .systemGroupedBackground
		#endif
    }

    func configureDataSource() {
		#if OfficialDemo
        let containerCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, OutlineItem> { (cell, indexPath, menuItem) in
            // Populate the cell with our item description.
            var contentConfiguration = cell.defaultContentConfiguration()
            contentConfiguration.text = menuItem.title
            contentConfiguration.textProperties.font = .preferredFont(forTextStyle: .headline)
            cell.contentConfiguration = contentConfiguration
            
            let disclosureOptions = UICellAccessory.OutlineDisclosureOptions(style: .header)
            cell.accessories = [.outlineDisclosure(options:disclosureOptions)]
            cell.backgroundConfiguration = UIBackgroundConfiguration.clear()
        }
        
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, OutlineItem> { cell, indexPath, menuItem in
            // Populate the cell with our item description.
            var contentConfiguration = cell.defaultContentConfiguration()
            contentConfiguration.text = menuItem.title
            cell.contentConfiguration = contentConfiguration
            cell.backgroundConfiguration = UIBackgroundConfiguration.clear()
        }
        
        dataSource = UICollectionViewDiffableDataSource<Section, OutlineItem>(collectionView: outlineCollectionView) {
            (collectionView: UICollectionView, indexPath: IndexPath, item: OutlineItem) -> UICollectionViewCell? in
            // Return the cell.
            if item.subitems.isEmpty {
                return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
            } else {
                return collectionView.dequeueConfiguredReusableCell(using: containerCellRegistration, for: indexPath, item: item)
            }
        }

        // load our initial data
        let snapshot = initialSnapshot()
        self.dataSource.apply(snapshot, to: .main, animatingDifferences: false)
		#else
		outlineCollectionView.register(
			view: {
				UICollectionViewListCell()
			},
			.config {
                let cell = $0.view
                let menuItem = $0.data
				var contentConfiguration = cell.defaultContentConfiguration()
				contentConfiguration.text = menuItem.title
				contentConfiguration.textProperties.font = .preferredFont(forTextStyle: .headline)
				cell.contentConfiguration = contentConfiguration
				
				let disclosureOptions = UICellAccessory.OutlineDisclosureOptions(style: .header)
				cell.accessories = [.outlineDisclosure(options:disclosureOptions)]
				cell.backgroundConfiguration = UIBackgroundConfiguration.clear()
			},
			.when {
				!$0.data.subitems.isEmpty
			}
		)
		outlineCollectionView.register(
			view: {
				UICollectionViewListCell()
			},
			.config {
                let cell = $0.view
                let menuItem = $0.data
				var contentConfiguration = cell.defaultContentConfiguration()
				contentConfiguration.text = menuItem.title
				cell.contentConfiguration = contentConfiguration
				cell.backgroundConfiguration = UIBackgroundConfiguration.clear()
			},
			.tap { [weak self] in
                let menuItem = $0.data
                let indexPath = $0.indexPath
                self?.outlineCollectionView.deselectItem(at: indexPath, animated: true)
				
				if let viewController = menuItem.outlineViewController {
					self?.navigationController?.pushViewController(viewController.init(), animated: true)
				}
			},
			.when {
				$0.data.subitems.isEmpty
			}
		)

		outlineCollectionView.dataManager.appendSections([Section.main])
		
        outlineCollectionView.dataManager.appendChildItems(menuItems, to: nil, recursivePath: \.subitems)
		#endif
    }

    func generateLayout() -> UICollectionViewLayout {
        let listConfiguration = UICollectionLayoutListConfiguration(appearance: .sidebar)
        let layout = UICollectionViewCompositionalLayout.list(using: listConfiguration)
        return layout
    }

    func initialSnapshot() -> NSDiffableDataSourceSectionSnapshot<OutlineItem> {
        var snapshot = NSDiffableDataSourceSectionSnapshot<OutlineItem>()

        func addItems(_ menuItems: [OutlineItem], to parent: OutlineItem?) {
            snapshot.append(menuItems, to: parent)
            for menuItem in menuItems where !menuItem.subitems.isEmpty {
                addItems(menuItem.subitems, to: menuItem)
            }
        }
        
        addItems(menuItems, to: nil)
        return snapshot
    }

}

extension OutlineViewController: UICollectionViewDelegate {
	#if OfficialDemo
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let menuItem = self.dataSource.itemIdentifier(for: indexPath) else { return }
        
        collectionView.deselectItem(at: indexPath, animated: true)
        
        if let viewController = menuItem.outlineViewController {
            navigationController?.pushViewController(viewController.init(), animated: true)
        }
        
    }
	#endif
}
