#import <UIKit/UIKit.h>

@interface SBAlertItem : NSObject

- (void)dismiss;
- (void)dismiss:(NSInteger)reason;

- (void)buttonDismissed;

- (UIAlertView *)alertSheet;



@end
