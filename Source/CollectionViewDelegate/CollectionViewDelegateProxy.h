//
//  CollectionViewDelegateProxy.h
//  ConfigableCollectionView
//
//  Created by 庄黛淳华 on 2020/3/7.
//  Copyright © 2020 庄黛淳华. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CollectionViewDelegateProxy: NSProxy<UICollectionViewDelegate, UICollectionViewDataSource>

- (instancetype)initWithCollection:(UICollectionView *)collection;
- (instancetype)initWithProxy:(CollectionViewDelegateProxy *)proxy;

@property (nullable, nonatomic, weak) UICollectionView *collection;

@property (nullable, nonatomic, strong) id mainDelegate;
@property (nonatomic, readonly) NSHashTable*customDelegates;

- (void)addDelegates:(id __nullable)delegate;
@end

NS_ASSUME_NONNULL_END
