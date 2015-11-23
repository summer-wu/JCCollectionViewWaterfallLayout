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
    
    self.headerHeight = 0.0f;
    self.footerHeight = 0.0f;
    self.itemAttributes = [[NSMutableArray alloc] initWithCapacity:10];
    self.supplementaryAttributes = [[NSMutableArray alloc] initWithCapacity:10];
}

- (void)changeItemSizeWithColumnCount:(NSUInteger)columnCount{
    NSAssert(columnCount>0, @"columnCount must bigger than zero");
    CGFloat itemWidth = ([UIScreen mainScreen].bounds.size.width-self.sectionInset.left-self.sectionInset.right-(columnCount-1)*self.minimumInteritemSpacing)/columnCount;
    //itemSize vary with section
    self.itemSize = CGSizeMake(itemWidth, itemWidth);
}

#pragma mark -

- (void)prepareLayout
{
    self.contentHeight = 0;
    [self.itemAttributes removeAllObjects];
    [self.supplementaryAttributes removeAllObjects];
    
    NSInteger numberOfSections = [self.collectionView numberOfSections];
    
    for (NSInteger section = 0; section < numberOfSections; section++) {
        CGFloat minimumInteritemSpacing = [self minimumInteritemSpacingForSection:section];
        CGFloat minimumLineSpacing = [self minimumLineSpacingForSection:section];
        UIEdgeInsets sectionInset = [self sectionInsetForSection:section];
        NSInteger columnCount = [self columnCountForSection:section];
        [self changeItemSizeWithColumnCount:columnCount];
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
        
        //item
        NSInteger itemCount = [self.collectionView numberOfItemsInSection:section];
        
        NSMutableArray *columnHeights = [[NSMutableArray alloc] initWithCapacity:columnCount];
        
        for (NSInteger i = 0; i < columnCount; i++) {
            columnHeights[i] = @(self.contentHeight);
        }
        
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
        
        if (itemCount == 0) {
            self.contentHeight += [UIScreen mainScreen].bounds.size.height;
        }
        
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

- (CGSize)collectionViewContentSize
{
    return CGSizeMake(self.collectionView.frame.size.width, self.contentHeight);
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    return [self.itemAttributes filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(UICollectionViewLayoutAttributes *evaluatedObject, NSDictionary *bindings) {
        return CGRectIntersectsRect(rect, evaluatedObject.frame);
    }]];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger index = indexPath.item;
    
    for (NSInteger section = 0; section < indexPath.section; section++) {
        index += [self.collectionView numberOfItemsInSection:section];
    }
    
    return self.itemAttributes[index];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    return self.supplementaryAttributes[indexPath.section][kind];
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    CGRect oldBounds = self.collectionView.bounds;
    
    if (CGRectGetWidth(newBounds) != CGRectGetWidth(oldBounds)) {
        return YES;
    }
    
    return NO;
}

#pragma mark -

- (id<JCCollectionViewWaterfallLayoutDelegate>)delegate
{
    if (_delegate == nil) {
        _delegate =  (id<JCCollectionViewWaterfallLayoutDelegate>)self.collectionView.delegate;
    }
    
    return _delegate;
}

- (NSInteger)columnCountForSection:(NSInteger)section
{
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:columnCountForSection:)]) {
        return [self.delegate collectionView:self.collectionView layout:self columnCountForSection:section];
    }
    else {
        return 2;
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
