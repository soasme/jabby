//
//  JLoginViewController.h
//  jabby
//
//  Created by 林 炬 on 14-3-14.
//  Copyright (c) 2014年 soasme. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JLoginViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *accountLabel;
@property (weak, nonatomic) IBOutlet UILabel *passwordLabel;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
- (IBAction)didLoginButtonTouchDown:(id)sender;

@end
