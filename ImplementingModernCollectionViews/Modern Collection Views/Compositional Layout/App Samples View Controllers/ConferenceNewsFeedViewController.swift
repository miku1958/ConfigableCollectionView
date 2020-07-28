/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Sample showing how we might build the news feed UI
*/

import UIKit

class ConferenceNewsFeedViewController: UIViewController {

    enum Section {
        case main
    }

    var collectionView: UICollectionView!
    var dataSource: UICollectionViewDiffableDataSource<Section, ConferenceNewsController.NewsFeedItem>!
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Conference News Feed"
        configureHierarchy()
        configureDataSource()
    }
}

extension ConferenceNewsFeedViewController {
    func configureHierarchy() {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        collectionView.backgroundColor = .systemBackground
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.topAnchor.constraint(equalTo: view.topAnchor)
        ])
    }

    func configureDataSource() {
        
        let newsController = ConferenceNewsController()
        
        let cellRegistration = UICollectionView.CellRegistration
        <ConferenceNewsFeedCell, ConferenceNewsController.NewsFeedItem> { (cell, indexPath, newsItem) in
            // Populate the cell with our item description.
            cell.titleLabel.text = newsItem.title
            cell.bodyLabel.text = newsItem.body

            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            cell.dateLabel.text = dateFormatter.string(from: newsItem.date)
            cell.showsSeparator = indexPath.item != newsController.items.count - 1
        }
        
        dataSource = UICollectionViewDiffableDataSource
        <Section, ConferenceNewsController.NewsFeedItem>(collectionView: collectionView) {
            (collectionView: UICollectionView, indexPath: IndexPath, item: ConferenceNewsController.NewsFeedItem) -> UICollectionViewCell? in
            // Return the cell.
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }

        // load our data
        let newsItems = newsController.items
        var snapshot = NSDiffableDataSourceSnapshot<Section, ConferenceNewsController.NewsFeedItem>()
        snapshot.appendSections([.main])
        snapshot.appendItems(newsItems)
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    func createLayout() -> UICollectionViewLayout {
        let estimatedHeight = CGFloat(100)
        let layoutSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .estimated(estimatedHeight))
        let item = NSCollectionLayoutItem(layoutSize: layoutSize)
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: layoutSize,
                                                       subitem: item,
                                                       count: 1)
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        section.interGroupSpacing = 10
        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }
}
