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

#import "LoginViewController.h"
#import "DataApi.h"
#import "AppDelegate.h"
#import "DataStore.h"
#import "SecureDataStore.h"

@interface LoginViewController ()
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UISwitch *keepMeSignedInSwitch;
@property (weak, nonatomic) IBOutlet UILabel *keepMeSignedInLabel;
@property (weak, nonatomic) IBOutlet UIButton *learnMoreButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (nonatomic, readonly, nonnull) DataApi *dataApi;
@property (nonatomic, readonly) NSURL *learnMoreUrl;
@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if ([[DataStore class] readKeepMeSignedIn]) {
        [self silentLogin];
    }
    self.versionLabel.text = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - IBAction

- (IBAction)loginAction {
    [self showLoginActivityIndicator:YES];
    [[DataStore class]  storeKeepMeSignedIn:self.keepMeSignedInSwitch.on];
    
    __weak typeof(self) weakSelf = self;
    [self.dataApi loginWithSuccess:^{
        [weakSelf presentMainViewController];
        [weakSelf showLoginActivityIndicator:NO];
    } failure:^(NSError * _Nullable error) {
        NSLog(@"ERROR login: %@", error);
        [weakSelf showLoginActivityIndicator:NO];
    }];
}

- (IBAction)linkAction {
    if (self.learnMoreUrl) {
        [[UIApplication sharedApplication] openURL:self.learnMoreUrl];
    }
}

#pragma mark - Private

- (void)silentLogin {
    if ([self.dataApi isSilentLoginStartPossible]) {
        [self showSilentLoginActivityIndicator:YES];
        
        __weak typeof(self) weakSelf = self;
        [self.dataApi silentLoginWithSuccess:^{
            [weakSelf presentMainViewController];
        } failure:^(NSError * _Nullable error) {
            NSLog(@"ERROR silent login: %@", error);
            [weakSelf showSilentLoginActivityIndicator:NO];
        }];
    }
}

- (void)showSilentLoginActivityIndicator:(BOOL)on {
    self.loginButton.hidden = on;
    self.keepMeSignedInSwitch.hidden = on;
    self.keepMeSignedInLabel.hidden = on;
    self.learnMoreButton.hidden = on;
    self.activityIndicator.hidden = !on;
}

- (void)showLoginActivityIndicator:(BOOL)on {
    self.loginButton.enabled = !on;
}

- (void)presentMainViewController {
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    appDelegate.window.rootViewController = [mainStoryboard instantiateInitialViewController];
}

#pragma mark - Private (setters/getters)

- (DataApi *)dataApi {
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    return appDelegate.dataApi;
}

- (NSURL *)learnMoreUrl {
    return [NSURL URLWithString:@"http://creatordev.io"];
}

@end
