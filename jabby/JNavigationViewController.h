//
//  JNavigationViewController.h
//  jabby
//
//  Created by 林 炬 on 14-3-22.
//  Copyright (c) 2014年 soasme. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PBFlatSettings.h"
#import "UINavigationBar+FlatUI.h"
#import "UIColor+FlatUI.h"
#import "JIMCenter.h"
#import "PBFlatRoundedImageView.h"


@interface JNavigationViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *logoutButton;

@end
