//
//  JMasterViewController.h
//  jabby
//
//  Created by 林 炬 on 14-3-6.
//  Copyright (c) 2014年 soasme. All rights reserved.
//

#import <UIKit/UIKit.h>

@class JDetailViewController;

#import <CoreData/CoreData.h>
#import "JAppDelegate.h"
#import "PBFlatGroupedStyleCell.h"
#import "PBFlatRoundedImageView.h"
#import "PBFlatGroupedTableViewController.h"


@interface JMasterViewController : PBFlatGroupedTableViewController <NSFetchedResultsControllerDelegate,
    JFriendListDelegate, FUIAlertViewDelegate>

@property (strong, nonatomic) JDetailViewController *detailViewController;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSMutableArray *friendList;

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;


@end
