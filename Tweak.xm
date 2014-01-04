#import <substrate.h>
#import <CoreFoundation/CoreFoundation.h>

#define SETTINGS_FILE @"/var/mobile/Library/Preferences/com.pNre.noannoyance.plist"

static bool IMPROVE_LOCATION_ACCURACY_WIFI = YES;
static bool EDGE_ALERT = YES;
static bool UNSUPPORTED_CHARGING_ACCESSORY = YES;
static bool AIRPLANE_CELL_PROMPT = YES;

static NSString * IMPROVE_LOCATION_ACCURACY_WIFI_string = nil;

@interface SBAlertItemsController

+ (id)sharedInstance;

- (void)deactivateAlertItem:(id)arg1;

@end

@interface SBUserNotificationAlert

@property(retain) NSString * alertMessage;

@end

%hook SBUIController

- (void)setIsConnectedToUnsupportedChargingAccessory:(BOOL)isConnectedToUnsupportedChargingAccessory {

    if (!UNSUPPORTED_CHARGING_ACCESSORY) {
        %orig;
        return;
    }

    BOOL &_isConnectedToUnsupportedChargingAccessory = MSHookIvar<BOOL>(self, "_isConnectedToUnsupportedChargingAccessory");

    _isConnectedToUnsupportedChargingAccessory = NO;

}

%end

%hook SBAlertItemsController

- (void)activateAlertItem:(id)alert {

    if ([alert isKindOfClass:[%c(SBLaunchAlertItem) class]] && AIRPLANE_CELL_PROMPT) {

        int _type = MSHookIvar<int>(alert, "_type");
        char _isDataAlert = MSHookIvar<char>(alert, "_isDataAlert");
        char _usesCellNetwork = MSHookIvar<char>(alert, "_usesCellNetwork");

        if (_type == 1 && _isDataAlert != 0 && _usesCellNetwork != 0) {

            [self deactivateAlertItem:alert];
            return;

        }
    }

    if ([alert isKindOfClass:[%c(SBEdgeActivationAlertItem) class]] && EDGE_ALERT)
    {
        [self deactivateAlertItem:alert];
        return;
    }
    
    if ([alert isKindOfClass:[%c(SBUserNotificationAlert) class]] && IMPROVE_LOCATION_ACCURACY_WIFI)
    {
        if ([[alert alertMessage] isEqual:IMPROVE_LOCATION_ACCURACY_WIFI_string]) {
            
            [self deactivateAlertItem:alert];
            return;
            
        }
    }
 
    %orig;
}

%end

void LoadSettings(CFNotificationCenterRef notificationCenterRef, void * arg1, CFStringRef arg2, const void * arg3, CFDictionaryRef dictionary)
{
    NSDictionary * _settingsPlist = [NSDictionary dictionaryWithContentsOfFile:SETTINGS_FILE];

    if ([_settingsPlist objectForKey:@"IMPROVE_LOCATION_ACCURACY_WIFI"])
        IMPROVE_LOCATION_ACCURACY_WIFI = [[_settingsPlist objectForKey:@"IMPROVE_LOCATION_ACCURACY_WIFI"] boolValue];
    
    if ([_settingsPlist objectForKey:@"EDGE_ALERT"])
        EDGE_ALERT = [[_settingsPlist objectForKey:@"EDGE_ALERT"] boolValue];
    
    if ([_settingsPlist objectForKey:@"UNSUPPORTED_CHARGING_ACCESSORY"])
        UNSUPPORTED_CHARGING_ACCESSORY = [[_settingsPlist objectForKey:@"UNSUPPORTED_CHARGING_ACCESSORY"] boolValue];
    
    if ([_settingsPlist objectForKey:@"AIRPLANE_CELL_PROMPT"])
        AIRPLANE_CELL_PROMPT = [[_settingsPlist objectForKey:@"AIRPLANE_CELL_PROMPT"] boolValue];

}

%ctor {

    //  Load IMPROVE_LOCATION_ACCURACY_WIFI string from its bundle
    NSBundle * coreLocationBundle = [[NSBundle alloc] initWithPath:@"/System/Library/Frameworks/CoreLocation.framework"];

    if (coreLocationBundle) {

        [coreLocationBundle load];
        IMPROVE_LOCATION_ACCURACY_WIFI_string = [[coreLocationBundle localizedStringForKey:@"IMPROVE_LOCATION_ACCURACY_WIFI" value:@"" table:@"locationd"] copy];

    } 

    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)LoadSettings, CFSTR("com.pNre.noannoyance/settingsupdated"), NULL, CFNotificationSuspensionBehaviorCoalesce);
    LoadSettings(NULL, NULL, NULL, NULL, NULL);

}
