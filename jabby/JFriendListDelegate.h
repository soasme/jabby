//
//  JFriendListDelegate.h
//  jabby
//
//  Created by 林 炬 on 14-3-7.
//  Copyright (c) 2014年 soasme. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol JFriendListDelegate <NSObject>

-(void)onAbsence:(NSString *)name;
-(void)onPresence:(NSString *)name;
-(void)didConnect;

@end
