@interface SBAlertItem : NSObject

- (void)dismiss;
- (void)dismiss:(NSInteger)reason;

- (void)buttonDismissed;

@end
