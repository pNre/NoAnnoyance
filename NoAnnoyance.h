#import <substrate.h>
#import <Logging.h>

#define settings_FILE @"/var/mobile/Library/Preferences/com.pNre.noannoyance.plist"

struct NoAnnoyanceSettings {
    BOOL GloballyEnabledInFullScreen;
    BOOL GloballyEnabled;

    struct {
        BOOL ImproveLocationAccuracy;
        BOOL CellularDataIsTurnedOffFor;
        BOOL EdgeAlert;
        BOOL AirplaneCellPrompt;
        BOOL AirplaneDataPrompt;
        BOOL LowBatteryAlert;
        BOOL LowDiskSpaceAlert;
        BOOL ShakeToUndo;
        BOOL UpdatedAppDot;
    } SpringBoard;

    struct {
        BOOL ConnectionFailed;
    } Mail;

    struct {
        BOOL Banner;
    } GameCenter;

    struct {
        NSUInteger TrustThisComputer;
        BOOL AccessoryUnreliable;
    } Security;
};

@interface NoAnnoyance : NSObject

@property (nonatomic, readonly) NSMutableDictionary * strings;

@property (nonatomic, readonly) NSMutableArray * EnabledApps;
@property (nonatomic, readonly) NSMutableArray * EnabledAppsInFullscreen;

+ (instancetype)sharedInstance;
+ (BOOL)canHook;

- (void)loadSettings;

- (struct NoAnnoyanceSettings)settings;
@end
