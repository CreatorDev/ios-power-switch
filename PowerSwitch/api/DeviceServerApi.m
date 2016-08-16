/*
 * <b>Copyright (c) 2016, Imagination Technologies Limited and/or its affiliated group companies
 *  and/or licensors. </b>
 *
 *  All rights reserved.
 *
 *  Redistribution and use in source and binary forms, with or without modification, are permitted
 *  provided that the following conditions are met:
 *
 *  1. Redistributions of source code must retain the above copyright notice, this list of conditions
 *      and the following disclaimer.
 *
 *  2. Redistributions in binary form must reproduce the above copyright notice, this list of
 *      conditions and the following disclaimer in the documentation and/or other materials provided
 *      with the distribution.
 *
 *  3. Neither the name of the copyright holder nor the names of its contributors may be used to
 *      endorse or promote products derived from this software without specific prior written
 *      permission.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
 *  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 *  FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 *  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 *  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 *  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 *  WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

#import "DeviceServerApi.h"
#import "Api.h"
#import "GETRequest.h"
#import "OauthRequest.h"
#import "PUTRequest.h"
#import "SecureDataStore.h"
#import "IPSODigitalOutputInstance.h"
#import "OauthManager.h"

@interface DeviceServerApi ()
@property(nonatomic, readonly, nonnull) NSURL *deviceServerUrl;
@property(nonatomic, strong, nullable) OauthManager *oauthManager;
@end

@implementation DeviceServerApi

#pragma mark - Public methods

- (BOOL)loginWithKey:(nonnull NSString *)key
              secret:(nonnull NSString *)secret
               error:(NSError * _Nullable * _Nullable)error
{
    Api *api = [self deviceServerLinksWithError:error];
    if (api == nil) {
        return NO;
    }
    
    NSURL *authenticateUrl = [NSURL URLWithString:[api linkByRel:@"authenticate"].href];
    if (authenticateUrl == nil) {
        if (error) {
            *error = [NSError errorWithDomain:@"com.imgtec.example.PowerSwitch.app" code:0 userInfo:@{@"description": @"Authenticate link not present.", @"method": NSStringFromSelector(_cmd), @"api": api.description}];
        }
        return NO;
    }
    
    self.oauthManager = [[OauthManager alloc] initWithAuthenticateUrl:authenticateUrl
                                                            accessKey:key
                                                               secret:secret];
    if (self.oauthManager.oauthToken == nil) {
        if (error) {
            *error = [NSError errorWithDomain:@"com.imgtec.example.PowerSwitch.app" code:0 userInfo:@{@"description": @"Oauth token not present.", @"method": NSStringFromSelector(_cmd), @"api": api.description}];
        }
        return NO;
    }
    
    return YES;
}

- (nullable Clients *)clientsWithError:(NSError * _Nullable * _Nullable)error {
    Api *api = [self deviceServerLinksWithError:error];
    if (api == nil) {
        return nil;
    }
    
    NSURL *clientsUrl = [NSURL URLWithString:[api linkByRel:@"clients"].href];
    if (clientsUrl == nil) {
        if (error) {
            *error = [NSError errorWithDomain:@"com.imgtec.example.PowerSwitch.app" code:0 userInfo:@{@"description": @"Clients link not present.", @"method": NSStringFromSelector(_cmd), @"api": api.description}];
        }
        return nil;
    }
    
    GETRequest *request = [GETRequest GETRequestWithUrl:clientsUrl
                                                 accept:@"application/vnd.imgtec.clients+json"
                                                   auth:self.oauthManager.oauthToken];
    return [request executeWithSharedUrlSessionAndReturnClass:[Clients class] error:error];
}

#pragma mark - Accounts Server methods

- (nullable Api *)deviceServerLinksWithError:(NSError * _Nullable * _Nullable)error {
    GETRequest *request = [GETRequest GETRequestWithUrl:[self deviceServerUrl]
                                                 accept:@"application/vnd.imgtec.apientrypoint+json"
                                                   auth:self.oauthManager.oauthToken];
    return [request executeWithSharedUrlSessionAndReturnClass:[Api class] error:error];
}

- (nullable ObjectTypes *)objectTypesForClient:(nonnull Client *)client
                                         error:(NSError * _Nullable * _Nullable)error
{
    NSURL *objectTypesUrl = [NSURL URLWithString:[client linkByRel:@"objecttypes"].href];
    GETRequest *request = [GETRequest GETRequestWithUrl:objectTypesUrl
                                                 accept:@"application/vnd.imgtec.objecttypes+json"
                                                   auth:self.oauthManager.oauthToken];
    return [request executeWithSharedUrlSessionAndReturnClass:[ObjectTypes class] error:error];
}

- (nullable Instances *)objectInstancesForObjectType:(nonnull ObjectType *)objectType
                                               error:(NSError * _Nullable * _Nullable)error
{
    NSURL *objectInstancesUrl = [NSURL URLWithString:[objectType linkByRel:@"instances"].href];
    NSString *accept = [NSString stringWithFormat:@"application/vnd.oma.lwm2m.ext:%@s+json", objectType.objectTypeID];
    
    GETRequest *request = [GETRequest GETRequestWithUrl:objectInstancesUrl accept:accept auth:self.oauthManager.oauthToken];
    return [request executeWithSharedUrlSessionAndReturnClass:[Instances class] error:error];
}

- (BOOL)putInstanceData:(nullable NSData *)data
              forObject:(nonnull ObjectType *)objectType
             instanceId:(nonnull NSNumber *)instanceId
                  error:(NSError * _Nullable * _Nullable)error
{
    NSURL *objectInstanceUrl = [NSURL URLWithString:[objectType linkByRel:@"instances"].href];
    objectInstanceUrl = [objectInstanceUrl URLByAppendingPathComponent:instanceId.stringValue];
    
    NSError *err = nil;
    PUTRequest *request = [PUTRequest PUTRequestWithUrl:objectInstanceUrl contentType:@"application/json; charset=utf-8" body:data auth:self.oauthManager.oauthToken];
    [request executeWithSharedUrlSessionAndReturnClass:nil error:&err];
    if (error) {
        *error = err;
    }
    return err != nil;
}

#pragma mark - Private

- (NSURL *)deviceServerUrl {
    return [NSURL URLWithString:@"https://deviceserver.creatordev.io"];
}

@end
