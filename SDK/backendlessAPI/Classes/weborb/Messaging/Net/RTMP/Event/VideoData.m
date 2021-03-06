//
//  VideoData.m
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

#import "VideoData.h"
#import "DEBUG.h"
#import "RTMPConstants.h"
#import "IVideoStreamCodec.h"


@interface VideoData ()
-(void)defaultInit;
@end


@implementation VideoData

-(id)init {	
	if ( (self=[super initWithType:STREAM_DATA]) ) {
        [self defaultInit];
	}
	
	return self;
}

-(id)initWithBinaryStream:(BinaryStream *)stream {
	if ( (self=[super initWithType:STREAM_DATA]) ) {
        [self defaultInit];
        [self setData:stream];
	}
	
	return self;    
}

-(id)initWithCodec:(id <IVideoStreamCodec>)videoCodec {
	if ( (self=[super initWithType:STREAM_DATA]) ) {
        [self defaultInit];
        [self setCodec:videoCodec];
	}
	
	return self;    
}

-(id)initWithBinaryStream:(BinaryStream *)stream videoCodec:(id <IVideoStreamCodec>)videoCodec {
	if ( (self=[super initWithType:STREAM_DATA]) ) {
        [self defaultInit];
        [self setCodec:videoCodec];
        [self setData:stream];
	}
	return self;    
}

-(void)dealloc {
	[DebLog logN:@"DEALLOC VideoData"];
    if (data) [data release]; 
    if (codec) [codec release];
	[super dealloc];
}

#pragma mark -
#pragma mark Private Methods

-(void)defaultInit {
    data = nil;
    codec = nil;
    timestamp = 0;
}

#pragma mark -
#pragma mark getters & setters

-(void)setData:(BinaryStream *)_data {
    if (data) [data release];
    data = (_data) ? [_data retain] : nil;
    if (codec) [codec addBuffer:data];
}

-(id <IVideoStreamCodec>)getCodec {
    return codec;
}
                                
-(void)setCodec:(id <IVideoStreamCodec>)_codec {
    if (codec) [codec release];
    codec = (_codec) ? [_codec retain] : nil;
    if (codec) [codec addBuffer:data];
}

#pragma mark -
#pragma mark Public Methods

#pragma mark -
#pragma mark IStreamPacket Methods

-(int)getDataType {
    return TYPE_VIDEO_DATA;
}

-(int)getTimestamp {
    return timestamp;
}

-(BinaryStream *)getData {
    return (codec) ? [codec getFrame] : data;
}
                          
@end
