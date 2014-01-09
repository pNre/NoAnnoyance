#import <substrate.h>
#import <CoreFoundation/CoreFoundation.h>

#import <SpringBoard/SBAlertItemsController.h>
#import <SpringBoard/SBUserNotificationAlert.h>

#import <MobileGestalt/MobileGestalt.h>

#define SETTINGS_FILE @"/var/mobile/Library/Preferences/com.pNre.noannoyance.plist"

static bool IMPROVE_LOCATION_ACCURACY_WIFI = YES;

static bool EDGE_ALERT = YES;
static bool CELLULAR_DATA_IS_TURNED_OFF_FOR_APP_NAME = YES;
static bool AIRPLANE_CELL_PROMPT = YES;

static bool UNSUPPORTED_CHARGING_ACCESSORY = YES;
static bool ACCESSORY_UNRELIABLE = YES;

static bool LOW_BATTERY_ALERT = YES;

static bool LOW_DISK_SPACE_ALERT = YES;

static NSString * IMPROVE_LOCATION_ACCURACY_WIFI_string = nil;
static NSString * CELLULAR_DATA_IS_TURNED_OFF_FOR_APP_NAME_string = nil;
static NSString * ACCESSORY_UNRELIABLE_string = nil;

struct ChargingInfo {
    unsigned _ignoringEvents : 1;
    unsigned _lastVolumeDownToControl : 1;
    unsigned _isBatteryCharging : 1;
    unsigned _isOnAC : 1;
    unsigned _isConnectedToUnsupportedChargingAccessory : 1;
    unsigned _isConnectedToChargeIncapablePowerSource : 1;
    unsigned _allowAlertWindowRotation : 1;
};

%hook SBUIController

- (void)setIsConnectedToUnsupportedChargingAccessory:(BOOL)isConnectedToUnsupportedChargingAccessory {

    if (!UNSUPPORTED_CHARGING_ACCESSORY) {
        %orig;
        return;
    }

    struct ChargingInfo &chargingInfo = MSHookIvar<struct ChargingInfo>(self, "_isConnectedToUnsupportedChargingAccessory");
    chargingInfo._isConnectedToUnsupportedChargingAccessory = NO;

}

%end

%hook SBAlertItemsController

- (void)activateAlertItem:(id)alert {

    if ([alert isKindOfClass:[%c(SBLowPowerAlertItem) class]] && LOW_BATTERY_ALERT) {

        [self deactivateAlertItem:alert];
        return;

    }

    if ([alert isKindOfClass:[%c(SBLaunchAlertItem) class]] && AIRPLANE_CELL_PROMPT) {

        int _type = MSHookIvar<int>(alert, "_type");
        char _isDataAlert = MSHookIvar<char>(alert, "_isDataAlert");
        char _usesCellNetwork = MSHookIvar<char>(alert, "_usesCellNetwork");

        if (_type == 1 && _isDataAlert != 0 && _usesCellNetwork != 0) {

            [self deactivateAlertItem:alert];
            return;

        }
    }

    if ([alert isKindOfClass:[%c(SBEdgeActivationAlertItem) class]] && EDGE_ALERT) {

        [self deactivateAlertItem:alert];
        return;

    }

    if ([alert isKindOfClass:[%c(SBDiskSpaceAlertItem) class]] && LOW_DISK_SPACE_ALERT) {

        [self deactivateAlertItem:alert];
        return;

    }
    
    if ([alert isKindOfClass:[%c(SBUserNotificationAlert) class]])
    {

        if (
            ([[alert alertMessage] isEqual:IMPROVE_LOCATION_ACCURACY_WIFI_string] && IMPROVE_LOCATION_ACCURACY_WIFI) ||
            ([[alert alertMessage] isEqual:CELLULAR_DATA_IS_TURNED_OFF_FOR_APP_NAME_string] && CELLULAR_DATA_IS_TURNED_OFF_FOR_APP_NAME) ||
            ([[alert alertHeader] isEqual:ACCESSORY_UNRELIABLE_string] && ACCESSORY_UNRELIABLE)) {
            
            [self deactivateAlertItem:alert];
            return;
            
        }
    }
 
    %orig;
}

%end

static void reloadSettings() {

    NSDictionary * _settingsPlist = [NSDictionary dictionaryWithContentsOfFile:SETTINGS_FILE];

    if ([_settingsPlist objectForKey:@"IMPROVE_LOCATION_ACCURACY_WIFI"])
        IMPROVE_LOCATION_ACCURACY_WIFI = [[_settingsPlist objectForKey:@"IMPROVE_LOCATION_ACCURACY_WIFI"] boolValue];
    
    if ([_settingsPlist objectForKey:@"EDGE_ALERT"])
        EDGE_ALERT = [[_settingsPlist objectForKey:@"EDGE_ALERT"] boolValue];
    
    if ([_settingsPlist objectForKey:@"UNSUPPORTED_CHARGING_ACCESSORY"])
        UNSUPPORTED_CHARGING_ACCESSORY = [[_settingsPlist objectForKey:@"UNSUPPORTED_CHARGING_ACCESSORY"] boolValue];
    
    if ([_settingsPlist objectForKey:@"AIRPLANE_CELL_PROMPT"])
        AIRPLANE_CELL_PROMPT = [[_settingsPlist objectForKey:@"AIRPLANE_CELL_PROMPT"] boolValue];
    
    if ([_settingsPlist objectForKey:@"CELLULAR_DATA_IS_TURNED_OFF_FOR_APP_NAME"])
        CELLULAR_DATA_IS_TURNED_OFF_FOR_APP_NAME = [[_settingsPlist objectForKey:@"CELLULAR_DATA_IS_TURNED_OFF_FOR_APP_NAME"] boolValue];

    if ([_settingsPlist objectForKey:@"LOW_BATTERY_ALERT"])
        LOW_BATTERY_ALERT = [[_settingsPlist objectForKey:@"LOW_BATTERY_ALERT"] boolValue];
    
    if ([_settingsPlist objectForKey:@"ACCESSORY_UNRELIABLE"])
        ACCESSORY_UNRELIABLE = [[_settingsPlist objectForKey:@"ACCESSORY_UNRELIABLE"] boolValue];

    if ([_settingsPlist objectForKey:@"LOW_DISK_SPACE_ALERT"])
        LOW_DISK_SPACE_ALERT = [[_settingsPlist objectForKey:@"LOW_DISK_SPACE_ALERT"] boolValue];

}

static void reloadSettingsNotification(CFNotificationCenterRef notificationCenterRef, void * arg1, CFStringRef arg2, const void * arg3, CFDictionaryRef dictionary)
{
    reloadSettings();
}

%ctor {

    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    %init;

    //  load IMPROVE_LOCATION_ACCURACY_WIFI string from its bundle
    NSBundle * coreLocationBundle = [[NSBundle alloc] initWithPath:@"/System/Library/Frameworks/CoreLocation.framework"];

    if (coreLocationBundle) {

        IMPROVE_LOCATION_ACCURACY_WIFI_string = [[coreLocationBundle localizedStringForKey:@"IMPROVE_LOCATION_ACCURACY_WIFI" value:@"" table:@"locationd"] retain];

    } 

    //  load YOU_CAN_TURN_ON_CELLULAR_DATA_FOR_THIS_APP_IN_SETTINGS string from its bundle
    NSBundle * carrierBundle = [[NSBundle alloc] initWithPath:@"/var/mobile/Library/CarrierDefault.bundle"];

    if (carrierBundle) {

        CELLULAR_DATA_IS_TURNED_OFF_FOR_APP_NAME_string = [[carrierBundle localizedStringForKey:@"YOU_CAN_TURN_ON_CELLULAR_DATA_FOR_THIS_APP_IN_SETTINGS" value:@"" table:@"DataUsage"] retain];

    }

    //  load ACCESSORY_UNRELIABLE string from its bundle
    NSBundle * IAPBundle = [NSBundle bundleWithIdentifier:@"com.apple.IAP"];

    if (IAPBundle) {

        CFStringRef deviceClass = (CFStringRef)MGCopyAnswer(kMGDeviceClass);

        NSString * sDeviceClass = (NSString *)deviceClass;
        NSMutableString * keyName = [NSMutableString stringWithString:@"ACCESSORY_UNRELIABLE"];

        if ([sDeviceClass isEqualToString:@"iPhone"])
            [keyName appendString:@"_IPHONE"];
        else if ([sDeviceClass isEqualToString:@"iPad"])
            [keyName appendString:@"_IPAD"];
        else
            [keyName appendString:@"_IPOD"];

        ACCESSORY_UNRELIABLE_string = [[IAPBundle localizedStringForKey:keyName value:@"" table:@"Framework"] retain];

        CFRelease(deviceClass);

    }

    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)reloadSettingsNotification, CFSTR("com.pNre.noannoyance/settingsupdated"), NULL, CFNotificationSuspensionBehaviorCoalesce);
    reloadSettings();

    [pool release];

}
