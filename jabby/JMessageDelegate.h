//
//  JMessageDelegate.h
//  jabby
//
//  Created by 林 炬 on 14-3-7.
//  Copyright (c) 2014年 soasme. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol JMessageDelegate <NSObject>

-(void)onReceivedMessage:(XMPPMessage *)message from:(id)user;

@end
