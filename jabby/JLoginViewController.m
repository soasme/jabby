//
//  JLoginViewController.m
//  jabby
//
//  Created by 林 炬 on 14-3-14.
//  Copyright (c) 2014年 soasme. All rights reserved.
//

#import "JLoginViewController.h"


@interface JLoginViewController ()

@end



@implementation JLoginViewController

- (JAppDelegate *)appDelegate
{
    return (JAppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

-(BOOL)validateWithUser:(NSString *)userText andPass:(NSString *)passText{
    
    if (userText.length > 0 && passText.length > 0) {
        return YES;
    }
    
    return NO;
}

- (IBAction)didLoginButtonTouchDown:(id)sender {
    // TODO validate input text and dismiss after server validate.
    if ([self validateWithUser:_accountInput.text andPass:_passwordInput.text]) {
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:_accountInput.text forKey:@"UID"];
        [defaults setObject:_passwordInput.text forKey:@"PASS"];
        //保存
        [defaults synchronize];
        [[self appDelegate].imCenter connect];
        [[self appDelegate].imCenter auth];
        
        [self dismissViewControllerAnimated:YES completion:nil];
    }else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"Please input your account and password" delegate:nil cancelButtonTitle:@"confirm" otherButtonTitles:nil, nil];
        [alert show];
    }
    
}
@end
