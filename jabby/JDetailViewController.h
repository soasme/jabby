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

@interface JDetailViewController : UIViewController <UISplitViewControllerDelegate, JMessageDelegate>

@property (strong, nonatomic) id detailItem;

@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
@end
