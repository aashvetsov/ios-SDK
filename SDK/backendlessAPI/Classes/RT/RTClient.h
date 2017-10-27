//
//  RTClient.h
//  backendlessAPI
/*
 * *********************************************************************************************************************
 *
 *  BACKENDLESS.COM CONFIDENTIAL
 *
 *  ********************************************************************************************************************
 *
 *  Copyright 2017 BACKENDLESS.COM. All Rights Reserved.
 *
 *  NOTICE: All information contained herein is, and remains the property of Backendless.com and its suppliers,
 *  if any. The intellectual and technical concepts contained herein are proprietary to Backendless.com and its
 *  suppliers and may be covered by U.S. and Foreign Patents, patents in process, and are protected by trade secret
 *  or copyright law. Dissemination of this information or reproduction of this material is strictly forbidden
 *  unless prior written permission is obtained from Backendless.com.
 *
 *  ********************************************************************************************************************
 */

#import <Foundation/Foundation.h>
@import SocketIO;

#define rtClient [RTClient sharedInstance]

@interface RTClient : NSObject

@property (strong, nonatomic) SocketIOClient *socket;
@property (strong, nonatomic) NSMutableDictionary *subscriptions;

+(RTClient *)sharedInstance;
-(void)connectSocket:(void(^)(void))connected;

@end
