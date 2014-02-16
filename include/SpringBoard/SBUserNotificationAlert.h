@interface SBUserNotificationAlert

@property(retain) NSString * alertMessage;
@property(retain) NSString * alertHeader;

- (void)_sendResponse:(int)response;

- (void)_setActivated:(BOOL)arg1;

- (void)cancel;

- (void)_cleanup;

@end
