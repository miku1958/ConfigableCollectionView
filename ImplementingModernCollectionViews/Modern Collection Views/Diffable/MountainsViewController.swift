/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Sample showing how we might create a search UI using a diffable data source
*/

import UIKit
import ConfigableCollectionView

class MountainsViewController: UIViewController {

    enum Section: CaseIterable {
        case main
    }
    let mountainsController = MountainsController()
    let searchBar = UISearchBar(frame: .zero)
	#if OfficialDemo
    var mountainsCollectionView: UICollectionView!
    var dataSource: UICollectionViewDiffableDataSource<Section, MountainsController.Mountain>!
	#else
	lazy var mountainsCollectionView = CollectionView<Section, MountainsController.Mountain>(layout: createLayout())
	#endif
    var nameFilter: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Mountains Search"
        configureHierarchy()
        configureDataSource()
        performQuery(with: nil)
    }
}

extension MountainsViewController {
    /// - Tag: MountainsDataSource
    func configureDataSource() {
		#if OfficialDemo
        let cellRegistration = UICollectionView.CellRegistration
        <LabelCell, MountainsController.Mountain> { (cell, indexPath, mountain) in
            // Populate the cell with our item description.
            cell.label.text = mountain.name
        }
        
        dataSource = UICollectionViewDiffableDataSource<Section, MountainsController.Mountain>(collectionView: mountainsCollectionView) {
            (collectionView: UICollectionView, indexPath: IndexPath, identifier: MountainsController.Mountain) -> UICollectionViewCell? in
            // Return the cell.
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: identifier)
        }
		#else
		mountainsCollectionView.register(
			view: {
				LabelCell()
			},
			.config {
				$0.view.label.text = $0.data.name
			}
		)
		#endif
    }
    
    /// - Tag: MountainsPerformQuery
    func performQuery(with filter: String?) {
        let mountains = mountainsController.filteredMountains(with: filter).sorted { $0.name < $1.name }

        #if OfficialDemo
        var snapshot = NSDiffableDataSourceSnapshot<Section, MountainsController.Mountain>()
        snapshot.appendSections([.main])
        snapshot.appendItems(mountains)
        dataSource.apply(snapshot, animatingDifferences: true)
        #else
        mountainsCollectionView.dataManager.applyItems(mountains, updatedSection: Section.main)
            .on(animatingDifferences: true)
        #endif
    }
}

extension MountainsViewController {
    func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { (sectionIndex: Int,
            layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection in
            let contentSize = layoutEnvironment.container.effectiveContentSize
            let columns = contentSize.width > 800 ? 3 : 2
            let spacing = CGFloat(10)
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                  heightDimension: .fractionalHeight(1.0))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                   heightDimension: .absolute(32))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: columns)
            group.interItemSpacing = .fixed(spacing)

            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = spacing
            section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)

            return section
        }
        return layout
    }

    func configureHierarchy() {
        view.backgroundColor = .systemBackground
        #if OfficialDemo
        let layout = createLayout()
        let collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .systemBackground
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(collectionView)
        view.addSubview(searchBar)

        let views = ["cv": collectionView, "searchBar": searchBar]
        #else
        mountainsCollectionView.translatesAutoresizingMaskIntoConstraints = false
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        mountainsCollectionView.backgroundColor = .systemBackground
        mountainsCollectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(mountainsCollectionView)
        view.addSubview(searchBar)
        
        let views = ["cv": mountainsCollectionView, "searchBar": searchBar]
        #endif

        var constraints = [NSLayoutConstraint]()
        constraints.append(contentsOf: NSLayoutConstraint.constraints(
            withVisualFormat: "H:|[cv]|", options: [], metrics: nil, views: views))
        constraints.append(contentsOf: NSLayoutConstraint.constraints(
            withVisualFormat: "H:|[searchBar]|", options: [], metrics: nil, views: views))
        constraints.append(contentsOf: NSLayoutConstraint.constraints(
            withVisualFormat: "V:[searchBar]-20-[cv]|", options: [], metrics: nil, views: views))
        constraints.append(searchBar.topAnchor.constraint(
            equalToSystemSpacingBelow: view.safeAreaLayoutGuide.topAnchor, multiplier: 1.0))
        NSLayoutConstraint.activate(constraints)
        #if OfficialDemo
        mountainsCollectionView = collectionView
        #endif

        searchBar.delegate = self
    }
}

extension MountainsViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        performQuery(with: searchText)
    }
}
