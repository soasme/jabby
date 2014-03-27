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
    [self.tipLabel setText:@""];
    // Do any additional setup after loading the view.
    self.loginButton.buttonColor = [UIColor turquoiseColor];
    self.loginButton.shadowColor = [UIColor greenSeaColor];
    self.loginButton.shadowHeight = 3.0f;
    self.loginButton.cornerRadius = 6.0f;
    self.loginButton.titleLabel.font = [UIFont boldFlatFontOfSize:16];
    [self.loginButton setTitleColor:[UIColor cloudsColor] forState:UIControlStateNormal];
    [self.loginButton setTitleColor:[UIColor cloudsColor] forState:UIControlStateHighlighted];
    [self.loginButton setTitle:@"Login" forState:UIControlStateNormal];
    
    [UIBarButtonItem configureFlatButtonsWithColor:[UIColor peterRiverColor]
                                  highlightedColor:[UIColor belizeHoleColor]
                                      cornerRadius:3];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didAuthenticatedSuccessOnLoginView:) name:@"Authenticate Success" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didAuthenticatedFailedOnLoginView:) name:@"Authenticate Failed" object:nil];
    [[JIMCenter sharedInstance].xmppReconnect stop];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)didAuthenticatedSuccessOnLoginView: (NSNotification *)notification
{
    [[JIMCenter sharedInstance].xmppReconnect manualStart];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didAuthenticatedFailedOnLoginView: (NSNotification *)notification
{
    //TODO we need to notify user that he type wrong account and password.
    [self.tipLabel setText:@"Your account and password are wrong!"];
//    [[self appDelegate] alert:@"Your account and password are wrong!" andTitle:@"Warning"];
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
        [[JIMCenter sharedInstance] connect];
        [[JIMCenter sharedInstance] auth];
    }else {
        [[self appDelegate] alert:@"Please input your account and password" andTitle:@"Warning"];
    }
}

- (IBAction)passwordEditingDidEnd:(id)sender {
    [self didLoginButtonTouchDown:sender];
}

- (IBAction)passwordDidEndOnExit:(id)sender {
//    NSLog(@"did exit");
}
@end
