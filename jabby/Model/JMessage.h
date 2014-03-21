//
//  JMessage.h
//  jabby
//
//  Created by 林 炬 on 14-3-21.
//  Copyright (c) 2014年 soasme. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSMessageData.h"

@interface JMessage : NSObject <JSMessageData>

@property NSString *text;
@end
