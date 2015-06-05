//
//  JCCollectionFooterView.m
//  JCCollectionViewWaterfallLayout
//
//  Created by 李京城 on 15/6/4.
//  Copyright (c) 2015年 lijingcheng. All rights reserved.
//

#import "JCCollectionFooterView.h"

@implementation JCCollectionFooterView

- (void)awakeFromNib
{
    
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    self.titleLabel.text = @"";
}

@end
