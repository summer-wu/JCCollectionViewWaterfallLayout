//
//  JCViewController.m
//  JCCollectionViewWaterfallLayout
//
//  Created by lijingcheng on 06/04/2015.
//  Copyright (c) 2014 lijingcheng. All rights reserved.
//

#import "JCViewController.h"
#import "AFNetworking.h"
#import "UIKit+AFNetworking.h"
#import "JCCollectionViewCell.h"
#import "JCCollectionHeaderView.h"
#import "JCCollectionFooterView.h"
#import "JCCollectionViewWaterfallLayout.h"

@interface JCViewController ()<UISearchBarDelegate, JCCollectionViewWaterfallLayoutDelegate>

@property (nonatomic, strong) NSMutableArray *pictures;

@property (nonatomic, strong) JCCollectionViewWaterfallLayout *layout;

@property (nonatomic, strong) UIActivityIndicatorView *activityView;

@end

@implementation JCViewController

static NSString * const reuseHeaderId = @"headerId";
static NSString * const reuseFooterId = @"footerId";
static NSString * const reuseCellId = @"cellId";

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityView];
    
    self.collectionView.backgroundColor = [UIColor yellowColor];

//    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
//    flowLayout.sectionInset = UIEdgeInsetsMake(5, 5, 5, 5);
////    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
//    flowLayout.minimumLineSpacing = 5;
//    flowLayout.minimumInteritemSpacing = 5;
//    flowLayout.itemSize = CGSizeMake(152.5, 100);
//    self.collectionView.collectionViewLayout = flowLayout;
    
    
    
    self.layout = (JCCollectionViewWaterfallLayout *)self.collectionView.collectionViewLayout;
    self.layout.headerHeight = 30.0f;
    self.layout.footerHeight = 30.0f;
    
    self.pictures = [[NSMutableArray alloc] initWithCapacity:10];
    
    [self requestPictures];
}

- (void)requestPictures
{
    [self.activityView startAnimating];
    
    NSString *url = [@"http://image.haosou.com/j?q=apple&pn=20" stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"application/javascript"];
    AFHTTPRequestOperation *operation = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [self.activityView stopAnimating];
        
        NSArray *list = [NSJSONSerialization JSONObjectWithData:operation.responseData options:NSJSONReadingMutableContainers error:nil][@"list"];
        
        [self.pictures addObjectsFromArray:list];
        
        [self.collectionView reloadData];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self.activityView stopAnimating];
        
        NSLog(@"error - %@", [error localizedDescription]);
    }];
    
    [[NSOperationQueue mainQueue] addOperation:operation];
}


#pragma mark -

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.pictures.count;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if([kind isEqual:UICollectionElementKindSectionHeader]){
        JCCollectionHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:reuseHeaderId forIndexPath:indexPath];
        
        return headerView;
    }
    else {
        JCCollectionFooterView *footerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:reuseFooterId forIndexPath:indexPath];

        return footerView;
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *dict = self.pictures[indexPath.row];
    
    return CGSizeMake([dict[@"width"] floatValue], [dict[@"height"] floatValue]);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    JCCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseCellId forIndexPath:indexPath];
    [cell.imageView setImageWithURL:[NSURL URLWithString:self.pictures[indexPath.row][@"img"]]];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"%ld", (long)indexPath.item);
}

@end
