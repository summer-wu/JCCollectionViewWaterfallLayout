//
//  JCCollectionViewWaterfallLayout.m
//  JCCollectionViewWaterfallLayout
//
//  Created by 李京城 on 15/6/4.
//  Copyright (c) 2015年 李京城. All rights reserved.
//

#import "JCCollectionViewWaterfallLayout.h"

@interface JCCollectionViewWaterfallLayout()

@property (nonatomic, weak) id<JCCollectionViewWaterfallLayoutDelegate> delegate;

@property (nonatomic, strong) NSMutableArray *allItemSize;
@property (nonatomic, strong) NSMutableArray *columnHeights;
@property (nonatomic, strong) NSMutableArray *supplementaryAttributes;
@property (nonatomic, strong) NSMutableArray *allItemAttributes;

@end

@implementation JCCollectionViewWaterfallLayout

- (id)init
{
    self = [super init];
    
    if (self) {
        [self setup];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        [self setup];
    }
    
    return self;
}

- (void)setup
{
    self.minimumInteritemSpacing = 5.0f;
    self.minimumLineSpacing = 5.0f;
    self.sectionInset = UIEdgeInsetsMake(5.0f, 5.0f, 5.0f, 5.0f);
    
    self.columnCount = 2;
    self.headerHeight = 0.0f;
    self.footerHeight = 0.0f;
    self.allItemSize = [[NSMutableArray alloc] initWithCapacity:10];
    self.allItemAttributes = [[NSMutableArray alloc] initWithCapacity:10];
    self.supplementaryAttributes = [[NSMutableArray alloc] initWithCapacity:10];
    self.columnHeights = [[NSMutableArray alloc] initWithCapacity:10];
    
    CGFloat itemWidth = ([UIScreen mainScreen].bounds.size.width-self.sectionInset.left-self.sectionInset.right-(self.columnCount-1)*self.minimumInteritemSpacing)/self.columnCount;
    
    self.itemSize = CGSizeMake(itemWidth, itemWidth);
}

#pragma mark -
//- (void)prepareForCollectionViewUpdates:(NSArray *)updateItems;
//1、设定一些必要的layout的结构和初始需要的参数
- (void)prepareLayout
{
    [super prepareLayout];
    
    self.delegate = (id<JCCollectionViewWaterfallLayoutDelegate>)self.collectionView.delegate;
    
    [self.allItemAttributes removeAllObjects];
    [self.supplementaryAttributes removeAllObjects];
    [self.columnHeights removeAllObjects];
    
    NSInteger numberOfSections = [self.collectionView numberOfSections];
    
    for (NSInteger section = 0; section < numberOfSections; section++) {
        NSInteger columnCount = [self columnCountForSection:section];
        NSMutableArray *sectionColumnHeights = [NSMutableArray arrayWithCapacity:columnCount];
        for (NSInteger idx = 0; idx < columnCount; idx++) {
            [sectionColumnHeights addObject:@(0)];
        }
        [self.columnHeights addObject:sectionColumnHeights];
    }
    
    for (NSInteger section = 0; section < numberOfSections; section++) {
        NSInteger columnCount = [self columnCountForSection:section];
        CGFloat minimumInteritemSpacing = [self minimumInteritemSpacingForSection:section];
        UIEdgeInsets sectionInset = [self sectionInsetForSection:section];
        
        CGFloat itemWidth = floorf(([UIScreen mainScreen].bounds.size.width-sectionInset.left-sectionInset.right-(columnCount-1)*minimumInteritemSpacing)/columnCount);
        
        NSInteger itemCount = [self.collectionView numberOfItemsInSection:section];
        
        if (self.allItemSize.count != itemCount) {
            [self.allItemSize removeAllObjects];
            
            for (NSInteger row = 0; row < itemCount; row++) {
                CGSize itemSize = [self itemSizeForIndexPath:[NSIndexPath indexPathForItem:row inSection:section]];
                
                //                NSLog(@"%@",NSStringFromCGSize(itemSize));
                
                [self.allItemSize addObject:NSStringFromCGSize(CGSizeMake(itemWidth, itemSize.height))];
            }
        }
    }
    
    CGFloat top = 0;
    
    for (NSInteger section = 0; section < numberOfSections; section++) {
        CGFloat minimumInteritemSpacing = [self minimumInteritemSpacingForSection:section];
        CGFloat minimumLineSpacing = [self minimumLineSpacingForSection:section];
        UIEdgeInsets sectionInset = [self sectionInsetForSection:section];
        NSInteger columnCount = [self columnCountForSection:section];
        CGFloat headerHeight = [self headerHeightForSection:section];
        CGFloat footerHeight = [self footerHeightForSection:section];
        
        NSMutableDictionary *supplementary = [[NSMutableDictionary alloc] initWithCapacity:2];
        
        //header
        if (headerHeight > 0) {
            UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader withIndexPath:[NSIndexPath indexPathForItem:0 inSection:section]];
            attributes.frame = CGRectMake(0, top, self.collectionView.frame.size.width, headerHeight);
            
            [self.allItemAttributes addObject:attributes];
            [supplementary setObject:attributes forKey:UICollectionElementKindSectionHeader];
            
            top = CGRectGetMaxY(attributes.frame);
        }
        
        top += sectionInset.top;
        for (NSInteger idx = 0; idx < columnCount; idx++) {
            self.columnHeights[section][idx] = @(top);
        }
        
        //item
        NSInteger itemCount = [self.collectionView numberOfItemsInSection:section];
        CGFloat itemWidth = floorf(([UIScreen mainScreen].bounds.size.width-sectionInset.left-sectionInset.right-(columnCount-1)*minimumInteritemSpacing)/columnCount);
        
        for (NSInteger i = 0; i < itemCount; i++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:section];
            NSUInteger columnIndex = i % columnCount;
            
            CGFloat offsetX = sectionInset.left + (itemWidth + minimumInteritemSpacing) * columnIndex;
            CGFloat offsetY = [self.columnHeights[section][columnIndex] floatValue];
            
            CGSize itemSize = CGSizeFromString(self.allItemSize[i]);
            
            UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
            attributes.frame = CGRectMake(offsetX, offsetY, itemSize.width, itemSize.height);
            
            [self.allItemAttributes addObject:attributes];
            self.columnHeights[section][columnIndex] = @(CGRectGetMaxY(attributes.frame) + minimumLineSpacing);
        }
        
        //footer
        NSUInteger columnIndex = [self longestColumnIndexInSection:section];
        top = [self.columnHeights[section][columnIndex] floatValue] - self.minimumInteritemSpacing + self.sectionInset.bottom;
        
        if (footerHeight > 0) {
            UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionFooter withIndexPath:[NSIndexPath indexPathForItem:0 inSection:section]];
            attributes.frame = CGRectMake(0, top, self.collectionView.frame.size.width, footerHeight);
            
            [self.allItemAttributes addObject:attributes];
            [supplementary setObject:attributes forKey:UICollectionElementKindSectionFooter];
            
            top = CGRectGetMaxY(attributes.frame);
        }
        
        [self.supplementaryAttributes addObject:supplementary];
        
        for (NSInteger idx = 0; idx < columnCount; idx++) {
            self.columnHeights[section][idx] = @(top);
        }
        
        NSLog(@"%f", [self.columnHeights[section][(columnCount-1)] floatValue]);
    }
}

//2、设定collectionView的contentsize
- (CGSize)collectionViewContentSize
{
    NSInteger numberOfSections = [self.collectionView numberOfSections];
    NSUInteger longestColumnIndex = [self longestColumnIndexInSection:numberOfSections-1];
    
    CGSize contentSize = self.collectionView.bounds.size;
    contentSize.height = [[self.columnHeights lastObject][longestColumnIndex] floatValue];
    NSLog(@"111   %@",NSStringFromCGSize(contentSize));
    return contentSize;
}

//3、返回rect中的所有的元素的布局属性
- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    return [self.allItemAttributes filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(UICollectionViewLayoutAttributes *evaluatedObject, NSDictionary *bindings) {
        return CGRectIntersectsRect(rect, evaluatedObject.frame);
    }]];
}

//返回对应于indexPath的位置的cell的布局属性
- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger index = indexPath.row;
    
    for (NSInteger section = 0; section < indexPath.section; section++) {
        index += [self.collectionView numberOfItemsInSection:section];
    }
    
    return self.allItemAttributes[index];
}

//返回对应于indexPath的位置的追加视图的布局属性
- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    return self.supplementaryAttributes[indexPath.section][kind];
}

//当边界发生改变时，是否应该刷新布局。如果YES则在边界变化（一般是scroll到其他地方）时，将重新计算需要的布局信息。
- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    CGRect oldBounds = self.collectionView.bounds;
    
    if (CGRectGetWidth(newBounds) != CGRectGetWidth(oldBounds)) {
        return YES;
    }
    
    return NO;
}

#pragma mark -

//- (CGSize)updateItemSize:(CGSize)newSize at:(NSIndexPath *)indexPath
//{
//    NSInteger index = indexPath.row;
//    
//    for (NSInteger section = 0; section < indexPath.section; section++) {
//        index += [self.collectionView numberOfItemsInSection:section];
//    }
//    
//    CGSize itemSize = CGSizeMake(self.itemSize.width, floorf(newSize.height * self.itemSize.width / newSize.width));
//    
//    [self.allItemSize replaceObjectAtIndex:index withObject:NSStringFromCGSize(itemSize)];
//    
//    return itemSize;
//}

- (NSUInteger)longestColumnIndexInSection:(NSInteger)section
{
    __block NSUInteger index = 0;
    __block CGFloat longestHeight = 0;
    
    [self.columnHeights[section] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CGFloat height = [obj floatValue];
        if (height > longestHeight) {
            longestHeight = height;
            index = idx;
        }
    }];
    
    return index;
}

#pragma mark -

- (NSInteger)columnCountForSection:(NSInteger)section
{
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:columnCountForSection:)]) {
        return [self.delegate collectionView:self.collectionView layout:self columnCountForSection:section];
    }
    else {
        return self.columnCount;
    }
}

- (CGFloat)headerHeightForSection:(NSInteger)section
{
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:heightForHeaderInSection:)]) {
        return [self.delegate collectionView:self.collectionView layout:self heightForHeaderInSection:section];
    }
    else {
        return self.headerHeight;
    }
}

- (CGFloat)footerHeightForSection:(NSInteger)section
{
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:heightForFooterInSection:)]) {
        return [self.delegate collectionView:self.collectionView layout:self heightForFooterInSection:section];
    }
    else {
        return self.footerHeight;
    }
}

- (UIEdgeInsets)sectionInsetForSection:(NSInteger)section
{
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:insetForSectionAtIndex:)]) {
        return [self.delegate collectionView:self.collectionView layout:self insetForSectionAtIndex:section];
    }
    else {
        return self.sectionInset;
    }
}

- (CGFloat)minimumInteritemSpacingForSection:(NSInteger)section
{
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:minimumInteritemSpacingForSectionAtIndex:)]) {
        return [self.delegate collectionView:self.collectionView layout:self minimumInteritemSpacingForSectionAtIndex:section];
    }
    else {
        return self.minimumInteritemSpacing;
    }
}

- (CGFloat)minimumLineSpacingForSection:(NSInteger)section
{
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:minimumLineSpacingForSectionAtIndex:)]) {
        return [self.delegate collectionView:self.collectionView layout:self minimumLineSpacingForSectionAtIndex:section];
    }
    else {
        return self.minimumLineSpacing;
    }
}

- (CGSize)itemSizeForIndexPath:(NSIndexPath *)indexPath
{
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:sizeForItemAtIndexPath:)]) {
        CGSize size = [self.delegate collectionView:self.collectionView layout:self sizeForItemAtIndexPath:indexPath];
        
        return CGSizeMake(self.itemSize.width, floorf(size.height * self.itemSize.width / size.width));
    }
    else {
        return self.itemSize;
    }
}

@end
