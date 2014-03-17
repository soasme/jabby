//
//  JDetailViewController.h
//  jabby
//
//  Created by 林 炬 on 14-3-6.
//  Copyright (c) 2014年 soasme. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AFHTTPRequestOperationManager.h"
#import "JAppDelegate.h"
#import "JSMessagesViewController.h"
#import "PBFlatBarButtonItems.h"

@interface JDetailViewController : JSMessagesViewController ;

@property (retain, nonatomic) IBOutlet UITableView *table;
@property (weak, nonatomic) IBOutlet UINavigationItem *navigationItem;


@property (strong, nonatomic) NSDictionary* info;

@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

- (void)configureInfo:(NSDictionary *)dict;

@end
