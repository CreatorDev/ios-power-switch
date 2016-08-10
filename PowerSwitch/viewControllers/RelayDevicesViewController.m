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

#import "RelayDevicesViewController.h"
#import "AppDelegate.h"
#import "DataApi.h"
#import "ObjectTypes.h"
#import "RelayDeviceTableViewCell.h"

@interface TimerTarget : NSObject
@property(weak, nonatomic) id realTarget;
@end

@implementation TimerTarget
- (void)pollingTimerFired:(NSTimer*)timer {
    [self.realTarget performSelector:@selector(pollingTimerFired:) withObject:timer];
}
@end

@interface RelayDevicesViewController () <RelayDeviceStateChangeDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, readonly, nonnull) DataApi *dataApi;
@property (nonatomic, strong, nullable) NSArray<RelayDevice *> *relayDevices;
@property (nonatomic, strong, nonnull) NSOperationQueue *pollingQueue;
@property (nonatomic, weak, nullable) NSTimer *pollingTimer;
@end

@implementation RelayDevicesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.client.name;
    [self requestRelayDevices];
    [self startPollingTimer];
}

- (void)dealloc {
    [self.pollingTimer invalidate];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return self.relayDevices.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    RelayDeviceTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"RelayDeviceCell" forIndexPath:indexPath];
    
    RelayDevice *relayDevice = self.relayDevices[indexPath.row];
    
    cell.instanceId = relayDevice.instanceId;
    cell.relayState.on = relayDevice.resources.digitalOutputState.boolValue;
    cell.nameLabel.text = [NSString stringWithFormat:@"Relay %@", relayDevice.instanceId];
    cell.relayStateDelegate = self;
    return cell;
}

#pragma - RelayDeviceStateChangeDelegate

- (void)relayDeviceStateChangeForInstanceId:(nonnull NSNumber *)instanceId newState:(BOOL)state {
    RelayDevice *relayDevice = [self relayDeviceWithInstanceId:instanceId];
    if (relayDevice) {
        [self.dataApi setRelayDeviceState:relayDevice newValue:state success:nil failure:^(NSError * _Nullable error) {
             NSLog(@"device state set failure: %@", error);
            [self requestRelayDevices];
         }];
    }
}

#pragma mark - Private

- (nullable RelayDevice *)relayDeviceWithInstanceId:(nonnull NSNumber *)instanceId {
    for (RelayDevice *relayDevice in self.relayDevices) {
        if (relayDevice.instanceId && relayDevice.instanceId.unsignedIntegerValue == instanceId.unsignedIntegerValue) {
            return relayDevice;
        }
    }
    return nil;
}

- (void)requestRelayDevices {
    if (self.pollingQueue.operations.count == 0) {
        __weak typeof(self) weakSelf = self;
        
        [self.pollingQueue addOperation:[NSBlockOperation blockOperationWithBlock:^{
            if (weakSelf.client) {
                dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
                [weakSelf.dataApi requestRelayDevicesForClient:weakSelf.client success:^(NSArray<RelayDevice *> * _Nonnull relayDevices) {
                    weakSelf.relayDevices = relayDevices;
                    [weakSelf.tableView reloadData];
                    dispatch_semaphore_signal(semaphore);
                } failure:^(NSError * _Nullable error) {
                    NSLog(@"ERROR getting relays: %@", error);
                    dispatch_semaphore_signal(semaphore);
                }];
                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            }
        }]];
    }
}

- (void)pollingTimerFired:(NSTimer *)timer {
    [self requestRelayDevices];
}

- (void)startPollingTimer {
    if (self.pollingTimer == nil) {
        TimerTarget *timerTarget = [TimerTarget new];
        timerTarget.realTarget = self;
        self.pollingTimer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:timerTarget selector:@selector(pollingTimerFired:) userInfo:nil repeats:YES];
    };
}

#pragma mark - Private (setters/getters)

- (DataApi *)dataApi {
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    return appDelegate.dataApi;
}

- (NSOperationQueue *)pollingQueue {
    if (_pollingQueue == nil) {
        _pollingQueue = [NSOperationQueue new];
        _pollingQueue.maxConcurrentOperationCount = 1;
        _pollingQueue.name = @"Relay Devices polling queue";
    }
    return _pollingQueue;
}

@end
