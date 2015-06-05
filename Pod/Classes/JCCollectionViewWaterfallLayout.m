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

@property (nonatomic, strong) NSMutableArray *itemAttributes;
@property (nonatomic, strong) NSMutableArray *supplementaryAttributes;

@property (nonatomic, assign) CGFloat contentHeight;

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
    self.itemAttributes = [[NSMutableArray alloc] initWithCapacity:10];
    self.supplementaryAttributes = [[NSMutableArray alloc] initWithCapacity:10];
    
    CGFloat itemWidth = ([UIScreen mainScreen].bounds.size.width-self.sectionInset.left-self.sectionInset.right-(self.columnCount-1)*self.minimumInteritemSpacing)/self.columnCount;
    
    self.itemSize = CGSizeMake(itemWidth, itemWidth);
}

#pragma mark -

//设置一些必要的layout的结构和初始需要的参数
- (void)prepareLayout
{
    self.delegate = (id<JCCollectionViewWaterfallLayoutDelegate>)self.collectionView.delegate;
    
    self.contentHeight = 0;
    [self.itemAttributes removeAllObjects];
    [self.supplementaryAttributes removeAllObjects];
    
    NSInteger numberOfSections = [self.collectionView numberOfSections];

    for (NSInteger section = 0; section < numberOfSections; section++) {
        CGFloat minimumInteritemSpacing = [self minimumInteritemSpacingForSection:section];
        CGFloat minimumLineSpacing = [self minimumLineSpacingForSection:section];
        UIEdgeInsets sectionInset = [self sectionInsetForSection:section];
        NSInteger columnCount = [self columnCountForSection:section];
        CGFloat headerHeight = [self headerHeightForSection:section];
        CGFloat footerHeight = [self footerHeightForSection:section];
        
        NSMutableDictionary *supplementary = [[NSMutableDictionary alloc] initWithCapacity:2];
        
        self.contentHeight += sectionInset.top;
        
        //header
        if (headerHeight > 0) {
            UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader withIndexPath:[NSIndexPath indexPathForItem:0 inSection:section]];
            attributes.frame = CGRectMake(0, self.contentHeight, self.collectionView.frame.size.width, headerHeight);
            
            [self.itemAttributes addObject:attributes];
            [supplementary setObject:attributes forKey:UICollectionElementKindSectionHeader];
            
            self.contentHeight = CGRectGetMaxY(attributes.frame);
        }
        
        NSMutableArray *columnHeights = [[NSMutableArray alloc] initWithCapacity:columnCount];
        
        for (NSInteger i = 0; i < columnCount; i++) {
            columnHeights[i] = @(self.contentHeight);
        }

        //item
        NSInteger itemCount = [self.collectionView numberOfItemsInSection:section];

        for (NSInteger i = 0; i < itemCount; i++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:section];
            
            NSInteger columnIndex = [columnHeights indexOfObject:[columnHeights valueForKeyPath:@"@min.self"]];
            
            CGSize size = [self itemSizeForIndexPath:indexPath];
            CGFloat x = sectionInset.left + (size.width + minimumInteritemSpacing) * columnIndex;
            
            UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
            attributes.frame = CGRectMake(x, [columnHeights[columnIndex] floatValue], size.width, size.height);
            
            [self.itemAttributes addObject:attributes];
           
            columnHeights[columnIndex] = @(CGRectGetMaxY(attributes.frame) + minimumLineSpacing);
        }
        
        self.contentHeight = [[columnHeights valueForKeyPath:@"@max.self"] floatValue];
        
        //footer
        if (footerHeight > 0) {
            UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionFooter withIndexPath:[NSIndexPath indexPathForItem:0 inSection:section]];
            attributes.frame = CGRectMake(0, self.contentHeight, self.collectionView.frame.size.width, footerHeight);
            
            [self.itemAttributes addObject:attributes];
            [supplementary setObject:attributes forKey:UICollectionElementKindSectionFooter];
            
            self.contentHeight = CGRectGetMaxY(attributes.frame);
        }
        
        [self.supplementaryAttributes addObject:supplementary];
        
        self.contentHeight += sectionInset.bottom;
    }
}

//设置collectionView的contentsize
- (CGSize)collectionViewContentSize
{
    return CGSizeMake(self.collectionView.frame.size.width, self.contentHeight);
}

//返回指定rect中的所有的元素的布局属性
- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    return [self.itemAttributes filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(UICollectionViewLayoutAttributes *evaluatedObject, NSDictionary *bindings) {
        return CGRectIntersectsRect(rect, evaluatedObject.frame);
    }]];
}

//返回对应于indexPath的位置的cell的布局属性
- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger index = indexPath.item;
    
    for (NSInteger section = 0; section < indexPath.section; section++) {
        index += [self.collectionView numberOfItemsInSection:section];
    }
    
    return self.itemAttributes[index];
}

//返回对应于indexPath的位置的追加视图的布局属性
- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    return self.supplementaryAttributes[indexPath.section][kind];
}

//当边界发生改变时，是否重新计算需要的布局信息。
- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    CGRect oldBounds = self.collectionView.bounds;
    
    if (CGRectGetWidth(newBounds) != CGRectGetWidth(oldBounds)) {
        return YES;
    }
    
    return NO;
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
