# ConfigableCollectionView

## [中文文档](https://github.com/miku1958/ConfigableCollectionView/blob/master/README.cn.md)

Create CollectionView in a similar way to new DataSource introdeced in iOS 13

The demo is based on Apple's ImplementingModernCollectionViews.

## Advantages

### Over 90% of test coverage

### More iOS version support

UICollectionViewDiffableDataSource: iOS 13 required

ConfigableCollectionView: iOS 9 required, but technically supporting all iOS versions since iOS 6

### Safer

UICollectionViewDiffableDataSource: once you append a repeated object, it crashes, even in release, and it doesn't someTimes in some iOS versions

ConfigableCollectionView : only assert during debugging when you append a repetitive object

### Easlier

No distinction between NSDiffableDataSourceSectionSnapshot and NSDiffableDataSourceSnapshot

The touch to cell is based on hittest rather than cell.bounds(this is how UICollectionView work), so you can override the view’s hittest you use to make sure your tap action works properly.

### Multiple Item types and Sections supported! 

UICollectionViewDiffableDataSource : only supports one Section type and one Item type

ConfigableCollectionView: multiple items and sections supported!

## Usage

### initialization

#### Use for specific Item type

```swift
let collectionView = CollectionView<Section, Item>(layout: generateLayout())
```

#### Support multiple Item types with multiple Section types

```swift
let collectionView = CollectionView<Any, Any>(layout: generateLayout())
```

## register

#### Use for specific Item type

```swift
collectionView.register(
  view: { // create view for reuse
    UICollectionViewListCell()
  },
  .config { // config the UICollectionViewListCell with Item
    let cell = $0.view
    let item = $0.data
    var contentConfiguration = cell.defaultContentConfiguration()
    contentConfiguration.text = item.title
    contentConfiguration.textProperties.font = .preferredFont(forTextStyle: .headline)
    cell.contentConfiguration = contentConfiguration

    let disclosureOptions = UICellAccessory.OutlineDisclosureOptions(style: .header)
    cell.accessories = [.outlineDisclosure(options:disclosureOptions)]
    cell.backgroundConfiguration = UIBackgroundConfiguration.clear()
  },
  .when { // Optional, deciding when to use this type of view if need
    !$0.data.subitems.isEmpty
  }
)

collectionView.register(
  view { // create normal view for reuse
    ContentView()
  },
  .config(map: \.title) { // config the ContentView with Item.title, configurationState: UICellConfigurationState(introduced in iOS 14) 
    $0.view.data = $0.data
    if $0.configurationState.isHighlighted {
    	$0.view.backgroundColor = .red
    }
    ...
  },
  .flowLayoutSize { _ in // Optional, deciding the size in flow layout
    CGSize(width: 100, height: 100)
  },
  .tap { _ in  // Optional, deciding what to do after tap the view
    Router.push( ... )
  }
)
...
```

#### Use multiple Item types

```swift
collectionView.register(
  dataType: Int.self,
  view {
    ContentView()
  },
  .config {
    $0.view.data = $0.data
  }
)
collectionView.register(
  dataType: String.self,
  view {
    UILabel()
  },
  .config {
    $0.view.text = $0.data
  }
)
```

#### The view closure is a ViewBuilder that supports weak reference of object w hen config view once the view is created, like

```swift
collectionView.register(
  dataType: Int.self,
  view { [weak self] in
    if let color = self?.color {
      ContentView(color: color)
    }
  },
  .config {
    $0.view.data = $0.data
  }
)
```

Attention: if using subClass of UICollectionViewCell, it won't use the view closure to create the view, rather than using UICollectionView.dequeue.



### Set up data, very similar to the UICollectionViewDiffableDataSource

like:

```swift
collectionView.dataManager.appendSections([Section.main])
collectionView.dataManager.appendItems(mountains)
or just
collectionView.dataManager.applyItems(mountains, updatedSection: Section.main)
```

or: 

support recursivePath in appendChildItems

```swift
collectionView.dataManager.appendChildItems(menuItems, to: nil, recursivePath: \.subitems)
is equal to:
func addItems(_ menuItems: [OutlineItem], to parent: OutlineItem?) {
    collectionView.dataManager.appendChildItems(menuItems, to: parent)
    for menuItem in menuItems where !menuItem.subitems.isEmpty {
        addItems(menuItem.subitems, to: menuItem)
    }
}
addItems(menuItems, to: nil)
```

or: 

use multi type of Item in the same section

```swift
let numbers: [Int]
let stings: [String]

collectionView.dataManager.appendItems(numbers)
collectionView.dataManager.appendItems(stings)

collectionView.register(
  dataType: Int.self,
  view {
    NumberView()
  }
)
collectionView.register(
  dataType: String.self,
  view {
    UILabel()
  }
)
```

Animating & update completion callback, using .on(animatingDifferences: completion) after all data handling functions, like:

```swift
collectionView.dataManager.appendItems(stings)
.on(animatingDifferences: false, completion: { print("appended") })
```

For more on usage, check out the difference in ImplementingModernCollectionViews.

## Attention 

To support the old iOS version, it is using NSDiffableDataSourceSnapshot above iOS 13, and using the data directly into a CustomUICollectionViewDataSource below iOS 13, to reduce the count of recreated NSDiffableDataSourceSnapshot instances, so the reload cells of CollectionView are async. To avoid that you can call the reloadImmediately()

You can use your own UICollectionViewDelegate(some delegate functions won't call), but you can't reset the UICollectionViewDataSource.

Known Issues:

The filter on appending children is not achieved due to performance issues, so it still adds to NSDiffableDataSourceSectionSnapshot directly, and crashes if you add a repetitive object in the release.

Because it will recreate NSDiffableDataSourceSnapshot instances, and if you use the data handling function above in iOS 14 based on NSDiffableDataSourceSnapshot, it won't save the expanded state, and if you change the data, it will collapse all items.

## Installation

pod 'ConfigableCollectionView'

## TODO List

- [ ] High performance filter for appending children.
- [ ] Distinguish the achievements of data handling functions above iOS 13 to solve the problem of recreating NSDiffableDataSourceSnapshot instances.
- [ ] Remove Proxy.m to support Swift package manager or wait for it support .m files.
- [ ] tvOS support.

