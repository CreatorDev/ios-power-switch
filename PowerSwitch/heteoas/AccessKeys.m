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

#import "AccessKeys.h"
#import "PageInfo.h"

@implementation AccessKeys

- (NSString *)description {
    NSMutableString *mainStr = [NSMutableString new];
    [mainStr appendString:@"AccessKeys:[\n"];
    for (AccessKey *accessKey in self.items) {
        [mainStr appendString:[NSString stringWithFormat:@"%@\n", accessKey]];
    }
    [mainStr appendString:@"]"];
    
    if (self.links.count > 0) {
        return [NSString stringWithFormat:@"{%@\n%@}", mainStr, [super description]];
    }
    
    return [mainStr copy];
}

#pragma mark - JsonInit protocol

- (nullable instancetype)initWithJson:(nonnull NSData *)jsonData {
    self = [super initWithJson:jsonData];
    if (self) {
        if (NO == [self parseAccessKeysJson:jsonData]) {
            self = nil;
        }
    }
    return self;
}

#pragma mark - Private

- (void)validatePageInfoWithJson:(nonnull id)json {
    PageInfo *pageInfo = [[PageInfo alloc] initWithJson:json];
    if (pageInfo.itemsCount != pageInfo.totalCount) {
        NSLog(@"%@ Not all access keys are retrieved.", NSStringFromSelector(_cmd));
    }
}

- (BOOL)parseAccessKeysJson:(nonnull id)json {
    [self validatePageInfoWithJson:json];
    
    NSMutableArray<AccessKey *> *accessKeysArr = [NSMutableArray new];
    if ([json isKindOfClass:[NSDictionary class]] &&
        [json[@"Items"] isKindOfClass:[NSArray class]])
    {
        for (id item in json[@"Items"]) {
            if ([item isKindOfClass:[NSDictionary class]])
            {
                AccessKey *accessKey = [[AccessKey alloc] initWithJson:item];
                if (accessKey) {
                    [accessKeysArr addObject:accessKey];
                } else {
                    NSLog(@"%@ Access key is not valid (%@).", NSStringFromSelector(_cmd), item);
                    return NO;
                }
            } else {
                NSLog(@"%@ AccessKey is not dictionary (%@).", NSStringFromSelector(_cmd), item);
                return NO;
            }
        }
    }
    self.items = [accessKeysArr copy];
    return YES;
}

@end
