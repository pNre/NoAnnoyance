#import <substrate.h>
#import <CoreFoundation/CoreFoundation.h>

#import <SpringBoard/SBAlertItem.h>
#import <SpringBoard/SBAlertItemsController.h>
#import <SpringBoard/SBUserNotificationAlert.h>
#import <SpringBoard/SBApplication.h>
#import <SpringBoard/SBWorkspace.h>

#import <MobileGestalt/MobileGestalt.h>

#import <UIKit/UIKit.h>

#import "Logging.h"

#define SETTINGS_FILE @"/var/mobile/Library/Preferences/com.pNre.noannoyance.plist"

//  Global
static BOOL GloballyEnabledInFullScreen = NO;
static BOOL GloballyEnabled = YES;

//  Apps
static NSMutableArray * EnabledApps = nil;
static NSMutableArray * EnabledAppsInFullscreen = nil;

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

static BOOL UPDATED_APP_DOT = NO;

static BOOL SHAKE_TO_UNDO = NO;

static NSString * IMPROVE_LOCATION_ACCURACY_WIFI_string = nil;
static NSString * CELLULAR_DATA_IS_TURNED_OFF_FOR_APP_NAME_string = nil;
static NSString * ACCESSORY_UNRELIABLE_string = nil;

//  Mail
static BOOL CONNECTION_FAILED = YES;

static NSString * CONNECTION_FAILED_string = nil;

//  Siri

static BOOL SIRI_CANCEL_ALERT = NO;
static BOOL SIRI_LISTEN_ALERT = NO;

//  Game Center
static BOOL GC_BANNER = YES;

//  Security
static NSInteger TRUST_THIS_COMPUTER = 0;

static NSString * TRUST_THIS_COMPUTER_string = nil;

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

static void reloadSettings() {

    if (!EnabledApps)
        EnabledApps = [[NSMutableArray alloc] init];

    if (!EnabledAppsInFullscreen)
        EnabledAppsInFullscreen = [[NSMutableArray alloc] init];

    [EnabledApps removeAllObjects];
    [EnabledAppsInFullscreen removeAllObjects];

    NSDictionary * _settingsPlist = [NSDictionary dictionaryWithContentsOfFile:SETTINGS_FILE];

    [_settingsPlist enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL * stop) {

        if (![key hasPrefix:@"EnabledApps-"] && ![key hasPrefix:@"EnabledAppsInFullscreen-"])
            return;

        if ([key hasPrefix:@"EnabledApps-"]) {
            if ([obj boolValue]) {
                [EnabledApps addObject:[[key substringFromIndex:[@"EnabledApps-" length]] lowercaseString]];
            }
        }

        if ([key hasPrefix:@"EnabledAppsInFullscreen-"]) {
            if ([obj boolValue]) {
                [EnabledAppsInFullscreen addObject:[[key substringFromIndex:[@"EnabledAppsInFullscreen-" length]] lowercaseString]];
            }
        }

    }];

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
    
    if ([_settingsPlist objectForKey:@"SIRI_CANCEL_ALERT"])
        SIRI_CANCEL_ALERT = [[_settingsPlist objectForKey:@"SIRI_CANCEL_ALERT"] boolValue];
    
    if ([_settingsPlist objectForKey:@"SIRI_LISTEN_ALERT"])
        SIRI_LISTEN_ALERT = [[_settingsPlist objectForKey:@"SIRI_LISTEN_ALERT"] boolValue];
    
    if ([_settingsPlist objectForKey:@"UPDATED_APP_DOT"])
        UPDATED_APP_DOT = [[_settingsPlist objectForKey:@"UPDATED_APP_DOT"] boolValue];
    
    if ([_settingsPlist objectForKey:@"GC_BANNER"])
        GC_BANNER = [[_settingsPlist objectForKey:@"GC_BANNER"] boolValue];

    if ([_settingsPlist objectForKey:@"TRUST_THIS_COMPUTER"])
        TRUST_THIS_COMPUTER = [[_settingsPlist objectForKey:@"TRUST_THIS_COMPUTER"] integerValue];

    if ([_settingsPlist objectForKey:@"SHAKE_TO_UNDO"])
        SHAKE_TO_UNDO = [[_settingsPlist objectForKey:@"SHAKE_TO_UNDO"] boolValue];

    if ([_settingsPlist objectForKey:@"GloballyEnabledInFullScreen"])
        GloballyEnabledInFullScreen = [[_settingsPlist objectForKey:@"GloballyEnabledInFullScreen"] boolValue];

    if ([_settingsPlist objectForKey:@"GloballyEnabled"])
        GloballyEnabled = [[_settingsPlist objectForKey:@"GloballyEnabled"] boolValue];

}

static void reloadSettingsNotification(CFNotificationCenterRef notificationCenterRef, void * arg1, CFStringRef arg2, const void * arg3, CFDictionaryRef dictionary)
{
    reloadSettings();
}

static BOOL CanHook() {

    NSString * topApplication = [[Workspace bksWorkspace] topApplication];

    if (!topApplication)
        return GloballyEnabled;

    BOOL hook = GloballyEnabled;
    BOOL hookInFS = GloballyEnabledInFullScreen;

    //  Check bundle againts our lists
    if (!hook) {
        hook = [EnabledApps containsObject:[topApplication lowercaseString]];
    }

    SBApplication * runningApp = [Workspace _applicationForBundleIdentifier:topApplication frontmost:YES];

    if (![runningApp statusBarHidden])
        return hook;

    //  Check bundle againts our lists
    if (!hookInFS) {
        hookInFS = [EnabledAppsInFullscreen containsObject:[topApplication lowercaseString]];
    }

    return hookInFS;

}

%group SB

%hook SBApplication

- (BOOL)_isRecentlyUpdated {

    if (!UPDATED_APP_DOT)
        return %orig;

    return NO;
    
}

%end

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

static void SBAlertItemDiscard(SBAlertItemsController * controller, SBAlertItem * alert) {

    if ([alert isKindOfClass:[%c(SBUserNotificationAlert) class]]) {

        if ([[(SBUserNotificationAlert *)alert alertHeader] isEqual:TRUST_THIS_COMPUTER_string]) {

            int response = (TRUST_THIS_COMPUTER == 2);

            [(SBUserNotificationAlert *)alert _setActivated:NO];
            [(SBUserNotificationAlert *)alert _sendResponse:response];

            [[NSNotificationCenter defaultCenter] postNotificationName:@"SBUserNotificationDoneNotification" object:alert];

            [(SBUserNotificationAlert *)alert _cleanup];

        } else {

            [controller deactivateAlertItem:alert];
            [(SBUserNotificationAlert *)alert cancel];
            
        }
    } else {

        [controller deactivateAlertItem:alert];

    }

}

- (void)activateAlertItem:(id)alert {

    if (!CanHook()) {
        %orig;
        return;
    }

    if ([alert isKindOfClass:[%c(SBLowPowerAlertItem) class]] && LOW_BATTERY_ALERT) {

        SBAlertItemDiscard(self, alert);
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

                SBAlertItemDiscard(self, alert);
                return;

            }

        }
    }

    if ([alert isKindOfClass:[%c(SBEdgeActivationAlertItem) class]] && EDGE_ALERT) {

        SBAlertItemDiscard(self, alert);
        return;

    }

    if ([alert isKindOfClass:[%c(SBDiskSpaceAlertItem) class]] && LOW_DISK_SPACE_ALERT) {

        SBAlertItemDiscard(self, alert);
        return;

    }
    
    if ([alert isKindOfClass:[%c(SBUserNotificationAlert) class]])
    {

        if (
            ([[alert alertMessage] isEqual:IMPROVE_LOCATION_ACCURACY_WIFI_string] && IMPROVE_LOCATION_ACCURACY_WIFI) ||
            ([[alert alertMessage] isEqual:CELLULAR_DATA_IS_TURNED_OFF_FOR_APP_NAME_string] && CELLULAR_DATA_IS_TURNED_OFF_FOR_APP_NAME) ||
            ([[alert alertHeader] isEqual:ACCESSORY_UNRELIABLE_string] && ACCESSORY_UNRELIABLE) ||
            ([[alert alertHeader] isEqual:TRUST_THIS_COMPUTER_string] && TRUST_THIS_COMPUTER)) {
            
            SBAlertItemDiscard(self, alert);
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
            return NO;

    }

    return %orig;

}

%end

%end

%group AssistantServices

%hook AVVoiceController

- (BOOL)setAlertSoundFromURL:(NSURL *)url forType:(int)type {

    if ((type == 1 && SIRI_LISTEN_ALERT) ||
        (type > 1 && SIRI_CANCEL_ALERT)
        )
        url = [NSURL URLWithString:@"file:///Library/PreferenceBundles/NoAnnoyancePrefs.bundle/Assets/SiriSilent.caf"];

    return %orig(url, type);

}

/*
//  This method works only for the cancel alert... can't figure out why (yet)
- (BOOL)playAlertSoundForType:(int)type {

    if ((type == 2 || type == 3) && SIRI_CANCEL_ALERT)
        return NO;

    return %orig;

}
*/

%end

%end

%group GameCenter

%hook GKNotificationBannerWindow

- (void)_showBanner:(id)banner showDimmingView:(BOOL)showDimmingView {

    if (!CanHook() || !GC_BANNER) {
        %orig;
        return;
    }

}

%end

%end

static void initializeMailStrings() {

    //  load CONNECTION_FAILED string from its bundle
    NSBundle * messageBundle = [[NSBundle alloc] initWithPath:@"/System/Library/PrivateFrameworks/Message.framework"];

    if (messageBundle) {

        CONNECTION_FAILED_string = [[messageBundle localizedStringForKey:@"CONNECTION_FAILED" value:@"" table:@"Delayed"] retain];

        [messageBundle release];

    } 

}

static void initializeSpringBoardStrings() {

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

    //  TRUST_DIALOG_HEADER
    NSBundle * LockdownLocalizationBundle = [[NSBundle alloc] initWithPath:@"/System/Library/Lockdown/Localization.bundle"];

    if (LockdownLocalizationBundle) {

        TRUST_THIS_COMPUTER_string = [[LockdownLocalizationBundle localizedStringForKey:@"TRUST_DIALOG_HEADER" value:@"" table:@"Pairing"] retain];

        [LockdownLocalizationBundle release];

    }

}

%group All

%hook UIApplication

- (BOOL)applicationSupportsShakeToEdit {

    if (!CanHook() || !SHAKE_TO_UNDO) {
        return %orig;
    }

    return NO;

}

%end

%end

%ctor {

    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    NSString * bundleId = [[NSBundle mainBundle] bundleIdentifier];

    if ([bundleId caseInsensitiveCompare:@"com.apple.mobilemail"] == NSOrderedSame) {
        //  time to hook mail
        %init(Mail);
        initializeMailStrings();
    } else if ([bundleId caseInsensitiveCompare:@"com.apple.springboard"] == NSOrderedSame) {
        //  hook springboard
        %init(SB);
        initializeSpringBoardStrings();
    } else if ([bundleId caseInsensitiveCompare:@"com.apple.AssistantServices"] == NSOrderedSame) {
        //  hook siri
        %init(AssistantServices);
    }

    %init(All);
    %init(GameCenter);

    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)reloadSettingsNotification, CFSTR("com.pNre.noannoyance/settingsupdated"), NULL, CFNotificationSuspensionBehaviorCoalesce);
    reloadSettings();

    [pool release];

}
