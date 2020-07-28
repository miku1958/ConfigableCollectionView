# ConfigableCollectionView
Create CollectionView in a similar way to iOS 13

The demo used to compare Apple's ImplementingModernCollectionViews is still in production.

## Advantages compared to UICollectionViewDiffableDataSource and UICollectionView.CellRegistration

### 90% of test coverage

### Safer

UICollectionViewDiffableDataSource: once you append a repeated object, it crashes, even in release, and it doesn't someTimes in some iOS versions

ConfigableCollectionView : only assert during debugging when you append a repetitive object

### Easlier

No distinction between NSDiffableDataSourceSectionSnapshot and NSDiffableDataSourceSnapshot

### Multiple Item types and Sections supported! 

UICollectionViewDiffableDataSource : only supports one Section type and one Item type

ConfigableCollectionView: multiple items and sections supported! 

## Usage

### Attention! After I finish the comparison and release the demo, the grammar may becomes more straightforward.

### initialization

#### Use for specific model types

```swift
let collectionView = CollectionView<Section, Item>(layout: generateLayout()) // CollectionView<Section, Item>
```

#### Support multiple model types with multiple section types

```swift
let collectionView = CollectionView<Section, Any>(layout: generateLayout()) // CollectionView<Section, Any>
```



## register

#### Use for specific model types

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

#### Use multiple model types

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

The view closure is a ViewBuilder that supports weak reference of object w hen config view once the view is created, like

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



### set up data, very similar to the UICollectionViewDiffableDataSource

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
```

or: 

multi type of Item and Section support

```
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

For more on usage, check out the difference in ImplementingModernCollectionViews.