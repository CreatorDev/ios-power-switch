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

#import "AccountsServerApi.h"
#import "Api.h"
#import "Developer.h"
#import "OauthToken.h"
#import "GETRequest.h"
#import "OauthRequest.h"

@interface AccountsServerApi ()
@property(nonatomic, nonnull, readonly) NSURL *accountsServerUrl;
@property(nonatomic, nullable) OauthToken *oauthToken;
@end

@implementation AccountsServerApi

#pragma mark - Public methods

- (nullable AccessKeys *)loginWithUsername:(nonnull NSString *)username
                                  password:(nonnull NSString *)password
                                     error:(NSError * _Nullable * _Nullable)error
{
    Api *api = [self accountsServerLinksWithError:error];
    if (api == nil) {
        return nil;
    }
    
    NSURL *authenticateUrl = [NSURL URLWithString:[api linkByRel:@"authenticate"].href];
    if (authenticateUrl == nil) {
        if (error) {
            *error = [NSError errorWithDomain:@"com.imgtec.example.PowerSwitch.app" code:0 userInfo:@{@"description": @"Authenticate link not present.", @"method": NSStringFromSelector(_cmd), @"api": api.description}];
        }
        return nil;
    }
    self.oauthToken = [self oauthTokenWithUrl:authenticateUrl
                                     username:username
                                     password:password
                                        error:error];
    if (self.oauthToken == nil) {
        return nil;
    }
    
    api = [self accountsServerLinksWithError:error];
    if (api == nil) {
        return nil;
    }
    
    NSURL *developerUrl = [NSURL URLWithString:[api linkByRel:@"developer"].href];
    if (developerUrl == nil) {
        NSLog(@"%@ Developer link not present.", NSStringFromSelector(_cmd));
        return nil;
    }
    Developer *developer = [self developerWithUrl:developerUrl error:error];
    if (developer == nil) {
        if (error) {
            *error = [NSError errorWithDomain:@"com.imgtec.example.PowerSwitch.app" code:0 userInfo:@{@"description": @"Developer link not present.", @"method": NSStringFromSelector(_cmd), @"api": api.description}];
        }
        return nil;
    }
    
    NSURL *accessKeysUrl = [NSURL URLWithString:[developer linkByRel:@"accesskeys"].href];
    if (accessKeysUrl == nil) {
        if (error) {
            *error = [NSError errorWithDomain:@"com.imgtec.example.PowerSwitch.app" code:0 userInfo:@{@"description": @"Access keys link not present.", @"method": NSStringFromSelector(_cmd), @"api": api.description}];
        }
        return nil;
    }
    return [self accessKeysWithUrl:accessKeysUrl error:error];
}

#pragma mark - Accounts Server methods

- (nullable Api *)accountsServerLinksWithError:(NSError * _Nullable * _Nullable)error {
    GETRequest *request = [GETRequest GETRequestWithUrl:[self accountsServerUrl]
                                                 accept:@"application/vnd.imgtec.apientrypoint+json"
                                                   auth:self.oauthToken];
    return [request executeWithSharedUrlSessionAndReturnClass:[Api class] error:error];
}

- (nullable OauthToken *)oauthTokenWithUrl:(nonnull NSURL *)url
                                  username:(nonnull NSString *)username
                                  password:(nonnull NSString *)password
                                     error:(NSError * _Nullable * _Nullable)error
{
    OauthRequest *request = [OauthRequest oauthRequestWithUrl:url
                                                     username:username
                                                     password:password];
    return [request executeWithSharedUrlSessionAndReturnClass:[OauthToken class] error:error];
}

- (nullable Developer *)developerWithUrl:(nonnull NSURL *)url
                                   error:(NSError * _Nullable * _Nullable)error
{
    GETRequest *request = [GETRequest GETRequestWithUrl:url
                                                 accept:@"application/vnd.imgtec.developer+json"
                                                   auth:self.oauthToken];
    return [request executeWithSharedUrlSessionAndReturnClass:[Developer class] error:error];
}

- (nullable AccessKeys *)accessKeysWithUrl:(nonnull NSURL *)url
                                     error:(NSError * _Nullable * _Nullable)error
{
    GETRequest *request = [GETRequest GETRequestWithUrl:url
                                                 accept:@"application/vnd.imgtec.accesskeys+json"
                                                   auth:self.oauthToken];
    return [request executeWithSharedUrlSessionAndReturnClass:[AccessKeys class] error:error];
}

#pragma mark - Private

- (NSURL *)accountsServerUrl {
    return [NSURL URLWithString:@"https://developeraccounts.flowcloud.systems"];
}

@end
