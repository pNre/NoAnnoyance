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

@implementation NoAnnoyance {
    struct NoAnnoyanceSettings _settings;
}

+ (id)sharedInstance
{
    static dispatch_once_t token = 0;
    __strong static id _sharedObject = nil;

    dispatch_once(&token, ^{
        _sharedObject = [[self alloc] init];
    });

    return _sharedObject;
}

- (id)init {
    if ((self = [super init])) {
        _strings = [[NSMutableDictionary alloc] init];

        _settings.GloballyEnabledInFullScreen = NO;
        _settings.GloballyEnabled = YES;

        _settings.SpringBoard.ImproveLocationAccuracy = YES;
        _settings.SpringBoard.CellularDataIsTurnedOffFor = YES;
        _settings.SpringBoard.EdgeAlert = YES;
        _settings.SpringBoard.AirplaneCellPrompt = YES;
        _settings.SpringBoard.AirplaneDataPrompt = YES;
        _settings.SpringBoard.LowBatteryAlert = YES;
        _settings.SpringBoard.LowDiskSpaceAlert = YES;
        _settings.SpringBoard.ShakeToUndo = NO;
        _settings.SpringBoard.UpdatedAppDot = NO;

        _settings.GameCenter.Banner = YES;
        _settings.Mail.ConnectionFailed = YES;

        _settings.Security.TrustThisComputer = 0;
        _settings.Security.AccessoryUnreliable = NO;

        [self loadSettings];
    }

    return self;
}

+ (BOOL)canHook {
    return [[NoAnnoyance sharedInstance] canHook];
}

- (BOOL)canHook {

    SBSceneManager * sceneManager = [[%c(SBSceneManagerController) sharedInstance] sceneManagerForDisplay:[%c(FBDisplayManager) mainDisplay]];
    NSSet * scenes = [sceneManager externalForegroundApplicationScenes];
    FBScene * topScene = [scenes anyObject];
    NSString * topApplication = [[topScene clientProcess] bundleIdentifier];

    if (!topApplication)
        topApplication = [[NSBundle mainBundle] bundleIdentifier];

    if (!topApplication) {
        PNLog(@"canHook: %d", self.settings.GloballyEnabled);
        return self.settings.GloballyEnabled;
    }

    BOOL hook = self.settings.GloballyEnabled;
    BOOL hookInFS = self.settings.GloballyEnabledInFullScreen;

    //  Check bundle againts our lists
    if (!hook) {
        hook = [self.EnabledApps containsObject:[topApplication lowercaseString]];
    }

    SBApplication * runningApp = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:topApplication];

    if (runningApp && ![runningApp statusBarHiddenForCurrentOrientation]) {
        PNLog(@"canHook: %d", hook);
        return hook;
    } else if ([UIApplication sharedApplication] && ![[UIApplication sharedApplication] isStatusBarHidden]) {
        PNLog(@"canHook: %d", hook);
        return hook;
    }

    //  Check bundle againts our lists
    if (!hookInFS) {
        hookInFS = [self.EnabledAppsInFullscreen containsObject:[topApplication lowercaseString]];
    }

    PNLog(@"canHook: %d", hookInFS);

    return hookInFS;

}

- (void)loadSettings {

    if (!_EnabledApps)
        _EnabledApps = [[NSMutableArray alloc] init];

    if (!_EnabledAppsInFullscreen)
        _EnabledAppsInFullscreen = [[NSMutableArray alloc] init];

    [_EnabledApps removeAllObjects];
    [_EnabledAppsInFullscreen removeAllObjects];

    NSDictionary * _settingsPlist = [NSDictionary dictionaryWithContentsOfFile:settings_FILE];

    [_settingsPlist enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL * stop) {

        if (![key hasPrefix:@"EnabledApps-"] && ![key hasPrefix:@"EnabledAppsInFullscreen-"])
            return;

        if ([key hasPrefix:@"EnabledApps-"]) {
            if ([obj boolValue]) {
                [self.EnabledApps addObject:[[key substringFromIndex:[@"EnabledApps-" length]] lowercaseString]];
            }
        }

        if ([key hasPrefix:@"EnabledAppsInFullscreen-"]) {
            if ([obj boolValue]) {
                [self.EnabledAppsInFullscreen addObject:[[key substringFromIndex:[@"EnabledAppsInFullscreen-" length]] lowercaseString]];
            }
        }

    }];

    if ([_settingsPlist objectForKey:@"IMPROVE_LOCATION_ACCURACY_WIFI"])
        _settings.SpringBoard.ImproveLocationAccuracy = [[_settingsPlist objectForKey:@"IMPROVE_LOCATION_ACCURACY_WIFI"] boolValue];

    if ([_settingsPlist objectForKey:@"EDGE_ALERT"])
        _settings.SpringBoard.EdgeAlert = [[_settingsPlist objectForKey:@"EDGE_ALERT"] boolValue];

    if ([_settingsPlist objectForKey:@"AIRPLANE_CELL_PROMPT"])
        _settings.SpringBoard.AirplaneCellPrompt = [[_settingsPlist objectForKey:@"AIRPLANE_CELL_PROMPT"] boolValue];

    if ([_settingsPlist objectForKey:@"CELLULAR_DATA_IS_TURNED_OFF_FOR_APP_NAME"])
        _settings.SpringBoard.CellularDataIsTurnedOffFor = [[_settingsPlist objectForKey:@"CELLULAR_DATA_IS_TURNED_OFF_FOR_APP_NAME"] boolValue];

    if ([_settingsPlist objectForKey:@"LOW_BATTERY_ALERT"])
        _settings.SpringBoard.LowBatteryAlert = [[_settingsPlist objectForKey:@"LOW_BATTERY_ALERT"] boolValue];

    if ([_settingsPlist objectForKey:@"LOW_DISK_SPACE_ALERT"])
        _settings.SpringBoard.LowDiskSpaceAlert = [[_settingsPlist objectForKey:@"LOW_DISK_SPACE_ALERT"] boolValue];

    if ([_settingsPlist objectForKey:@"AIRPLANE_DATA_PROMPT"])
        _settings.SpringBoard.AirplaneDataPrompt = [[_settingsPlist objectForKey:@"AIRPLANE_DATA_PROMPT"] boolValue];

    if ([_settingsPlist objectForKey:@"CONNECTION_FAILED"])
        _settings.Mail.ConnectionFailed = [[_settingsPlist objectForKey:@"CONNECTION_FAILED"] boolValue];

    if ([_settingsPlist objectForKey:@"UPDATED_APP_DOT"])
        _settings.SpringBoard.UpdatedAppDot = [[_settingsPlist objectForKey:@"UPDATED_APP_DOT"] boolValue];

    if ([_settingsPlist objectForKey:@"GC_BANNER"])
        _settings.GameCenter.Banner = [[_settingsPlist objectForKey:@"GC_BANNER"] boolValue];

    if ([_settingsPlist objectForKey:@"TRUST_THIS_COMPUTER"])
        _settings.Security.TrustThisComputer = [[_settingsPlist objectForKey:@"TRUST_THIS_COMPUTER"] integerValue];

    if ([_settingsPlist objectForKey:@"ACCESSORY_UNRELIABLE"])
        _settings.Security.AccessoryUnreliable = [[_settingsPlist objectForKey:@"ACCESSORY_UNRELIABLE"] boolValue];

    if ([_settingsPlist objectForKey:@"SHAKE_TO_UNDO"])
        _settings.SpringBoard.ShakeToUndo = [[_settingsPlist objectForKey:@"SHAKE_TO_UNDO"] boolValue];

    if ([_settingsPlist objectForKey:@"GloballyEnabledInFullScreen"])
        _settings.GloballyEnabledInFullScreen = [[_settingsPlist objectForKey:@"GloballyEnabledInFullScreen"] boolValue];

    if ([_settingsPlist objectForKey:@"GloballyEnabled"])
        _settings.GloballyEnabled = [[_settingsPlist objectForKey:@"GloballyEnabled"] boolValue];
}

- (struct NoAnnoyanceSettings)settings {
    return _settings;
}

@end
