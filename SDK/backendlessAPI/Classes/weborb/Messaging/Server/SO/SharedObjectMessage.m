//
//  SharedObjectMessage.m
//  backendlessAPI
/*
 * *********************************************************************************************************************
 *
 *  BACKENDLESS.COM CONFIDENTIAL
 *
 *  ********************************************************************************************************************
 *
 *  Copyright 2018 BACKENDLESS.COM. All Rights Reserved.
 *
 *  NOTICE: All information contained herein is, and remains the property of Backendless.com and its suppliers,
 *  if any. The intellectual and technical concepts contained herein are proprietary to Backendless.com and its
 *  suppliers and may be covered by U.S. and Foreign Patents, patents in process, and are protected by trade secret
 *  or copyright law. Dissemination of this information or reproduction of this material is strictly forbidden
 *  unless prior written permission is obtained from Backendless.com.
 *
 *  ********************************************************************************************************************
 */

#import "SharedObjectMessage.h"
#import "DEBUG.h"
#import "RTMPConstants.h"
#import "SharedObjectEvent.h"


@implementation SharedObjectMessage

-(id)init {	
	if ( (self=[super init]) ) {
		name = nil;
		events = [[NSMutableArray alloc] init];
		version = -1;
		persistent = NO;
	}
	
	return self;
}

-(id)initWithName:(NSString *)_name version:(int)_version persistent:(BOOL)_persistent {	
	if ( (self=[super initWithType:SHARED_OBJECT andSource:nil]) ) {
		name = _name;
		events = [[NSMutableArray alloc] init];
		version = _version;
		persistent = _persistent;
	}
	
	return self;
}

-(id)initWithSource:(id <IEventListener>)_source name:(NSString *)_name version:(int)_version persistent:(BOOL)_persistent {	
	if ( (self=[super initWithType:SHARED_OBJECT andSource:_source]) ) {
		name = _name;
		events = [[NSMutableArray alloc] init];
		version = _version;
		persistent = _persistent;
	}
	
	return self;
}

-(void)dealloc {
	
	[DebLog logN:@"DEALLOC SharedObjectMessage"];
	
	[events removeAllObjects];
	[events release];
	
	[super dealloc];
}

-(NSString *)description {
    return [NSString stringWithFormat:@"<SharedObjectMessage> %@ [%d, %@] %@", name, version, @(persistent), events];
}

#pragma mark -
#pragma mark Public Methods

-(void)setVersion:(int)_version {
	version = _version;
}

-(void)setName:(NSString *)_name {
	name = _name;
}

-(void)setIsPersistent:(BOOL)_persistent {
	persistent = _persistent;
}

-(void)addEvents:(NSArray *)listEvents {
	for (id evt in listEvents)
		[events addObject:evt];
}

-(EventType)getType {
	return SHARED_OBJECT;
}

-(id)getObject {
	return [self getEvents];
}

#pragma mark -
#pragma mark IRTMPEvent Methods

-(uint)getDataType {
	return TYPE_SHARED_OBJECT;
}

#pragma mark -
#pragma mark ISharedObjectMessage Methods

-(int)getVersion {
	return version;
}

-(NSString *)getName {
	return name;
}

-(BOOL)isPersistent {
	return persistent;
}

-(NSArray *)getEvents {
	return [NSArray arrayWithArray:events];
}

-(void)addEvent:(id <ISharedObjectEvent>)evt {
	[events addObject:evt];
}

-(void)addEvent:(SharedObjectEventType)_type withKey:(NSString *)key andValue:(id)value {
	[self addEvent:[[[SharedObjectEvent alloc] initWithType:_type withKey:key andValue:value] autorelease]];
}

-(void)clear {
	[events removeAllObjects];
}

-(BOOL)isEmpty {
	return ([events count] == 0);
}

@end
