//
//  JMessage.h
//  jabby
//
//  Created by 林 炬 on 14-3-21.
//  Copyright (c) 2014年 soasme. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSMessageData.h"
#import "XMPPMessageArchiving_Message_CoreDataObject.h"


@interface JMessage : XMPPMessage <JSMessageData>

@property (atomic, readwrite) NSString *content;
@property (atomic, readwrite) NSDate *timestamp;
@property (atomic, readwrite) NSUInteger *direction;

-(id)initWithCoreData:(XMPPMessageArchiving_Message_CoreDataObject *)object;
-(id)initWithXMPPMessage:(XMPPMessage *)message kind:(NSString *)kind;

-(BOOL)isOutgoing;
@end
