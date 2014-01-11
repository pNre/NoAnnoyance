@interface BKSWorkspace : NSObject

- (id)topApplication;

@end

@interface SBWorkspace : NSObject

- (BKSWorkspace *)bksWorkspace;

- (id)_applicationForBundleIdentifier:(id)bundleIdentifier frontmost:(BOOL)frontmost;

@end

