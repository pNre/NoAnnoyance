@interface SBAlertItemsController : NSObject

+ (instancetype)sharedInstance;

- (void)activateAlertItem:(id)alertItem animated:(BOOL)animated;
- (void)deactivateAlertItem:(id)alertItem;

@end
