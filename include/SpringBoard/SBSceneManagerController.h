#import <SpringBoard/SBSceneManager.h>

#import <SpringBoard/FBSDisplay.h>

@interface SBSceneManagerController : NSObject
+ (instancetype)sharedInstance;
- (SBSceneManager *)sceneManagerForDisplay:(FBSDisplay *)display;
@end
