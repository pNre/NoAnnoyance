#import <Preferences/Preferences.h>
#import "NoAnnoyanceSettings.h"

@implementation NoAnnoyanceSBSettingsListController

- (id)specifiers {

    if (_specifiers == nil)
        _specifiers = [[self loadSpecifiersFromPlistName:@"NoAnnoyanceSBSettings" target:self] retain];

    return _specifiers;
}

@end

@implementation NoAnnoyanceMLSettingsListController

- (id)specifiers {

    if (_specifiers == nil)
        _specifiers = [[self loadSpecifiersFromPlistName:@"NoAnnoyanceMLSettings" target:self] retain];

    return _specifiers;
}

@end

@implementation NoAnnoyanceGCSettingsListController

- (id)specifiers {

    if (_specifiers == nil)
        _specifiers = [[self loadSpecifiersFromPlistName:@"NoAnnoyanceGCSettings" target:self] retain];

    return _specifiers;
}

@end

@implementation NoAnnoyanceSRSettingsListController {
    BOOL _settingsChanged;
}

- (id)specifiers {

    if (_specifiers == nil)
        _specifiers = [[self loadSpecifiersFromPlistName:@"NoAnnoyanceSRSettings" target:self] retain];

    return _specifiers;
}

- (void)settingsChangedWithBlock:(void (^)(void))block {

    if (!_settingsChanged) {
        _settingsChanged = YES;
        block();
    }

}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)spec {

    [super setPreferenceValue:value specifier:spec];

    [self settingsChangedWithBlock:^{
        UIBarButtonItem *respringButton = [[UIBarButtonItem alloc] initWithTitle:@"Respring" style:UIBarButtonItemStyleDone target:self action:@selector(respring:)];
        [[self navigationItem] setRightBarButtonItem:respringButton];
        [respringButton release];
    }];

}

- (void)respring:(id)sender {

    setuid(0);
    system("killall SpringBoard");

}

@end
