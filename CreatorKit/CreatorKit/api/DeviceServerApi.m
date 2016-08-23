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

#import "DeviceServerApi_PRIV.h"
#import "Api.h"
#import "GETRequest.h"
#import "OauthManager.h"


typedef NS_ENUM(NSInteger, LoginMethod) {
    LoginMethodAccessKeySecret,
    LoginMethodRefreshToken
};


@interface DeviceServerApi ()
@property(nonatomic, readonly, nonnull) NSURL *deviceServerUrl;
@property(nonatomic, strong, nullable) OauthManager *oauthManager;
@end


@implementation DeviceServerApi

#pragma mark - Public methods

- (void)loginWithKey:(nonnull NSString *)key
              secret:(nonnull NSString *)secret
      keepMeSignedIn:(BOOL)keepMeSignedIn
               error:(NSError * _Nullable * _Nullable)error
{
    [self loginWithMethod:LoginMethodAccessKeySecret
                   params:@[key, secret]
           keepMeSignedIn:keepMeSignedIn
                    error:error];
}

- (void)loginWithRefreshToken:(nonnull NSString *)token
               keepMeSignedIn:(BOOL)keepMeSignedIn
                        error:(NSError * _Nullable * _Nullable)error
{
    [self loginWithMethod:LoginMethodRefreshToken
                   params:@[token]
           keepMeSignedIn:keepMeSignedIn
                    error:error];
}

- (nullable NSURL *)authenticateUrlWithError:(NSError * _Nullable * _Nullable)error {
    Api *api = [self deviceServerLinksWithAuthToken:nil error:error];
    if (api == nil) {
        return nil;
    }
    
    return [NSURL URLWithString:[api linkByRel:@"authenticate"].href];
}

- (OauthManager *)oauthManagerWithError:(NSError * _Nullable * _Nullable)error {
    NSURL *authenticateUrl = [self authenticateUrlWithError:error];
    return [[OauthManager alloc] initWithAuthenticateUrl:authenticateUrl];
}

- (OauthManager *)oauthManager {
    if (_oauthManager == nil) {
        NSError *error = nil;
        _oauthManager = [self oauthManagerWithError:&error];
        if (error) {
            NSLog(@"ERROR getting oauth manager.");
        }
    }
    return _oauthManager;
}

- (void)loginWithMethod:(LoginMethod)method
                 params:(NSArray<NSString *> *)params
         keepMeSignedIn:(BOOL)keepMeSignedIn
                  error:(NSError * _Nullable * _Nullable)error
{
    if (self.oauthManager == nil) {
        if (error) {
            *error = [NSError errorWithDomain:@"io.creatordev.CreatorKit" code:0 userInfo:@{@"description": @"ERROR initializing Oauth Manager, wrong URL?"}];
        }
        return;
    }
    self.oauthManager.storeRefreshToken = keepMeSignedIn;
    
    switch (method) {
        case LoginMethodAccessKeySecret:
            if (params.count == 2) {
                [self.oauthManager authorizeWithAccessKey:params[0] secret:params[1] error:error];
            }
            break;
        case LoginMethodRefreshToken:
            if (params.count == 1) {
                [self.oauthManager authorizeWithRefreshToken:params[0] error:error];
            }
            break;
    }
}

- (OauthToken *)oauthToken {
    return self.oauthManager.oauthToken;
}

#pragma mark - Accounts Server methods

- (nullable Api *)deviceServerLinksWithAuthToken:(nullable OauthToken *)oauthToken
                                           error:(NSError * _Nullable * _Nullable)error {
    GETRequest *request = [GETRequest GETRequestWithUrl:[self deviceServerUrl]
                                                 accept:@"application/vnd.imgtec.apientrypoint+json"
                                                   auth:oauthToken];
    return [request executeWithSharedUrlSessionAndReturnClass:[Api class] error:error];
}

#pragma mark - Private

- (NSURL *)deviceServerUrl {
    return [NSURL URLWithString:@"https://deviceserver.creatordev.io"];
}

@end
