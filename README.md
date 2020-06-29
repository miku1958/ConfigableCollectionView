# ConfigableCollectionView
Create CollectionView in a similar way to iOS 14

The demo used to compare Apple's ImplementingModernCollectionViews is still in production.



## Usage

### Attention! After I finish the comparison and release the demo, the grammar may becomes more straightforward.

### initialization

#### use for specific type model

```
let collectionView = CollectionView(dataType: ClassData.self) // CollectionView<ClassData, ClassData, Void>
```

##### multi section support

```
let collectionView = CollectionView(datasType: ClassData.self) // CollectionView<[ClassData], ClassData, Void>
```

####use for multi type model, support multi section too

```
let collectionView = CollectionView() // CollectionView<Any, Any, Any>
```



## register

#### use for specific type model

```
collectionView.register(
  .view { // create view for reuse
    ContentView()
  },
  .config { view, data in // view: ContentView, data: ClassData, config the ContentView with ClassData
    view.data = data
    view.usingAnimation = true
    ...
  },
  .size { // Optional, deciding what to do after tap the view
    designHeight.max($0.sectionHeight()).ratioSizeForHeight(designRatio)
  },
  .tap { _, data in  // Optional, deciding what to do after tap the view
    Router.push( ... )
  },
  .when { data in // Optional, deciding when to use this type of view if need, 
  	data.subject == .math
  }
)
collectionView.register(
  .view { // create view for reuse
    ContentViewWihtExtraInfo()
  },
  .config { view, data in // view: ContentView, data: ClassData, config the ContentView with ClassData
    view.data = data
    view.usingAnimation = true
    ...
  },
  .when { data in // Optional, deciding when to use this type of view if need, 
  	data.subject == .english
  }
)
...
```

####use for multi type model

```
collectionView.register(
  dataType: ClassData.self,
  .view {
    ContentView()
  },

  .config { view, data in
    view.data = data
  }
)
collectionView.register(
  dataType: ClassInfo.self,
  .view {
    UILabel()
  },

  .config { view, data in
    view.text = data.text
  }
)
```



### set up data

#### use for specific type model

```
collectionView.datas = datas // datas: [ClassData] or [[ClassData]] if multi sections suppor
```

####use for multi type model

```
collectionView.datas = datas // datas: [Any] or [[Any]]
```

