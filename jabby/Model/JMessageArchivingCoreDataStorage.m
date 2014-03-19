//
//  JMessageArchivingCoreDataStorage.m
//  jabby
//
//  Created by 林 炬 on 14-3-19.
//  Copyright (c) 2014年 soasme. All rights reserved.
//

#import "JMessageArchivingCoreDataStorage.h"

@implementation JMessageArchivingCoreDataStorage

- (void)willInsertMessage:(XMPPMessageArchiving_Message_CoreDataObject *)message
{
	// Override hook
}

- (void)didUpdateMessage:(XMPPMessageArchiving_Message_CoreDataObject *)message
{
	// Override hook
    NSLog(@"did update message %@", message);
}

- (void)willDeleteMessage:(XMPPMessageArchiving_Message_CoreDataObject *)message
{
	// Override hook
}

- (void)willInsertContact:(XMPPMessageArchiving_Contact_CoreDataObject *)contact
{
	// Override hook
}

- (void)didUpdateContact:(XMPPMessageArchiving_Contact_CoreDataObject *)contact
{
	// Override hook
}

@end
