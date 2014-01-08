#import <Preferences/Preferences.h>
#import "NoAnnoyanceSettings.h"

@implementation NoAnnoyanceSettingsListController

- (id)specifiers {

    if (_specifiers == nil)
        _specifiers = [[self loadSpecifiersFromPlistName:@"NoAnnoyanceSettings" target:self] retain];

    return _specifiers;
}

@end
