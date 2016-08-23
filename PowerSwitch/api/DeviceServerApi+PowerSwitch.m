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

#import "DeviceServerApi+PowerSwitch.h"
#import <CreatorKit/Api.h>
#import <CreatorKit/GETRequest.h>
#import <CreatorKit/PUTRequest.h>

@implementation DeviceServerApi (Other)

- (nullable Api *)deviceServerLinksWithError:(NSError * _Nullable * _Nullable)error {
    return [self deviceServerLinksWithAuthToken:self.oauthToken error:error];
}

- (nullable Clients *)clientsWithError:(NSError * _Nullable * _Nullable)error {
    Api *api = [self deviceServerLinksWithError:error];
    if (api == nil) {
        return nil;
    }
    
    NSURL *clientsUrl = [NSURL URLWithString:[api linkByRel:@"clients"].href];
    if (clientsUrl == nil) {
        if (error) {
            *error = [NSError errorWithDomain:@"io.creatordev.PowerSwitch.app" code:0 userInfo:@{@"description": @"Clients link not present.", @"method": NSStringFromSelector(_cmd), @"api": api.description}];
        }
        return nil;
    }
    
    GETRequest *request = [GETRequest GETRequestWithUrl:clientsUrl
                                                 accept:@"application/vnd.imgtec.clients+json"
                                                   auth:self.oauthToken];
    return [request executeWithSharedUrlSessionAndReturnClass:[Clients class] error:error];
}

- (nullable ObjectTypes *)objectTypesForClient:(nonnull Client *)client
                                         error:(NSError * _Nullable * _Nullable)error
{
    NSURL *objectTypesUrl = [NSURL URLWithString:[client linkByRel:@"objecttypes"].href];
    GETRequest *request = [GETRequest GETRequestWithUrl:objectTypesUrl
                                                 accept:@"application/vnd.imgtec.objecttypes+json"
                                                   auth:self.oauthToken];
    return [request executeWithSharedUrlSessionAndReturnClass:[ObjectTypes class] error:error];
}

- (nullable Instances *)objectInstancesForObjectType:(nonnull ObjectType *)objectType
                                               error:(NSError * _Nullable * _Nullable)error
{
    NSURL *objectInstancesUrl = [NSURL URLWithString:[objectType linkByRel:@"instances"].href];
    NSString *accept = [NSString stringWithFormat:@"application/vnd.oma.lwm2m.ext:%@s+json", objectType.objectTypeID];
    
    GETRequest *request = [GETRequest GETRequestWithUrl:objectInstancesUrl accept:accept auth:self.oauthToken];
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
    PUTRequest *request = [PUTRequest PUTRequestWithUrl:objectInstanceUrl contentType:@"application/json; charset=utf-8" body:data auth:self.oauthToken];
    [request executeWithSharedUrlSessionAndReturnClass:nil error:&err];
    if (error) {
        *error = err;
    }
    return err != nil;
}

@end
