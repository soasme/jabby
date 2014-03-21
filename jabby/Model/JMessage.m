//
//  JMessage.m
//  jabby
//
//  Created by 林 炬 on 14-3-21.
//  Copyright (c) 2014年 soasme. All rights reserved.
//

#import "JMessage.h"


@implementation JMessage

-(id)initWithCoreData:(XMPPMessageArchiving_Message_CoreDataObject *)object
{
    if (self = [super init]) {
        [self setText:[object body]];
        [self setDate:[object timestamp]];
        
    }
    return self;
}

/**
 *  @return The body text of the message.
 *  @warning This value must not be `nil`.
 */
- (NSString *)text
{
    return _text;
}

/**
 *  @return The name of the user who sent the message.
 */
- (NSString *)sender
{
    //return @"Soasme";
    return @"";
}

/**
 *  @return The date that the message was sent.
 */
- (NSDate *)date
{
    return _date;
}
@end


