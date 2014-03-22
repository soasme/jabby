//
//  JMessage.m
//  jabby
//
//  Created by 林 炬 on 14-3-21.
//  Copyright (c) 2014年 soasme. All rights reserved.
//

#import "JMessage.h"


@implementation JMessage

@synthesize content;
@synthesize timestamp;
@synthesize direction;

-(id)initWithCoreData:(XMPPMessageArchiving_Message_CoreDataObject *)object
{
    if (self = [super init]) {
        [self setContent:[object body]];
        [self setTimestamp:[object timestamp]];
        [self setDirection:(NSUInteger *)[object isOutgoing]];
        
    }
    return self;
}


- (NSString *)text
{
    return self.content;
}

/**
 *  @return The name of the user who sent the message.
 */
- (NSString *)sender
{
    return nil;
}


- (NSDate *)date
{
    return nil;
}

-(BOOL)isOutgoing
{
    return (BOOL)[self direction];
}
@end


