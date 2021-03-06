//
//  UserService.m
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

#import "UserService.h"
#import "DEBUG.h"
#import "Types.h"
#import "Responder.h"
#import "HashMap.h"
#import "Backendless.h"
#import "Invoker.h"
#import "BackendlessUser.h"
#import "UserProperty.h"
#import "AMFSerializer.h"
#import "AuthorizationException.h"
#import "RTClient.h"
#import "BackendlessUserAdapter.h"
#import "VoidResponseWrapper.h"

#define FAULT_NO_USER_CREDENTIALS [Fault fault:@"Login or password is missing or null" detail:@"Login or password is missing or null" faultCode:@"3006"]
#define FAULT_NO_USER [Fault fault:@"User is missing or null" detail:@"User is missing or null" faultCode:@"3900"]
#define FAULT_NO_USER_ID [Fault fault:@"objectId is missing or null" detail:@"objectId is missing or null" faultCode:@"3901"]
#define FAULT_NO_USER_ROLE [Fault fault:@"user role is missing or null" detail:@"user role is missing or null" faultCode:@"3902"]
#define FAULT_NO_USER_EMAIL [Fault fault:@"user email is missing or null" detail:@"user email is missing or null" faultCode:@"3903"]
#define FAULT_USER_IS_NOT_LOGGED_IN [Fault fault:@"user is not logged in" detail:@"user is not logged in" faultCode:@"3904"]

static NSString *PERSIST_USER_FILE_NAME = @"user.bin";
static NSString *SERVER_USER_SERVICE_PATH = @"com.backendless.services.users.UserService";
static NSString *METHOD_REGISTER = @"register";
static NSString *METHOD_UPDATE = @"update";
static NSString *METHOD_LOGIN = @"login";
static NSString *METHOD_LOGOUT = @"logout";
static NSString *METHOD_RESTORE_PASSWORD = @"restorePassword";
static NSString *METHOD_DESCRIBE_USER_CLASS = @"describeUserClass";
static NSString *METHOD_GET_USER_ROLES = @"getUserRoles";
static NSString *METHOD_IS_VALID_USER_TOKEN = @"isValidUserToken";
static NSString *METHOD_USER_LOGIN_WITH_FACEBOOK = @"getFacebookServiceAuthorizationUrlLink";
static NSString *METHOD_USER_LOGIN_WITH_TWITTER = @"getTwitterServiceAuthorizationUrlLink";
static NSString *METHOD_USER_LOGIN_WITH_GOOGLEPLUS = @"getGooglePlusServiceAuthorizationUrlLink";
static NSString *METHOD_USER_LOGIN_WITH_FACEBOOK_SDK = @"loginWithFacebook";
static NSString *METHOD_USER_LOGIN_WITH_GOOGLEPLUS_SDK = @"loginWithGooglePlus";
static NSString *METHOD_USER_LOGIN_WITH_TWITTER_SDK = @"loginWithTwitter";
static NSString *METHOD_RESEND_EMAIL_CONFIRMATION = @"resendEmailConfirmation";
static NSString *METHOD_GUEST_LOGIN = @"loginAsGuest";

@interface UserService ()

#if TARGET_OS_IPHONE || TARGET_OS_SIMULATOR
@property BOOL iOS9above;
#endif

@end

@implementation UserService

-(id)init {
    if (self = [super init]) {
        self.currentUser = nil;
        _isStayLoggedIn = NO;
        [[Types sharedInstance] addClientClassMapping:@"com.backendless.services.users.property.UserProperty" mapped:[UserProperty class]];
        [[Types sharedInstance] addClientClassMapping:@"com.backendless.services.users.property.AbstractProperty" mapped:[AbstractProperty class]];
        [[Types sharedInstance] addClientClassMapping:@"com.backendless.exceptions.security.AuthorizationException" mapped:[AuthorizationException class]];
        [[Types sharedInstance] addClientClassMapping:@"com.backendless.exceptions.user.UserServiceException" mapped:[AuthorizationException class]];
        [[Types sharedInstance] addClientClassMapping:@"com.backendless.geo.model.GeoPoint" mapped:[GeoPoint class]];
    }
    return self;
}

-(BackendlessUser *)castFromDictionary:(id)castObject {
    BackendlessUser *castedUser = nil;
    if ([castObject isKindOfClass:[BackendlessUser class]]) {
        castedUser = (BackendlessUser *)castObject;
    }
    else if ([castObject isKindOfClass:[NSDictionary class]]) {
        BackendlessUser *user = [BackendlessUser new];
        for (NSString *key in [castObject allKeys]) {
            id value = [castObject valueForKey:key];
            if (![value isEqual:[NSNull null]]) {
                [user setProperty:key object:value];
            }
            else {
                [user setProperty:key object:nil];
            }
        }
        castedUser = user;
    }
    return castedUser;
}

-(BOOL)setStayLoggedIn:(BOOL)value {
    if (value == _isStayLoggedIn)
    return YES;
    return (_isStayLoggedIn = value) ? [self setPersistentUser] : [self resetPersistentUser];
}

-(void)setUserToken:(NSString *)userToken {
    [backendless.headers setValue:userToken forKey:BACKENDLESS_USER_TOKEN];
}

-(NSString *)getUserToken {
    return self.currentUser.getUserToken;
}

// sync methods with fault return (as exception)

-(BackendlessUser *)registerUser:(BackendlessUser *)user {
    if (!user)
    return [backendless throwFault:FAULT_NO_USER];
    if (![user getProperties])
    return [backendless throwFault:FAULT_NO_USER_CREDENTIALS];
    NSMutableDictionary *props = [NSMutableDictionary dictionaryWithDictionary:[user getProperties]];
    [props removeObjectsForKeys:@[BACKENDLESS_USER_TOKEN, BACKENDLESS_USER_REGISTERED]];
    NSArray *args = [NSArray arrayWithObjects:props, nil];
    id result = [invoker invokeSync:SERVER_USER_SERVICE_PATH method:METHOD_REGISTER args:args responseAdapter:[BackendlessUserAdapter new]];
    if ([result isKindOfClass:[Fault class]]) {
        return [backendless throwFault:result];
    }
    return [self castFromDictionary:result];
}

-(BackendlessUser *)update:(BackendlessUser *)user {
    if (!user)
    return [backendless throwFault:FAULT_NO_USER];
    NSMutableDictionary *props = [NSMutableDictionary dictionaryWithDictionary:[user getProperties]];
    [props removeObjectsForKeys:@[BACKENDLESS_USER_TOKEN, BACKENDLESS_USER_REGISTERED]];
    NSArray *args = [NSArray arrayWithObjects:props, nil];
    id result = [invoker invokeSync:SERVER_USER_SERVICE_PATH method:METHOD_UPDATE args:args responseAdapter:[BackendlessUserAdapter new]];
    if ([result isKindOfClass:[Fault class]]) {
        return [backendless throwFault:result];
    }
    if ([result isKindOfClass:[BackendlessUser class]]) {
        user = result;
    }
    else {
        [user setProperties:result];
    }
    if (_isStayLoggedIn && self.currentUser && [user.objectId isEqualToString:self.currentUser.objectId]) {
        [self updateCurrentUser:result];
    }
    return user;
}

-(BackendlessUser *)login:(NSString *)login password:(NSString *)password {
    if (!login || !password || ![login length] || ![password length])
    return [backendless throwFault:FAULT_NO_USER_CREDENTIALS];
    NSArray *args = [NSArray arrayWithObjects:login, password, nil];
    id result = [invoker invokeSync:SERVER_USER_SERVICE_PATH method:METHOD_LOGIN args:args responseAdapter:[BackendlessUserAdapter new]];
    if ([result isKindOfClass:[Fault class]]) {
        return [backendless throwFault:result];
    }
    self.currentUser = [self castFromDictionary:result];
    if (self.currentUser.getUserToken) {
        [backendless.headers setValue:self.currentUser.getUserToken forKey:BACKENDLESS_USER_TOKEN];
    }
    else {
        [backendless.headers removeObjectForKey:BACKENDLESS_USER_TOKEN];
    }
    [self setPersistentUser];
    return self.currentUser;
}

-(BackendlessUser *)findById:(NSString *)objectId {
    return [[backendless.data of:[BackendlessUser class]] findById:objectId];
}

-(void)logout {
    id result = [invoker invokeSync:SERVER_USER_SERVICE_PATH method:METHOD_LOGOUT args:@[]];
    if ([result isKindOfClass:[Fault class]]) {
        [self onLogoutError:result];
        [backendless throwFault:result];
    }
    if (self.currentUser) {
        self.currentUser = nil;
    }
    [backendless.headers removeObjectForKey:BACKENDLESS_USER_TOKEN];
    [self resetPersistentUser];
}

-(BOOL)isValidUserToken {
    NSString *userToken = [backendless.headers valueForKey:BACKENDLESS_USER_TOKEN];
    if (!self.currentUser || !userToken) {
        return NO;
    }
    NSArray *args = @[userToken];
    id result = [invoker invokeSync:SERVER_USER_SERVICE_PATH method:METHOD_IS_VALID_USER_TOKEN args:args];
    if ([result isKindOfClass:[Fault class]]) {
        if ([((Fault *)result).faultCode isEqualToString:@"3048"]) {
            [backendless.headers removeObjectForKey:BACKENDLESS_USER_TOKEN];
        }
        [backendless throwFault:result];
    }
    return [result boolValue];
}

-(void)restorePassword:(NSString *)email {
    if (!email||!email.length)
    [backendless throwFault:FAULT_NO_USER_CREDENTIALS];
    NSArray *args = [NSArray arrayWithObjects:email, nil];
    id result = [invoker invokeSync:SERVER_USER_SERVICE_PATH method:METHOD_RESTORE_PASSWORD args:args];
    if ([result isKindOfClass:[Fault class]]) {
        [backendless throwFault:result];
    }
}

-(NSArray<UserProperty*> *)describeUserClass {
    id result = [invoker invokeSync:SERVER_USER_SERVICE_PATH method:METHOD_DESCRIBE_USER_CLASS args:@[]];
    if ([result isKindOfClass:[Fault class]]) {
        return [backendless throwFault:result];
    }
    return result;
}

-(NSArray<NSString*> *)getUserRoles {
    id result = [invoker invokeSync:SERVER_USER_SERVICE_PATH method:METHOD_GET_USER_ROLES args:@[]];
    if ([result isKindOfClass:[Fault class]]) {
        return [backendless throwFault:result];
    }
    return result;
}

-(BackendlessUser *)loginWithFacebookSDK:(NSString *)userId tokenString:(NSString *)tokenString expirationDate:(NSDate *)expirationDate fieldsMapping:(NSDictionary *)fieldsMapping {
    if (!userId||!userId.length||!tokenString||!tokenString.length) {
        return [backendless throwFault:FAULT_NO_USER_CREDENTIALS];
    }
    NSArray *args = @[userId, tokenString, expirationDate, @[], (NSDictionary<NSString *, NSString*> *)fieldsMapping?fieldsMapping:@{}];
    id result = [invoker invokeSync:SERVER_USER_SERVICE_PATH method:METHOD_USER_LOGIN_WITH_FACEBOOK_SDK args:args responseAdapter:[BackendlessUserAdapter new]];
    if ([result isKindOfClass:[Fault class]]) {
        return [backendless throwFault:result];
    }
    return [self onLogin:result];
}

-(BackendlessUser *)loginWithGoogleSDK:(NSString *)idToken accessToken:(NSString *)accessToken {
    if (!idToken||!idToken.length||!accessToken||!accessToken.length) {
        return [backendless throwFault:FAULT_NO_USER_CREDENTIALS];
    }
    NSArray *args = @[idToken, accessToken, @[], @{}];
    id result = [invoker invokeSync:SERVER_USER_SERVICE_PATH method:METHOD_USER_LOGIN_WITH_GOOGLEPLUS_SDK args:args responseAdapter:[BackendlessUserAdapter new]];
    if ([result isKindOfClass:[Fault class]]) {
        return [backendless throwFault:result];
    }
    return [self onLogin:result];
}

-(BackendlessUser *)loginWithTwitterSDK:(NSString *)authToken authTokenSecret:(NSString *)authTokenSecret fieldsMapping:(NSDictionary *)fieldsMapping {
    if (!authToken||!authToken.length||!authTokenSecret||!authTokenSecret.length) {
        return [backendless throwFault:FAULT_NO_USER_CREDENTIALS];
    }
    NSArray *args = @[authToken, authTokenSecret, (NSDictionary<NSString *, NSString*> *)fieldsMapping?fieldsMapping:@{}];
    id result = [invoker invokeSync:SERVER_USER_SERVICE_PATH method:METHOD_USER_LOGIN_WITH_TWITTER_SDK args:args responseAdapter:[BackendlessUserAdapter new]];
    if ([result isKindOfClass:[Fault class]]) {
        return [backendless throwFault:result];
    }
    return [self onLogin:result];
}

-(void)resendEmailConfirmation:(NSString *)email {
    if (!email||!email.length) {
        [backendless throwFault:FAULT_NO_USER_EMAIL];
    }
    NSArray *args = @[email];
    id result = [invoker invokeSync:SERVER_USER_SERVICE_PATH method:METHOD_RESEND_EMAIL_CONFIRMATION args:args];
    if ([result isKindOfClass:[Fault class]]) {
        [backendless throwFault:result];
    }
    [self onLogin:result];
}

-(BackendlessUser *)loginAsGuest  {
    return [self loginAsGuestWithStayLoggedIn:NO];
}

-(BackendlessUser *)loginAsGuestWithStayLoggedIn:(BOOL)stayLoggedIn {
    [self setStayLoggedIn:stayLoggedIn];
    id result = [invoker invokeSync:SERVER_USER_SERVICE_PATH method:METHOD_GUEST_LOGIN args:nil responseAdapter:[BackendlessUserAdapter new]];
    if ([result isKindOfClass:[Fault class]]) {
        return [backendless throwFault:result];
    }
    self.currentUser = [self castFromDictionary:result];
    if (self.currentUser.getUserToken) {
        [backendless.headers setValue:self.currentUser.getUserToken forKey:BACKENDLESS_USER_TOKEN];
    }
    else {
        [backendless.headers removeObjectForKey:BACKENDLESS_USER_TOKEN];
    }
    [self setPersistentUser];
    return self.currentUser;
}

// async methods with block-based callbacks

-(void)registerUser:(BackendlessUser *)user response:(void(^)(BackendlessUser *))responseBlock error:(void(^)(Fault *))errorBlock {
    if (!user)
    [backendless throwFault:FAULT_NO_USER];
    if (![user getProperties])
    [backendless throwFault:FAULT_NO_USER_CREDENTIALS];
    NSMutableDictionary *props = [NSMutableDictionary dictionaryWithDictionary:[user getProperties]];
    [props removeObjectsForKeys:@[BACKENDLESS_USER_TOKEN, BACKENDLESS_USER_REGISTERED]];
    NSArray *args = [NSArray arrayWithObjects:props, nil];
    void(^wrappedBlock)(NSDictionary *) = ^(NSDictionary *regUserDict) {
        responseBlock([self castFromDictionary:regUserDict]);
    };
    [invoker invokeAsync:SERVER_USER_SERVICE_PATH method:METHOD_REGISTER args:args responder:[ResponderBlocksContext responderBlocksContext:wrappedBlock error:errorBlock] responseAdapter:[BackendlessUserAdapter new]];
}

-(void)update:(BackendlessUser *)user response:(void(^)(BackendlessUser *))responseBlock error:(void(^)(Fault *))errorBlock {
    id <IResponder> responder = [ResponderBlocksContext responderBlocksContext:responseBlock error:errorBlock];
    if (!user)
    return [responder errorHandler:FAULT_NO_USER];
    NSMutableDictionary *props = [NSMutableDictionary dictionaryWithDictionary:[user getProperties]];
    [props removeObjectsForKeys:@[BACKENDLESS_USER_TOKEN, BACKENDLESS_USER_REGISTERED]];
    NSArray *args = [NSArray arrayWithObjects:props, nil];
    Responder *_responder = [Responder responder:self selResponseHandler:@selector(onUpdate:) selErrorHandler:nil];
    _responder.chained = responder;
    _responder.context = user;
    [invoker invokeAsync:SERVER_USER_SERVICE_PATH method:METHOD_UPDATE args:args responder:_responder responseAdapter:[BackendlessUserAdapter new]];
}

-(void)login:(NSString *)login password:(NSString *)password response:(void(^)(BackendlessUser *))responseBlock error:(void(^)(Fault *))errorBlock {
    Responder *responder = [ResponderBlocksContext responderBlocksContext:responseBlock error:errorBlock];
    if (!login || !password || ![login length] || ![password length])
    return [responder errorHandler:FAULT_NO_USER_CREDENTIALS];
    NSArray *args = [NSArray arrayWithObjects:login, password, nil];
    Responder *_responder = [Responder responder:self selResponseHandler:@selector(onLogin:) selErrorHandler:nil];
    _responder.chained = responder;
    [invoker invokeAsync:SERVER_USER_SERVICE_PATH method:METHOD_LOGIN args:args responder:_responder responseAdapter:[BackendlessUserAdapter new]];
}

-(void)findById:(NSString *)objectId response:(void(^)(BackendlessUser *))responseBlock error:(void(^)(Fault *))errorBlock {
    [[backendless.data of:[BackendlessUser class]] findById:objectId response:responseBlock error:errorBlock];
}

-(void)logout:(void(^)(void))responseBlock error:(void(^)(Fault *))errorBlock {    
    Responder *responder = [ResponderBlocksContext responderBlocksContext:[[VoidResponseWrapper sharedInstance] wrapResponseBlock:responseBlock] error:errorBlock];
    Responder *_responder = [Responder responder:self selResponseHandler:@selector(onLogout:) selErrorHandler:@selector(onLogoutError:)];
    _responder.chained = responder;
    [invoker invokeAsync:SERVER_USER_SERVICE_PATH method:METHOD_LOGOUT args:@[] responder:_responder];
}

-(void)isValidUserToken:(void(^)(BOOL))responseBlock error:(void(^)(Fault *))errorBlock {
    void(^wrappedBlock)(NSNumber *) = ^(NSNumber *result) {        
        if ([result isKindOfClass:[Fault class]]) {
            Fault *fault = (Fault *)result;
            if ([fault.faultCode isEqualToString:@"3048"]) {
                [backendless.headers removeObjectForKey:BACKENDLESS_USER_TOKEN];
            }
        }
        responseBlock([result boolValue]);
    };
    id <IResponder>responder = [ResponderBlocksContext responderBlocksContext:wrappedBlock error:errorBlock];
    NSString *userToken = [backendless.headers valueForKey:BACKENDLESS_USER_TOKEN];
    if (!self.currentUser || !userToken) {
        [responder responseHandler:@0];
        return;
    }
    NSArray *args = @[userToken];
    [invoker invokeAsync:SERVER_USER_SERVICE_PATH method:METHOD_IS_VALID_USER_TOKEN args:args responder:responder];
}

-(void)restorePassword:(NSString *)email response:(void(^)(void))responseBlock error:(void(^)(Fault *))errorBlock {
    id<IResponder>responder = [ResponderBlocksContext responderBlocksContext:[voidResponseWrapper wrapResponseBlock:responseBlock] error:errorBlock];
    if (!email||!email.length)
    return [responder errorHandler:FAULT_NO_USER_CREDENTIALS];
    NSArray *args = [NSArray arrayWithObjects:email, nil];
    [invoker invokeAsync:SERVER_USER_SERVICE_PATH method:METHOD_RESTORE_PASSWORD args:args responder:responder];
}

-(void)describeUserClass:(void(^)(NSArray<UserProperty*> *))responseBlock error:(void(^)(Fault *))errorBlock {
    [invoker invokeAsync:SERVER_USER_SERVICE_PATH method:METHOD_DESCRIBE_USER_CLASS args:@[] responder:[ResponderBlocksContext responderBlocksContext:responseBlock error:errorBlock]];
}

-(void)getUserRoles:(void(^)(NSArray<NSString*> *))responseBlock error:(void(^)(Fault *))errorBlock {
    [invoker invokeAsync:SERVER_USER_SERVICE_PATH method:METHOD_GET_USER_ROLES args:@[] responder:[ResponderBlocksContext responderBlocksContext:responseBlock error:errorBlock]];
}

-(void)loginWithFacebookSDK:(NSString *)userId tokenString:(NSString *)tokenString expirationDate:(NSDate *)expirationDate fieldsMapping:(NSDictionary *)fieldsMapping response:(void(^)(BackendlessUser *))responseBlock error:(void(^)(Fault *))errorBlock {
    id<IResponder>responder = [ResponderBlocksContext responderBlocksContext:responseBlock error:errorBlock];
    if (!userId||!userId.length||!tokenString||!tokenString.length) {
        return [responder errorHandler:FAULT_NO_USER_CREDENTIALS];
    }
    NSArray *args = @[userId, tokenString, expirationDate, @[], (NSDictionary<NSString *, NSString*> *)fieldsMapping?fieldsMapping:@{}];
    Responder *_responder = [Responder responder:self selResponseHandler:@selector(onLogin:) selErrorHandler:nil];
    _responder.chained = responder;
    [invoker invokeAsync:SERVER_USER_SERVICE_PATH method:METHOD_USER_LOGIN_WITH_FACEBOOK_SDK args:args responder:_responder responseAdapter:[BackendlessUserAdapter new]];
}

-(void)loginWithGoogleSDK:(NSString *)idToken accessToken:(NSString *)accessToken response:(void(^)(BackendlessUser *))responseBlock error:(void(^)(Fault *))errorBlock {
    id<IResponder>responder = [ResponderBlocksContext responderBlocksContext:responseBlock error:errorBlock];
    if (!idToken||!idToken.length||!accessToken||!accessToken.length) {
        return [responder errorHandler:FAULT_NO_USER_CREDENTIALS];
    }
    NSArray *args = @[idToken, accessToken, @[], @{}];
    Responder *_responder = [Responder responder:self selResponseHandler:@selector(onLogin:) selErrorHandler:nil];
    _responder.chained = responder;
    [invoker invokeAsync:SERVER_USER_SERVICE_PATH method:METHOD_USER_LOGIN_WITH_GOOGLEPLUS_SDK args:args responder:_responder responseAdapter:[BackendlessUserAdapter new]];
}

-(void)loginWithTwitterSDK:(NSString *)authToken authTokenSecret:(NSString *)authTokenSecret fieldsMapping:(NSDictionary *)fieldsMapping response:(void(^)(BackendlessUser *))responseBlock error:(void(^)(Fault *))errorBlock {
    id<IResponder>responder = [ResponderBlocksContext responderBlocksContext:responseBlock error:errorBlock];
    if (!authToken||!authToken.length||!authTokenSecret||!authTokenSecret.length) {
        return [responder errorHandler:FAULT_NO_USER_CREDENTIALS];
    }
    NSArray *args = @[authToken, authTokenSecret, (NSDictionary<NSString *, NSString*> *)fieldsMapping?fieldsMapping:@{}];
    Responder *_responder = [Responder responder:self selResponseHandler:@selector(onLogin:) selErrorHandler:nil];
    _responder.chained = responder;
    [invoker invokeAsync:SERVER_USER_SERVICE_PATH method:METHOD_USER_LOGIN_WITH_TWITTER_SDK args:args responder:_responder responseAdapter:[BackendlessUserAdapter new]];
}

-(void)resendEmailConfirmation:(NSString *)email response:(void(^)(void))responseBlock error:(void(^)(Fault *))errorBlock {
    id<IResponder>responder = [ResponderBlocksContext responderBlocksContext:[voidResponseWrapper wrapResponseBlock:responseBlock] error:errorBlock];
    if (!email||!email.length)
    [responder errorHandler:FAULT_NO_USER_EMAIL];
    NSArray *args = @[email];
    [invoker invokeAsync:SERVER_USER_SERVICE_PATH method:METHOD_RESEND_EMAIL_CONFIRMATION args:args responder:responder];
}

-(void)loginAsGuest:(void (^)(BackendlessUser *))responseBlock error:(void (^)(Fault *))errorBlock {
    [self loginAsGuestWithStayLoggedIn:NO response:responseBlock error:errorBlock];
}

-(void)loginAsGuestWithStayLoggedIn:(BOOL)stayLoggedIn response:(void (^)(BackendlessUser *))responseBlock error:(void (^)(Fault *))errorBlock {
    [self setStayLoggedIn:stayLoggedIn];
    Responder *responder = [ResponderBlocksContext responderBlocksContext:responseBlock error:errorBlock];
    Responder *_responder = [Responder responder:self selResponseHandler:@selector(onLogin:) selErrorHandler:nil];
    _responder.chained = responder;
    [invoker invokeAsync:SERVER_USER_SERVICE_PATH method:METHOD_GUEST_LOGIN args:nil responder:_responder responseAdapter:[BackendlessUserAdapter new]];
}

// persistent user

-(BOOL)getPersistentUser {
    id obj = [AMFSerializer deserializeFromFile:PERSIST_USER_FILE_NAME];
    self.currentUser = obj ? [[BackendlessUser alloc] initWithProperties:obj] : nil;
    _isStayLoggedIn = (BOOL)self.currentUser;
    if (_isStayLoggedIn && self.currentUser.getUserToken) {
        [backendless.headers setValue:self.currentUser.getUserToken forKey:BACKENDLESS_USER_TOKEN];
    }
    else {
        [backendless.headers removeObjectForKey:BACKENDLESS_USER_TOKEN];
    }
    return _isStayLoggedIn;
}

-(BOOL)setPersistentUser {
    if (self.currentUser) {
        [rtClient userLoggedInWithToken:self.currentUser.getUserToken];
        if (_isStayLoggedIn) {
            NSMutableDictionary *properties = [NSMutableDictionary dictionaryWithDictionary:[self.currentUser getProperties]];
            NSString *userToken = [backendless.headers valueForKey:BACKENDLESS_USER_TOKEN];
            if (userToken) {
                [properties setValue:userToken forKey:BACKENDLESS_USER_TOKEN];
            }
            return [AMFSerializer serializeToFile:properties fileName:PERSIST_USER_FILE_NAME];
        }
    }
    return NO;
}

-(BOOL)resetPersistentUser {
    [rtClient userLoggedInWithToken:nil];
    return [AMFSerializer serializeToFile:nil fileName:PERSIST_USER_FILE_NAME];
}

// callbacks

-(id)registerError:(id)error {
    [DebLog log:@"UserService -> registerError: %@", error];
    return error;
}

-(id)registerResponse:(ResponseContext *)response {
    [DebLog log:@"UserService -> registerResponse: %@", response];
    BackendlessUser *user = response.context;
    [user setProperties:response.response];
    return user;
}

-(id)onLogin:(id)response {
    if ([response isKindOfClass:[BackendlessUser class]]) {
        self.currentUser = response;
    }
    else {
        NSDictionary *props = (NSDictionary *)response;
        (self.currentUser) ? [self.currentUser setProperties:props] : (self.currentUser = [[BackendlessUser alloc] initWithProperties:props]);
    }
    if (self.currentUser.getUserToken)
    [backendless.headers setValue:self.currentUser.getUserToken forKey:BACKENDLESS_USER_TOKEN];
    else
    [backendless.headers removeObjectForKey:BACKENDLESS_USER_TOKEN];
    [self setPersistentUser];
    return self.currentUser;
}

-(void)updateCurrentUser:(id)response {
    if ([response isKindOfClass:[BackendlessUser class]]) {
        self.currentUser = response;
    }
    else {
        NSDictionary *props = (NSDictionary *)response;
        (self.currentUser) ? [self.currentUser setProperties:props] : (self.currentUser = [[BackendlessUser alloc] initWithProperties:props]);
    }
    [self setPersistentUser];
}

-(id)onUpdate:(ResponseContext *)response {
    [DebLog log:@"UserService -> onUpdate: %@", response];
    BackendlessUser *user = response.context;
    id result = response.response;
    if ([result isKindOfClass:[BackendlessUser class]]) {
        user = result;
    }
    else {
        [user setProperties:result];
    }
    
    if (_isStayLoggedIn && self.currentUser && [user.objectId isEqualToString:self.currentUser.objectId]) {
        [self updateCurrentUser:result];
    }
    return user;
}

-(id)onLogout:(id)response {
    if (self.currentUser) {
        self.currentUser = nil;
    }
    [backendless.headers removeObjectForKey:BACKENDLESS_USER_TOKEN];
    [self resetPersistentUser];
    return response;
}

-(void)onLogoutError:(Fault *)fault {
    [DebLog log:@"UserService -> onLogoutError: %@", fault];
    NSArray *faultCodes = @[@"3023", @"3064", @"3090", @"3091"];
    for (NSString *code in faultCodes) {
        if ([fault.faultCode isEqualToString:code]) {
            [self onLogout:fault];
        }
    }
}

@end
