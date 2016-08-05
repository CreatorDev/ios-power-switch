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

#import "CreatorTextField.h"
#import "GlobalStyle.h"

@interface CreatorTextField ()
@property (nonatomic, weak, nullable) UIView *underlineView;
@property (nonatomic, strong, nonnull) NSArray<NSLayoutConstraint *> *underlineSelectedVerticalConstraints;
@property (nonatomic, strong, nonnull) NSArray<NSLayoutConstraint *> *underlineNotSelectedVerticalConstraints;
@end

@implementation CreatorTextField

- (void)prepareForInterfaceBuilder {
    [self setupAppearance];
    [self duplicatePlaceholder];
    [self addUnderlineSubview];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self addUnderlineSubview];
        [self setupAppearance];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setupAppearance];
    [self duplicatePlaceholder];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (UIColor *)creatorPrimaryColor {
    if (_creatorPrimaryColor == nil) {
        return [[GlobalStyle class] textPrimaryColor];
    }
    return _creatorPrimaryColor;
}

- (UIColor *)creatorPlaceholderColor {
    if (_creatorPlaceholderColor == nil) {
        return [[GlobalStyle class] textDisabledColor];
    }
    return _creatorPlaceholderColor;
}

- (void)markError:(BOOL)error {
    if (error) {
        self.underlineView.backgroundColor = [[GlobalStyle class] textFieldErrorUnderlineColor];
    } else {
        self.underlineView.backgroundColor = [[GlobalStyle class] textFieldDefaultUnderlineColor];
    }
}

- (void)setupAppearance {
    self.font = [UIFont fontWithName:@"Roboto-Regular" size:self.font.pointSize];
    self.clipsToBounds = NO;
    self.textColor = self.creatorPrimaryColor;
}

- (void)duplicatePlaceholder {
    self.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.placeholder attributes:@{NSForegroundColorAttributeName: self.creatorPlaceholderColor}];
}

- (void)addUnderlineSubview {
    UIView *underlineView = [[UIView alloc] init];
    underlineView.translatesAutoresizingMaskIntoConstraints = NO;
    underlineView.backgroundColor = [[GlobalStyle class] textFieldDefaultUnderlineColor];
    [self addSubview:underlineView];
    self.underlineView = underlineView;
    
    NSDictionary *views = NSDictionaryOfVariableBindings(underlineView);
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[underlineView]-0-|" options:0 metrics:nil views:views]];

    self.underlineNotSelectedVerticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[underlineView(1)]-BELOW-|" options:0 metrics:@{@"BELOW": @(-2)} views:views];
    self.underlineSelectedVerticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[underlineView(2)]-BELOW-|" options:0 metrics:@{@"BELOW": @(-3)} views:views];

    [NSLayoutConstraint deactivateConstraints:self.underlineSelectedVerticalConstraints];
    [NSLayoutConstraint activateConstraints:self.underlineNotSelectedVerticalConstraints];
    
    __weak typeof(self) weakSelf = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:UITextFieldTextDidBeginEditingNotification object:self queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        weakSelf.underlineView.backgroundColor = [[GlobalStyle class] textFieldSelectedUnderlineColor];
        [NSLayoutConstraint deactivateConstraints:weakSelf.underlineNotSelectedVerticalConstraints];
        [NSLayoutConstraint activateConstraints:weakSelf.underlineSelectedVerticalConstraints];
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:UITextFieldTextDidEndEditingNotification object:self queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        weakSelf.underlineView.backgroundColor = [[GlobalStyle class] textFieldDefaultUnderlineColor];
        [NSLayoutConstraint deactivateConstraints:weakSelf.underlineSelectedVerticalConstraints];
        [NSLayoutConstraint activateConstraints:weakSelf.underlineNotSelectedVerticalConstraints];
    }];
}

- (void)setPlaceholder:(NSString *)placeholder {
    [super setPlaceholder:placeholder];
    [self duplicatePlaceholder];
}

@end
