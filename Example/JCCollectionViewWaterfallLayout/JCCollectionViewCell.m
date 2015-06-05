//
//  JCCollectionViewCell.m
//  JCCollectionViewWaterfallLayout
//
//  Created by 李京城 on 15/6/4.
//  Copyright (c) 2015年 lijingcheng. All rights reserved.
//

#import "JCCollectionViewCell.h"

@implementation JCCollectionViewCell

- (void)awakeFromNib
{
    
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    self.imageView.image = nil;
}

@end
