#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "iiKitPrefs.h"

// ============================================================================
// DoubleTapSleep.x — iiKit
// Double-tap on empty space on the Home Screen or Lock Screen to sleep/lock
// ============================================================================

@interface SpringBoard : UIApplication
- (void)_simulateLockButtonPress;
- (void)_simulateHomeButtonPress;
@end

@interface SBLockScreenManager : NSObject
+ (instancetype)sharedInstance;
+ (instancetype)sharedInstanceIfExists;
- (void)lockUIFromSource:(int)source withOptions:(id)options;
@end

@interface SBBacklightController : NSObject
+ (instancetype)sharedInstance;
+ (instancetype)sharedInstanceIfExists;
- (void)turnOnScreenFullyWithBacklightSource:(long long)source;
- (void)_startFadeOutAnimationFromLockSource:(int)source;
@end

@interface SBIconListView : UIView
@end

@interface CSCoverSheetView : UIView
@end

@interface CSMainPageView : UIView
@end

static NSTimeInterval gLastSleepTimestamp = 0;

static void iiKitSleepDevice(void) {
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    if (now - gLastSleepTimestamp < 0.5) {
        return; // Debounce duplicate triggers if multiple views catch the same double-tap
    }
    gLastSleepTimestamp = now;

    UIApplication *app = [UIApplication sharedApplication];
    if ([app respondsToSelector:@selector(_simulateLockButtonPress)]) {
        [(SpringBoard *)app _simulateLockButtonPress];
        return;
    }
    Class lsMgrClass = objc_getClass("SBLockScreenManager");
    if (lsMgrClass && [lsMgrClass respondsToSelector:@selector(sharedInstanceIfExists)]) {
        SBLockScreenManager *mgr = [lsMgrClass sharedInstanceIfExists];
        if ([mgr respondsToSelector:@selector(lockUIFromSource:withOptions:)]) {
            [mgr lockUIFromSource:1 withOptions:nil];
        }
    }
}

static BOOL iiKitIsViewInteractiveOnHomeScreen(UIView *hitView, UIView *containerView) {
    Class iconViewClass = objc_getClass("SBIconView");
    Class widgetViewClass = objc_getClass("SBHWidgetContainerView");
    Class folderViewClass = objc_getClass("SBFloatyFolderView");

    UIView *v = hitView;
    while (v && v != containerView) {
        if ([v isKindOfClass:[UIControl class]]) return YES;
        if (iconViewClass && [v isKindOfClass:iconViewClass]) return YES;
        if (widgetViewClass && [v isKindOfClass:widgetViewClass]) return YES;
        if (folderViewClass && [v isKindOfClass:folderViewClass]) return YES;
        NSString *clsName = NSStringFromClass([v class]);
        if ([clsName containsString:@"IconView"] ||
            [clsName containsString:@"SBHWidget"] ||
            [clsName containsString:@"WGWidget"] ||
            [clsName containsString:@"PlatterView"] ||
            [clsName containsString:@"Button"] ||
            [clsName containsString:@"SearchPill"]) {
            return YES;
        }
        v = v.superview;
    }
    return NO;
}

static BOOL iiKitIsViewInteractiveOnLockScreen(UIView *hitView, UIView *containerView) {
    UIView *v = hitView;
    while (v && v != containerView) {
        if ([v isKindOfClass:[UIControl class]]) return YES;
        NSString *clsName = NSStringFromClass([v class]);
        // Only block actual interactive Lock Screen cells/controls (notifications, media player, passcode keypad)
        // Do NOT block full-screen container views like CSComplicationContainerView / CSMainPageView / ScrollViews
        if ([clsName containsString:@"NCNotificationListCell"] ||
            [clsName containsString:@"NCNotificationShortLookView"] ||
            [clsName containsString:@"NCNotificationSeamlessContentView"] ||
            [clsName containsString:@"PLPlatterView"] ||
            [clsName containsString:@"SBUIPasscode"] ||
            [clsName containsString:@"PasscodeLockView"] ||
            [clsName containsString:@"TPNumberPad"] ||
            [clsName containsString:@"CSMediaControls"] ||
            [clsName containsString:@"MRUNowPlaying"] ||
            [clsName containsString:@"MRUArtwork"] ||
            [clsName containsString:@"CSAdjunctItemView"] ||
            [clsName containsString:@"CHUISWidgetHostViewControllerView"]) {
            return YES;
        }
        v = v.superview;
    }
    return NO;
}

// Dedicated gesture delegate so we never collide with existing UIView / CSCoverSheetView delegate methods
@interface iiKitDoubleTapDelegate : NSObject <UIGestureRecognizerDelegate>
@property (nonatomic, assign) BOOL isLockScreen;
+ (instancetype)homeScreenDelegate;
+ (instancetype)lockScreenDelegate;
- (void)handleDoubleTap:(UITapGestureRecognizer *)gesture;
@end

@implementation iiKitDoubleTapDelegate

+ (instancetype)homeScreenDelegate {
    static iiKitDoubleTapDelegate *inst = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        inst = [[iiKitDoubleTapDelegate alloc] init];
        inst.isLockScreen = NO;
    });
    return inst;
}

+ (instancetype)lockScreenDelegate {
    static iiKitDoubleTapDelegate *inst = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        inst = [[iiKitDoubleTapDelegate alloc] init];
        inst.isLockScreen = YES;
    });
    return inst;
}

- (void)handleDoubleTap:(UITapGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateEnded) {
        UIView *view = gesture.view;
        if (!view) return;
        CGPoint pt = [gesture locationInView:view];
        UIView *hit = [view hitTest:pt withEvent:nil];
        BOOL interactive = self.isLockScreen
            ? iiKitIsViewInteractiveOnLockScreen(hit, view)
            : iiKitIsViewInteractiveOnHomeScreen(hit, view);
        if (!interactive) {
            iiKitSleepDevice();
        }
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    UIView *view = gestureRecognizer.view;
    if (!view || !touch.view) return YES;
    BOOL interactive = self.isLockScreen
        ? iiKitIsViewInteractiveOnLockScreen(touch.view, view)
        : iiKitIsViewInteractiveOnHomeScreen(touch.view, view);
    return !interactive;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    // Allow Lock Screen / Home Screen scroll views and system recognizers to coexist without blocking our 2-tap
    return YES;
}

@end

static const void *kDoubleTapInstalledKey = &kDoubleTapInstalledKey;

static void iiKitAttachDoubleTap(UIView *view, BOOL isLockScreen) {
    if (!view || objc_getAssociatedObject(view, kDoubleTapInstalledKey)) return;
    iiKitDoubleTapDelegate *del = isLockScreen
        ? [iiKitDoubleTapDelegate lockScreenDelegate]
        : [iiKitDoubleTapDelegate homeScreenDelegate];
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:del action:@selector(handleDoubleTap:)];
    doubleTap.numberOfTapsRequired = 2;
    doubleTap.numberOfTouchesRequired = 1;
    doubleTap.cancelsTouchesInView = NO;
    doubleTap.delaysTouchesBegan = NO;
    doubleTap.delaysTouchesEnded = NO;
    doubleTap.delegate = del;
    [view addGestureRecognizer:doubleTap];
    objc_setAssociatedObject(view, kDoubleTapInstalledKey, doubleTap, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

%group SpringBoardDoubleTapSleep

// 1. Home Screen Empty Space Double-Tap to Sleep
%hook SBIconListView

- (void)didMoveToWindow {
    %orig;
    if (self.window) {
        iiKitAttachDoubleTap(self, NO);
    }
}

%end

// 2. Lock Screen Empty Space Double-Tap to Sleep (CSCoverSheetView + CSMainPageView)
%hook CSCoverSheetView

- (void)didMoveToWindow {
    %orig;
    if (self.window) {
        iiKitAttachDoubleTap(self, YES);
    }
}

%end

%hook CSMainPageView

- (void)didMoveToWindow {
    %orig;
    if (self.window) {
        iiKitAttachDoubleTap(self, YES);
    }
}

%end

%end // group SpringBoardDoubleTapSleep

%ctor {
    @autoreleasepool {
        NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
        if ([bundleID isEqualToString:@"com.apple.springboard"] &&
            iiKitPrefEnabled(iiKitPrefDoubleTapSleep)) {
            %init(SpringBoardDoubleTapSleep);
        }
    }
}
