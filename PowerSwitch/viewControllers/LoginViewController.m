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
#import "CreatorTextField.h"
#import "SecureDataStore.h"

@interface LoginViewController () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet CreatorTextField *usernameTextField;
@property (weak, nonatomic) IBOutlet CreatorTextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UILabel *errorLabel;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIButton *visitUsButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (nonatomic, readonly, nonnull) DataApi *dataApi;
@property (nonatomic, readonly) NSURL *visitUsUrl;
@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self resetScrollView];
    [self observeKeyboard];
    [self silentLogin];
}

#pragma mark - IBAction

- (IBAction)loginAction {
    [self.usernameTextField resignFirstResponder];
    [self.passwordTextField resignFirstResponder];
    [self.usernameTextField markError:NO];
    [self.passwordTextField markError:NO];
    
    NSString *username = self.usernameTextField.text;
    NSString *password = self.passwordTextField.text;
    [self showLoginActivityIndicator:YES];
    
    __weak typeof(self) weakSelf = self;
    [self.dataApi loginWithUsername:username password:password success:^{
        [weakSelf presentMainViewController];
        [weakSelf showLoginActivityIndicator:NO];
    } failure:^(NSError * _Nullable error) {
        [weakSelf showLoginActivityIndicator:NO];
        [weakSelf.usernameTextField markError:YES];
        [weakSelf.passwordTextField markError:YES];
    }];
}

- (IBAction)linkAction {
    if (self.visitUsUrl) {
        [[UIApplication sharedApplication] openURL:self.visitUsUrl];
    }
}

- (IBAction)handleTapGasture:(UITapGestureRecognizer *)sender {
    [self.usernameTextField resignFirstResponder];
    [self.passwordTextField resignFirstResponder];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.usernameTextField) {
        [self.passwordTextField becomeFirstResponder];
        return YES;
    } else if (textField == self.passwordTextField) {
        [self.passwordTextField resignFirstResponder];
        [self loginAction];
        return YES;
    }
    return NO;
}

#pragma mark - Private

- (void)silentLogin {
    if ([self.dataApi isSilentLoginStartPossible]) {
        [self showSilentLoginActivityIndicator:YES];
        
        __weak typeof(self) weakSelf = self;
        [self.dataApi silentLoginWithSuccess:^{
            [weakSelf presentMainViewController];
        } failure:^(NSError * _Nullable error) {
            [weakSelf showSilentLoginActivityIndicator:NO];
        }];
    }
}

- (void)showSilentLoginActivityIndicator:(BOOL)on {
    self.usernameTextField.hidden = on;
    self.passwordTextField.hidden = on;
    self.errorLabel.hidden = on;
    self.loginButton.hidden = on;
    self.visitUsButton.hidden = on;
    self.activityIndicator.hidden = !on;
}

- (void)showLoginActivityIndicator:(BOOL)on {
    if (on) {
        self.errorLabel.hidden = YES;
    }
    self.loginButton.enabled = !on;
    self.usernameTextField.enabled = !on;
    self.passwordTextField.enabled = !on;
}

- (void)presentMainViewController {
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    appDelegate.window.rootViewController = [mainStoryboard instantiateInitialViewController];
}

- (void)resetScrollView {
    self.scrollView.contentInset = UIEdgeInsetsMake(0.0, 0.0, 1.0, 0.0);
    self.scrollView.scrollIndicatorInsets = UIEdgeInsetsZero;
    self.scrollView.contentOffset = CGPointZero;
}

- (BOOL)isScrollViewReset {
    return self.scrollView.contentInset.bottom == 1.0;
}

- (void)observeKeyboard {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)handleKeyboardWillShow:(NSNotification *)notification {
    if (NO == [self isScrollViewReset]) {
        return;
    }
    
    CGRect keyboardRect = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    UIEdgeInsets contentInset = UIEdgeInsetsMake(0.0, 0.0, keyboardRect.size.height, 0.0);
    self.scrollView.contentInset = contentInset;
    self.scrollView.scrollIndicatorInsets = contentInset;
    
    CGRect loginButtonRect = [self.loginButton.superview convertRect:self.loginButton.frame toView:nil];
    if (CGRectIntersectsRect(loginButtonRect, keyboardRect)) {
        CGFloat dy = (loginButtonRect.origin.y + loginButtonRect.size.height) - keyboardRect.origin.y;
        self.scrollView.contentOffset = CGPointMake(0.0, dy + 10.0);
    }
}

- (void)handleKeyboardWillHide:(NSNotification *)notification {
    [self resetScrollView];
}

#pragma mark - Private (setters/getters)

- (DataApi *)dataApi {
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    return appDelegate.dataApi;
}

- (NSURL *)visitUsUrl {
    return [NSURL URLWithString:@"http://creator.io"];
}

@end
