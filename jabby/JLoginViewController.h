//
//  JLoginViewController.h
//  jabby
//
//  Created by 林 炬 on 14-3-14.
//  Copyright (c) 2014年 soasme. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JAppDelegate.h"
#import "FlatUIKit.h"

@interface JLoginViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextField *accountInput;
@property (weak, nonatomic) IBOutlet UITextField *passwordInput;
@property (weak, nonatomic) IBOutlet UILabel *accountLabel;
@property (weak, nonatomic) IBOutlet UILabel *passwordLabel;
@property (weak, nonatomic) IBOutlet FUIButton *loginButton;
- (IBAction)didLoginButtonTouchDown:(id)sender;
- (JAppDelegate *)appDelegate;
@end
