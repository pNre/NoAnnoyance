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
