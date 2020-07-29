# ConfigableCollectionView
用和 iOS 13 新加的 DataSource 类似的方式配置 CollectionView

实现 Demo 是根据 Apple's ImplementingModernCollectionViews 制作的.

## 优势

### 超过 90% 的代码测试覆盖率

### 支持更多的 iOS 版本

UICollectionViewDiffableDataSource: 要求 iOS13

ConfigableCollectionView: 最低支持 iOS 9, 虽然技术上来说支持 iOS6 以来的所有版本

### 更安全

UICollectionViewDiffableDataSource: 一旦你添加一个 hash 重复的数据会抛出异常导致 crash (包括在 release 下), 而且测试下来 iOS14 和 iOS13 的 API 有些会 crash 有些不会, 很混乱

ConfigableCollectionView : 只会在 debug 下进行断言判断添加的是否一个 hash 重复的数据

### 更方便

没有像 NSDiffableDataSourceSectionSnapshot 和 NSDiffableDataSourceSnapshot一样区分 API

cell 的点击是根据 hittest 而不是根据 cell.bounds 决定的( UICollectionView 会忽略 cell.bounds 外的点击, 即使你重写 Cell 的 hittest 也没有效果), 因此你可以重写你所使用的 View 的 hittest 确保你所需要的 tap action 能正常工作

### 支持不同类型的 Item 和 Sections! 

UICollectionViewDiffableDataSource : 只支持一种 Section 和一种 Item 类型

ConfigableCollectionView: 支持不同类型的 Item 和 Sections 混合使用! 

## 用法

### 初始化

#### 使用特定的 Section/Item 类型, 后续 API 都会绑定此类型

```swift
let collectionView = CollectionView<Section, Item>(layout: generateLayout())
```

#### 如果想要使用不同的 Section 或者 Item 类型, 后续 API 皆为泛型

```swift
let collectionView = CollectionView<Any, Any>(layout: generateLayout())
```

## 注册

#### 使用特定的 Item 类型

```swift
collectionView.register(
  view: { // 创建用于复用的 UICollectionViewListCell
    UICollectionViewListCell()
  },
  .config { // 用 Item 配置 UICollectionViewListCell
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
  .when { // 非必要, 过滤什么时候使用这个类型的 View
    !$0.data.subitems.isEmpty
  }
)

collectionView.register(
  view { // 创建用于复用的 ContentView
    ContentView()
  },
  .config(map: \.title) { // 用 Item.title 配置 ContentView, configurationState 是 iOS 14 新增的 UICellConfigurationState, 如果你使用UICollectionViewCell作为View则是没有用的
    $0.view.data = $0.data
    if $0.configurationState.isHighlighted {
    	$0.view.backgroundColor = .red
    }
    ...
  },
  .flowLayoutSize { _ in // 非必要, 设置 ContentView 的尺寸, 仅当使用UICollectionViewFlowLayout时有用
    CGSize(width: 100, height: 100)
  },
  .tap { _ in  // 非必要, ContentView 的点击事件
    Router.push( ... )
  }
)
...
```

#### 使用不同的 Item 类型

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

#### 这里的 view 闭包是一个 ViewBuilder, 用于支持在配置当 View 被创建的那一刻需要给 View 传参, 而这个时候可能需要弱引用来源对象(当然还是更建议放到 config 里配置), 比如:

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

注意, 如果使用的 View 是一个 UICollectionViewCell 的子类, 由于 UICollectionView 本身的限制需要使用 UICollectionView.dequeue 获取 Cell, 此时是不会使用 View 闭包来创建 Viiew 的



### 设置数据, 和 UICollectionViewDiffableDataSource 非常类似

比如:

```swift
collectionView.dataManager.appendSections([Section.main])
collectionView.dataManager.appendItems(mountains)
等价于
collectionView.dataManager.applyItems(mountains, updatedSection: Section.main)
```

又比如: 

`appendChildItems` 时支持递归路径

```swift
collectionView.dataManager.appendChildItems(menuItems, to: nil, recursivePath: \.subitems)
等价于
func addItems(_ menuItems: [OutlineItem], to parent: OutlineItem?) {
    collectionView.dataManager.appendChildItems(menuItems, to: parent)
    for menuItem in menuItems where !menuItem.subitems.isEmpty {
        addItems(menuItem.subitems, to: menuItem)
    }
}
addItems(menuItems, to: nil)
```

又比如: 

在同一个Section里使用不同的 Item 类型

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

动画和更新结束回调, 在调用操作数据的方法后使用 `.on(animatingDifferences: completion)` 即可:

```swift
collectionView.dataManager.appendItems(stings)
.on(animatingDifferences: false, completion: { print("appended") })
```

更多的用法可以查看对比上方的苹果官方 DEMO ImplementingModernCollectionViews

## 注意 

为了支持低版本 iOS, ConfigableCollectionView 在iOS13 以下则是通过一个独立的 UICollectionViewDataSource 提供支持, 而 iOS13 以上会使用 NSDiffableDataSourceSnapshot, 目前为了减少每次更新都去重新创建 NSDiffableDataSourceSnapshot, 会异步去刷新数据, 等当前调用栈结束后再去创建新的 NSDiffableDataSourceSnapshot, 如果有需要可可以通过 reloadImmediately() 去避免异步刷新

你可以使用自己的 UICollectionViewDelegate (有些代理方法不会被调用), 但你不能重新设置 UICollectionViewDataSource

已知的问题:

因为在过滤已添加的 item 时, 如果递归检查 childItems 会有严重的性能问题, 所以目前的过滤是不支持 appendChildItems 的, 使用 appendChildItems 时会直接调用 NSDiffableDataSourceSectionSnapshot 的方法, 如果存在 hash 重复的数据则会抛出异常.

因为上面提到了的每次刷新数据都会重新构建 NSDiffableDataSourceSnapshot, 所以无法记录子项的展开状态, 所以目前在 iOS14 上使用 NSDiffableDataSourceSectionSnapshot 展开子项后更新数据都会导致所有子项关闭

## 安装

pod 'ConfigableCollectionView'

## TODO 列表

- [ ] 实现高性能的支持 appending children 的过滤器
- [ ] 在 iOS13上 改为直接操作 UICollectionViewDiffableDataSource 更新数据的方式而不是通过更新内部数据后重新创建 NSDiffableDataSourceSnapshot, 以解决NSDiffableDataSourceSectionSnapshot 的子项闭合丢失问题
- [ ] 移除 Proxy.m,以支持 Swift package manager, 或者等 SPM 支持.m文件后添加 SPM 的支持
- [ ] tvOS 的支持
- [ ] 补充使用文档
