//
//  CollectionViewDelegateProxy.m
//  ConfigableCollectionView
//
//  Created by 庄黛淳华 on 2020/3/7.
//  Copyright © 2020 庄黛淳华. All rights reserved.
//

#import "CollectionViewDelegateProxy.h"
#import <objc/runtime.h>

#define NSSEL CollectionViewDelegateProxy_SEL
@interface NSSEL: NSObject<NSCopying>
@property (nonatomic, assign) SEL sel;
@property (nonatomic, copy) NSString *name;
@end
@implementation NSSEL
+ (instancetype)selWith:(SEL)sel {
	return [[self alloc]initWithSEL: sel];
}
- (instancetype)initWithSEL:(SEL)sel {
	self = [super init];
	if (self) {
		_sel = sel;
		_name = NSStringFromSelector(_sel);
	}
	return self;
}
- (BOOL)isEqual:(NSSEL *)other {
	return _sel == other.sel;
}

- (NSUInteger)hash {
	return (NSUInteger)sel_getName(_sel);
}
- (nonnull id)copyWithZone:(nullable NSZone *)zone {
	return [NSSEL selWith: _sel];
}
- (NSString *)description {
	return _name;
}
- (NSString *)debugDescription {
	return _name;
}

@end

typedef BOOL (^ShouldRespond)(void);

static NSArray<NSSEL *> *allDelegateMethod;
static NSArray<NSSEL *> *allDataSourceMethod;
@interface CollectionViewDelegateProxy()
@property (nonatomic, strong) NSMutableDictionary<NSSEL *, NSHashTable *> *methodsMap;
@property (nonatomic, strong) NSDictionary<NSSEL *, ShouldRespond> *respondChecker;

@property (nonatomic, strong) NSHashTable<UICollectionViewDelegate> *customDelegates;
@property (nonatomic, strong) NSHashTable<UICollectionViewDataSource> *customDatasources;
@end

@implementation CollectionViewDelegateProxy
- (instancetype)initWithCollection:(UICollectionView *)collection {
	_collection = collection;
	_methodsMap = [NSMutableDictionary dictionary];
	_customDatasources = (id)[NSHashTable weakObjectsHashTable];
	_customDelegates = (id)[NSHashTable weakObjectsHashTable];
	[self initChecker];
	[self initMethods];
	return self;
}
- (instancetype)initWithProxy:(CollectionViewDelegateProxy *)proxy {
	_customDelegates = proxy.customDelegates;
	_customDatasources = proxy.customDatasources;
	_methodsMap = proxy.methodsMap;
	_mainDelegate = proxy.mainDelegate;
	_collection = proxy.collection;
	[self initChecker];
	[self initMethods];
	return self;
}
- (void)initChecker {
//	__weak typeof(_collection) collection = _collection;
	_respondChecker = @{
//		[NSSEL selWith: @selector(collectionView:layout:sizeForItemAtIndexPath:)] : ^BOOL () {
//			if (![collection.collectionViewLayout isKindOfClass: UICollectionViewFlowLayout.class]) {
//				return true;
//			}
//			UICollectionViewFlowLayout *layout = (id)collection.collectionViewLayout;
//			return !CGSizeEqualToSize(layout.itemSize, UICollectionViewFlowLayoutAutomaticSize);
//		}
	};
}
- (NSArray<NSSEL *> *)instanceMethodsFor:(Protocol *)protocol {
	NSMutableArray *methods = [NSMutableArray array];
	unsigned int count = 0;
	struct objc_method_description *lists = protocol_copyMethodDescriptionList(protocol, false, true, &count);
	int index = 0;
	while (index<count) {
		[methods addObject: [[NSSEL alloc]initWithSEL: lists[index].name]];
		index += 1;
	}
	return methods;
}
- (void)initMethods {
	if (allDataSourceMethod == nil) {
		allDataSourceMethod = [self instanceMethodsFor: NSProtocolFromString(@"UICollectionViewDataSource")];
	}
	if (allDelegateMethod == nil) {
		allDelegateMethod = [self instanceMethodsFor: NSProtocolFromString(@"UICollectionViewDelegate")];
	}
}
- (BOOL)setObj:(id)obj forSEL:(NSSEL *)sel filterMainDelegate:(BOOL)filter {
	if (![obj respondsToSelector:sel.sel]) {
		return false;
	}
	if (_methodsMap[sel] == nil) {
		_methodsMap[sel] = [NSHashTable hashTableWithOptions: NSPointerFunctionsWeakMemory];
	}
	if (filter && [_methodsMap[sel] containsObject: _mainDelegate]) {
		return true;
	}
	[_methodsMap[sel] addObject: obj];
	return true;
}

- (void)setMainDelegate:(id)mainDelegate {
	_mainDelegate = mainDelegate;
	
	for (NSSEL *sel in allDelegateMethod) {
		[self setObj: mainDelegate forSEL: sel filterMainDelegate: false];
	}
	
	for (NSSEL *sel in allDataSourceMethod) {
		[self setObj: mainDelegate forSEL: sel filterMainDelegate: false];
	}
}

- (void)addDelegates:(id<UICollectionViewDelegate>)delegate {
	if (delegate == nil) {
		return;
	}
	[_customDelegates addObject: delegate];
	for (NSSEL *sel in allDelegateMethod) {
		[self setObj: delegate forSEL: sel filterMainDelegate: true];
	}
}
- (void)addDatasources:(id<UICollectionViewDataSource>)dataSource {
	if (dataSource == nil) {
		return;
	}
	[_customDatasources addObject: dataSource];
	for (NSSEL *sel in allDataSourceMethod) {
		[self setObj: dataSource forSEL: sel filterMainDelegate: true];
	}
}
@end

@implementation CollectionViewDelegateProxy(proxy)
- (void)findResponderForSEL:(NSSEL *)sel {
	[self setObj: _mainDelegate forSEL: sel filterMainDelegate: false];
	for (id obj in _customDelegates) {
		[self setObj: obj forSEL: sel filterMainDelegate: false];
	}
	
	for (id obj in _customDatasources) {
		[self setObj: obj forSEL: sel filterMainDelegate: false];
	}
}
- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel{
	if (sel == @selector(respondsToSelector:)) {
		return [_mainDelegate methodSignatureForSelector: sel];
	}

	NSSEL *method = [NSSEL selWith: sel];
	if ([@"scrollViewDidScroll:" isEqualToString:method.name]) {
		printf("");
	}
	//在字典中查找对应的target
	id target = _methodsMap[method].anyObject;
	if (target == nil) {
		target = _mainDelegate;
	}
	return [target methodSignatureForSelector:sel];
}

- (void)forwardInvocation:(NSInvocation *)invocation{
	
	id failureTarget = nil;
	// 这里[invocation invokeWithTarget: xxx];不能传self, 否则又会回到这里

    SEL sel = invocation.selector;
	if (sel == @selector(respondsToSelector:)) {
		SEL arg;
		[invocation getArgument: &arg atIndex: 2];
		NSSEL *method = [NSSEL selWith: arg];
		ShouldRespond checker = _respondChecker[method];
		if (checker != nil && !checker()) {
			[invocation invokeWithTarget: failureTarget];
			return;
		}
		if (_methodsMap[method].count == 0) {
			if (![allDataSourceMethod containsObject: method] && ![allDelegateMethod containsObject: method]) {
				[self findResponderForSEL: method];
			}
		}
		NSHashTable * objs = _methodsMap[method];
		[invocation invokeWithTarget: objs.anyObject];
		return;
	}
	NSSEL *method = [NSSEL selWith: sel];
	NSHashTable * objs = _methodsMap[method];
	if (objs.count == 0) {
		// 类似于conformToProtocol等方法都由_mainDelegate处理就行
		[invocation invokeWithTarget: _mainDelegate];
	} else {
		for (id obj in objs) {
			[invocation invokeWithTarget: obj];
		}
	}
}
@end
