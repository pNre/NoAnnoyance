#import <NoAnnoyance.h>

#import <CoreFoundation/CoreFoundation.h>

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

static void reloadSettingsNotification(CFNotificationCenterRef notificationCenterRef, void * arg1, CFStringRef arg2, const void * arg3, CFDictionaryRef dictionary)
{
    [[NoAnnoyance sharedInstance] loadSettings];
}

%group Mail

%hook MailErrorHandler

- (BOOL)shouldDisplayError:(NSError *)error forAccount:(id)account mode:(int)mode {

    if (![NoAnnoyance canHook])
        return %orig;

    if ([NoAnnoyance sharedInstance].settings.Mail.ConnectionFailed && account && [account respondsToSelector:@selector(hostname)]) {

        NSString * errorDescription = [error localizedDescription];
        if ([errorDescription isEqualToString:[NSString stringWithFormat:[NoAnnoyance sharedInstance].strings[@"Mail.ConnectionFailed"], [account performSelector:@selector(hostname)]]])
            return NO;

    }

    return %orig;

}

%end

%end

%group GameCenter

%hook GKNotificationBannerWindow

- (void)_showBanner:(id)banner showDimmingView:(BOOL)showDimmingView {

    PNLog(@"%d", [NoAnnoyance sharedInstance].settings.GameCenter.Banner);

    if (![NoAnnoyance canHook] || ![NoAnnoyance sharedInstance].settings.GameCenter.Banner) {
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
        [NoAnnoyance sharedInstance].strings[@"Mail.ConnectionFailed"] = [messageBundle localizedStringForKey:@"CONNECTION_FAILED" value:@"" table:@"Delayed"];
    }

}

%group All

%hook UIApplication

- (BOOL)applicationSupportsShakeToEdit {

    if (![NoAnnoyance canHook] || ![NoAnnoyance sharedInstance].settings.SpringBoard.ShakeToUndo) {
        return %orig;
    }

    return NO;

}

%end

%end

%ctor {

    @autoreleasepool {

        NSString * bundleId = [[NSBundle mainBundle] bundleIdentifier];

        if ([bundleId caseInsensitiveCompare:@"com.apple.mobilemail"] == NSOrderedSame) {
            %init(Mail);
            initializeMailStrings();
        }

        %init(All);
        %init(GameCenter);

        PNLog(@"Running in %@", bundleId);

        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)reloadSettingsNotification, CFSTR("com.pNre.noannoyance/settingsupdated"), NULL, CFNotificationSuspensionBehaviorCoalesce);
        [[NoAnnoyance sharedInstance] loadSettings];

    }

}
