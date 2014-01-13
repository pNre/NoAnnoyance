#import <substrate.h>
#import <CoreFoundation/CoreFoundation.h>

#import <SpringBoard/SBAlertItemsController.h>
#import <SpringBoard/SBUserNotificationAlert.h>
#import <SpringBoard/SBApplication.h>
#import <SpringBoard/SBWorkspace.h>

#import <MobileGestalt/MobileGestalt.h>

#import <UIKit/UIKit.h>

#define SETTINGS_FILE @"/var/mobile/Library/Preferences/com.pNre.noannoyance.plist"

//  Global
static BOOL WorksInFullScreen = YES;

//  SpringBoard
static BOOL IMPROVE_LOCATION_ACCURACY_WIFI = YES;

static BOOL EDGE_ALERT = YES;
static BOOL CELLULAR_DATA_IS_TURNED_OFF_FOR_APP_NAME = YES;
static BOOL AIRPLANE_CELL_PROMPT = YES;
static BOOL AIRPLANE_DATA_PROMPT = YES;

static BOOL UNSUPPORTED_CHARGING_ACCESSORY = YES;
static BOOL ACCESSORY_UNRELIABLE = YES;

static BOOL LOW_BATTERY_ALERT = YES;

static BOOL LOW_DISK_SPACE_ALERT = YES;

static NSString * IMPROVE_LOCATION_ACCURACY_WIFI_string = nil;
static NSString * CELLULAR_DATA_IS_TURNED_OFF_FOR_APP_NAME_string = nil;
static NSString * ACCESSORY_UNRELIABLE_string = nil;

//  Mail
static BOOL CONNECTION_FAILED = YES;

static NSString * CONNECTION_FAILED_string = nil;

static SBWorkspace * Workspace = nil;

struct ChargingInfo {
    unsigned _ignoringEvents : 1;
    unsigned _lastVolumeDownToControl : 1;
    unsigned _isBatteryCharging : 1;
    unsigned _isOnAC : 1;
    unsigned _isConnectedToUnsupportedChargingAccessory : 1;
    unsigned _isConnectedToChargeIncapablePowerSource : 1;
    unsigned _allowAlertWindowRotation : 1;
};

static BOOL CanHook() {

    NSString * topApplication = [[Workspace bksWorkspace] topApplication];

    if (!topApplication)
        return YES;

    SBApplication * runningApp = [Workspace _applicationForBundleIdentifier:topApplication frontmost:YES];

    if (![runningApp statusBarHidden])
        return YES;

    return WorksInFullScreen;

}

%group SpringBoard

%hook SBWorkspace

- (id)init
{
    self = %orig;

    if (self)
        Workspace = [self retain];

    return self;
}

- (void)dealloc
{
    if (Workspace == self) {
        [Workspace release];
        Workspace = nil;
    }

    %orig;
}

%end

%hook SBUIController

- (void)setIsConnectedToUnsupportedChargingAccessory:(BOOL)isConnectedToUnsupportedChargingAccessory {

    if (!UNSUPPORTED_CHARGING_ACCESSORY ||
        !CanHook()) {
        %orig;
        return;
    }

    struct ChargingInfo &chargingInfo = MSHookIvar<struct ChargingInfo>(self, "_isConnectedToUnsupportedChargingAccessory");
    chargingInfo._isConnectedToUnsupportedChargingAccessory = NO;

}

%end

%hook SBAlertItemsController

- (void)activateAlertItem:(id)alert {

    if (!CanHook()) {
        %orig;
        return;
    }

    if ([alert isKindOfClass:[%c(SBLowPowerAlertItem) class]] && LOW_BATTERY_ALERT) {

        [self deactivateAlertItem:alert];
        return;

    }

    if ([alert isKindOfClass:[%c(SBLaunchAlertItem) class]]) {

        int _type = MSHookIvar<int>(alert, "_type");
        char _isDataAlert = MSHookIvar<char>(alert, "_isDataAlert");
        char _usesCellNetwork = MSHookIvar<char>(alert, "_usesCellNetwork");

        if (_type == 1) {

            BOOL cellPrompt = (_isDataAlert != 0 && _usesCellNetwork != 0) && AIRPLANE_CELL_PROMPT;
            BOOL dataPrompt = (_isDataAlert != 0 && _usesCellNetwork != 1) && AIRPLANE_DATA_PROMPT;

            if (cellPrompt || dataPrompt) {

                [self deactivateAlertItem:alert];
                return;

            }

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

%end

%group Mail

%hook MailErrorHandler

- (BOOL)shouldDisplayError:(NSError *)error forAccount:(id)account mode:(int)mode {

    if (!CanHook())
        return %orig;

    if (CONNECTION_FAILED && account && [account respondsToSelector:@selector(hostname)]) {

        NSString * errorDescription = [error localizedDescription];
        if ([errorDescription isEqualToString:[NSString stringWithFormat:CONNECTION_FAILED_string, [account performSelector:@selector(hostname)]]])
            return YES;

    }

    return %orig;

}

%end

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
    
    if ([_settingsPlist objectForKey:@"AIRPLANE_DATA_PROMPT"])
        AIRPLANE_DATA_PROMPT = [[_settingsPlist objectForKey:@"AIRPLANE_DATA_PROMPT"] boolValue];

    if ([_settingsPlist objectForKey:@"CONNECTION_FAILED"])
        CONNECTION_FAILED = [[_settingsPlist objectForKey:@"CONNECTION_FAILED"] boolValue];

    if ([_settingsPlist objectForKey:@"WorksInFullScreen"])
        WorksInFullScreen = [[_settingsPlist objectForKey:@"WorksInFullScreen"] boolValue];

}

static void reloadSettingsNotification(CFNotificationCenterRef notificationCenterRef, void * arg1, CFStringRef arg2, const void * arg3, CFDictionaryRef dictionary)
{
    reloadSettings();
}

static void initializeMailHooks() {

    %init(Mail);

    //  load CONNECTION_FAILED string from its bundle
    NSBundle * messageBundle = [[NSBundle alloc] initWithPath:@"/System/Library/PrivateFrameworks/Message.framework"];

    if (messageBundle) {

        CONNECTION_FAILED_string = [[messageBundle localizedStringForKey:@"CONNECTION_FAILED" value:@"" table:@"Delayed"] retain];

        [messageBundle release];

    } 

}

static void initializeSpringBoardHooks() {

    %init(SpringBoard);

    //  load IMPROVE_LOCATION_ACCURACY_WIFI string from its bundle
    NSBundle * coreLocationBundle = [[NSBundle alloc] initWithPath:@"/System/Library/Frameworks/CoreLocation.framework"];

    if (coreLocationBundle) {

        IMPROVE_LOCATION_ACCURACY_WIFI_string = [[coreLocationBundle localizedStringForKey:@"IMPROVE_LOCATION_ACCURACY_WIFI" value:@"" table:@"locationd"] retain];

        [coreLocationBundle release];

    } 

    //  load YOU_CAN_TURN_ON_CELLULAR_DATA_FOR_THIS_APP_IN_SETTINGS string from its bundle
    NSBundle * carrierBundle = [[NSBundle alloc] initWithPath:@"/var/mobile/Library/CarrierDefault.bundle"];

    if (carrierBundle) {

        CELLULAR_DATA_IS_TURNED_OFF_FOR_APP_NAME_string = [[carrierBundle localizedStringForKey:@"YOU_CAN_TURN_ON_CELLULAR_DATA_FOR_THIS_APP_IN_SETTINGS" value:@"" table:@"DataUsage"] retain];

        [carrierBundle release];

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
}

%ctor {

    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    if ([[[NSBundle mainBundle] bundleIdentifier] caseInsensitiveCompare:@"com.apple.mobilemail"]) {
        //  time to hook mail
        initializeMailHooks();
    } else {
        //  hook springboard
        initializeSpringBoardHooks();
    }

    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)reloadSettingsNotification, CFSTR("com.pNre.noannoyance/settingsupdated"), NULL, CFNotificationSuspensionBehaviorCoalesce);
    reloadSettings();

    [pool release];

}
