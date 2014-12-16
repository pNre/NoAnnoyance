#import <NoAnnoyance.h>

#import <SpringBoard/SBAlertItem.h>
#import <SpringBoard/SBAlertItemsController.h>
#import <SpringBoard/SBUserNotificationAlert.h>
#import <SpringBoard/SBApplication.h>
#import <SpringBoard/SBWorkspace.h>
#import <SpringBoard/SBApplicationController.h>
#import <SpringBoard/SBSceneManager.h>
#import <SpringBoard/SBSceneManagerController.h>

#import <SpringBoard/FBSDisplay.h>
#import <SpringBoard/FBDisplayManager.h>
#import <SpringBoard/FBScene.h>
#import <SpringBoard/FBProcess.h>

#import <MobileGestalt/MobileGestalt.h>

#import <UIKit/UIKit.h>

%group SB

%hook SBApplication

- (BOOL)_isRecentlyUpdated {
    return [NoAnnoyance sharedInstance].settings.SpringBoard.UpdatedAppDot ? NO : %orig;
}

%end

%hook SBAlertItemsController

static inline void SBAlertItemDiscard(SBAlertItemsController * controller, SBAlertItem * alert) {

    if ([alert isKindOfClass:[%c(SBUserNotificationAlert) class]]) {

        if ([[(SBUserNotificationAlert *)alert alertHeader] isEqualToString:[NoAnnoyance sharedInstance].strings[@"Security.TrustThisComputer"]]) {

            int response = ([NoAnnoyance sharedInstance].settings.Security.TrustThisComputer == 2);

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

- (void)activateAlertItem:(SBAlertItem *)alert {

    //  Can I catch this alert?
    if (![NoAnnoyance canHook] || [alert isKindOfClass:%c(SBNoAnnoyanceAlertItem)]) {
        %orig;
        return;
    }

    if ([alert isKindOfClass:[%c(SBLowPowerAlertItem) class]] && [NoAnnoyance sharedInstance].settings.SpringBoard.LowBatteryAlert) {
        SBAlertItemDiscard(self, alert);
        return;
    }

    if ([alert isKindOfClass:[%c(SBLaunchAlertItem) class]]) {

        int _type = MSHookIvar<int>(alert, "_type");
        char _isDataAlert = MSHookIvar<char>(alert, "_isDataAlert");
        char _usesCellNetwork = MSHookIvar<char>(alert, "_usesCellNetwork");

        PNLog(@"SBLaunchAlertItem %d, %d, %d", _type, _isDataAlert, _usesCellNetwork);

        if (_type == 1) {

            BOOL cellPrompt = (_isDataAlert != 0 && _usesCellNetwork != 0) && [NoAnnoyance sharedInstance].settings.SpringBoard.AirplaneCellPrompt;
            BOOL dataPrompt = (_isDataAlert != 0 && _usesCellNetwork != 1) && [NoAnnoyance sharedInstance].settings.SpringBoard.AirplaneDataPrompt;

            if (cellPrompt || dataPrompt) {

                SBAlertItemDiscard(self, alert);
                return;

            }

        }
    }

    if ([alert isKindOfClass:[%c(SBEdgeActivationAlertItem) class]] && [NoAnnoyance sharedInstance].settings.SpringBoard.EdgeAlert) {

        SBAlertItemDiscard(self, alert);
        return;

    }

    if ([alert isKindOfClass:[%c(SBDiskSpaceAlertItem) class]] && [NoAnnoyance sharedInstance].settings.SpringBoard.LowDiskSpaceAlert) {

        SBAlertItemDiscard(self, alert);
        return;

    }

    if ([alert isKindOfClass:[%c(SBUserNotificationAlert) class]])
    {
        PNLog(@"SBUserNotificationAlert %@, %@", [(SBUserNotificationAlert *)alert alertMessage], [(SBUserNotificationAlert *)alert alertHeader]);
        PNLog(@"%@", [NoAnnoyance sharedInstance].strings);

        if (
            ([[(SBUserNotificationAlert *)alert alertMessage] isEqualToString:[NoAnnoyance sharedInstance].strings[@"SpringBoard.ImproveLocationAccuracy"]] && [NoAnnoyance sharedInstance].settings.SpringBoard.ImproveLocationAccuracy) ||
            ([[(SBUserNotificationAlert *)alert alertMessage] isEqualToString:[NoAnnoyance sharedInstance].strings[@"SpringBoard.CellularDataIsTurnedOffFor"]] && [NoAnnoyance sharedInstance].settings.SpringBoard.CellularDataIsTurnedOffFor) ||
            ([[(SBUserNotificationAlert *)alert alertHeader] isEqualToString:[NoAnnoyance sharedInstance].strings[@"Security.TrustThisComputer"]] && [NoAnnoyance sharedInstance].settings.Security.TrustThisComputer) ||
            ([[(SBUserNotificationAlert *)alert alertHeader] isEqualToString:[NoAnnoyance sharedInstance].strings[@"Security.AccessoryUnreliable"]] && [NoAnnoyance sharedInstance].settings.Security.AccessoryUnreliable)) {

            SBAlertItemDiscard(self, alert);
            return;
        }

    }

    %orig;

}

%end

%end

static void initializeSpringBoardStrings() {

    //  load IMPROVE_LOCATION_ACCURACY_WIFI string from its bundle
    NSBundle * coreLocationBundle = [[NSBundle alloc] initWithPath:@"/System/Library/Frameworks/CoreLocation.framework"];

    if (coreLocationBundle) {
        [NoAnnoyance sharedInstance].strings[@"SpringBoard.ImproveLocationAccuracy"] = [coreLocationBundle localizedStringForKey:@"IMPROVE_LOCATION_ACCURACY_WIFI" value:@"" table:@"locationd"];
    }

    //  load YOU_CAN_TURN_ON_CELLULAR_DATA_FOR_THIS_APP_IN_settings string from its bundle
    NSError * error = nil;
    NSArray * directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/System/Library/Carrier Bundles" error:&error];
    NSBundle * carrierBundle = nil;

    if (!error) {
        for (NSString * file in directoryContents) {
            NSString * path = [@"/System/Library/Carrier Bundles" stringByAppendingPathComponent:file];
            BOOL isDirectory = NO;

            if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory) {
                carrierBundle = [[NSBundle alloc] initWithPath:[NSString stringWithFormat:@"%@/Default.bundle", path]];
                break;
            }
        }

        if (carrierBundle) {
            [NoAnnoyance sharedInstance].strings[@"SpringBoard.CellularDataIsTurnedOffFor"] = [carrierBundle localizedStringForKey:@"YOU_CAN_TURN_ON_CELLULAR_DATA_FOR_THIS_APP_IN_SETTINGS" value:@"" table:@"DataUsage"];
        }
    }

    //  load ACCESSORY_UNRELIABLE string from its bundle
    NSBundle * IAPBundle = [NSBundle bundleWithIdentifier:@"com.apple.IAP"];

    if (IAPBundle) {
        NSString * sDeviceClass = (__bridge NSString *)MGCopyAnswer(kMGDeviceClass);
        NSMutableString * keyName = [NSMutableString stringWithString:@"ACCESSORY_UNRELIABLE"];

        if ([sDeviceClass isEqualToString:@"iPhone"])
            [keyName appendString:@"_IPHONE"];
        else if ([sDeviceClass isEqualToString:@"iPad"])
            [keyName appendString:@"_IPAD"];
        else
            [keyName appendString:@"_IPOD"];

        [NoAnnoyance sharedInstance].strings[@"Security.AccessoryUnreliable"] = [IAPBundle localizedStringForKey:keyName value:@"" table:@"Framework"];

        PNLog(@"%@, %@, %@", IAPBundle, keyName, [NoAnnoyance sharedInstance].strings[@"Security.AccessoryUnreliable"]);
    }

    //  TRUST_DIALOG_HEADER
    NSBundle * LockdownLocalizationBundle = [[NSBundle alloc] initWithPath:@"/System/Library/Lockdown/Localization.bundle"];

    if (LockdownLocalizationBundle) {
        [NoAnnoyance sharedInstance].strings[@"Security.TrustThisComputer"] = [LockdownLocalizationBundle localizedStringForKey:@"TRUST_DIALOG_HEADER" value:@"" table:@"Pairing"];

    }

}

%ctor {

    @autoreleasepool {

        NSString * bundleId = [[NSBundle mainBundle] bundleIdentifier];

        if ([bundleId caseInsensitiveCompare:@"com.apple.springboard"] == NSOrderedSame) {
            //  hook springboard
            %init(SB);
            initializeSpringBoardStrings();
        }

    }

}
