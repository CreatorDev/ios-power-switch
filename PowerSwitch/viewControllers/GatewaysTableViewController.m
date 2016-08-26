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

#import "GatewaysTableViewController.h"
#import "AppDelegate.h"
#import "AppData.h"
#import "DataApi.h"
#import <CreatorKit/LoginApi.h>
#import "RelayDevicesViewController.h"
#import "GatewayTableViewCell.h"

@interface GatewaysTableViewController () <UITableViewDataSource>
@property(nonatomic, readonly, nonnull) AppData *appData;
@property(nonatomic, strong, nullable) DataApi *dataApi;
@end

@implementation GatewaysTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupRefreshControl];
    [self observeClients:YES];
    [self reloadGateways];
}

- (void)dealloc {
    [self observeClients:NO];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showGatewayDetails"] &&
        [segue.destinationViewController isKindOfClass:[RelayDevicesViewController class]])
    {
        RelayDevicesViewController *destinationVC = (RelayDevicesViewController *)segue.destinationViewController;
        if ([sender isKindOfClass:[GatewayTableViewCell class]]) {
            GatewayTableViewCell *cell = sender;
            destinationVC.client = [self.appData clientByIdentifier:cell.clientIdentifier];
            [destinationVC setDataApi:self.dataApi];
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSString *,id> *)change
                       context:(void *)context
{
    if ([keyPath isEqualToString:@"appData.clients"] && object == self) {
        [self.tableView reloadData];
    }
}

#pragma mark - IBAction

- (IBAction)refreshControlValueChanged:(id)sender {
    [self reloadGateways];
}

- (IBAction)logoutAction:(UIBarButtonItem *)sender {
    [[LoginApi class] logout];
    [self presentLoginViewController];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return self.appData.clients.items.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    GatewayTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GatewayCell" forIndexPath:indexPath];
    
    Client *client = self.appData.clients.items[indexPath.row];
    
    cell.clientIdentifier = [client linkByRel:@"self"].href;
    cell.nameLabel.text = client.name;
    return cell;
}

#pragma mark - ProvideDeviceServerApiProtocol

#pragma mark - Private

- (void)reloadGateways {
    __weak typeof(self) weakSelf = self;
    [self.dataApi requestGatewaysWithSuccess:^(Clients * _Nonnull clients) {
        weakSelf.appData.clients = clients;
        [weakSelf.refreshControl endRefreshing];
    } failure:^(NSError * _Nullable error) {
        NSLog(@"ERROR getting gateways: %@", error);
        [weakSelf.refreshControl endRefreshing];
    }];
}

- (void)setupRefreshControl {
    self.refreshControl = [UIRefreshControl new];
    [self.refreshControl addTarget:self action:@selector(refreshControlValueChanged:) forControlEvents:UIControlEventValueChanged];
}

- (void)observeClients:(BOOL)observe {
    if (observe) {
        [self addObserver:self forKeyPath:@"appData.clients" options:NSKeyValueObservingOptionNew context:nil];
    } else {
        [self removeObserver:self forKeyPath:@"appData.clients"];
    }
}

- (void)presentLoginViewController {
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    appDelegate.window.rootViewController = [[LoginApi class] loginViewControllerWithLoginDelegate:appDelegate];
}

#pragma mark - Private (setters/getters)

- (AppData *)appData {
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    return appDelegate.appData;
}

@end
