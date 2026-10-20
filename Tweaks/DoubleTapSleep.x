#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// ============================================================================
// DoubleTapSleep.x — AIOTweaks
// Double-tap on empty space on the Home Screen or Lock Screen to sleep/lock
// ============================================================================

@interface SpringBoard : UIApplication
- (void)_simulateLockButtonPress;
@end

@interface SBLockScreenManager : NSObject
+ (instancetype)sharedInstanceIfExists;
- (void)lockUIFromSource:(int)source withOptions:(id)options;
@end

@interface SBIconListView : UIView <UIGestureRecognizerDelegate>
- (void)aiotweaks_handleDoubleTap:(UITapGestureRecognizer *)gesture;
@end

@interface CSCoverSheetView : UIView <UIGestureRecognizerDelegate>
- (void)aiotweaks_handleDoubleTap:(UITapGestureRecognizer *)gesture;
@end

static void AIOTweaksSleepDevice(void) {
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

static BOOL AIOTweaksIsViewInteractiveOnHomeScreen(UIView *hitView, UIView *containerView) {
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
            [clsName containsString:@"Widget"] ||
            [clsName containsString:@"Platter"] ||
            [clsName containsString:@"Button"] ||
            [clsName containsString:@"SearchPill"]) {
            return YES;
        }
        v = v.superview;
    }
    return NO;
}

static BOOL AIOTweaksIsViewInteractiveOnLockScreen(UIView *hitView, UIView *containerView) {
    UIView *v = hitView;
    while (v && v != containerView) {
        if ([v isKindOfClass:[UIControl class]]) return YES;
        NSString *clsName = NSStringFromClass([v class]);
        // Avoid triggering sleep when double-tapping notifications, media player, passcode keypad, or widgets
        if ([clsName containsString:@"Notification"] ||
            [clsName containsString:@"NCNotification"] ||
            [clsName containsString:@"Platter"] ||
            [clsName containsString:@"Passcode"] ||
            [clsName containsString:@"Keypad"] ||
            [clsName containsString:@"MediaControls"] ||
            [clsName containsString:@"MRU"] ||
            [clsName containsString:@"Button"] ||
            [clsName containsString:@"Complication"] ||
            [clsName containsString:@"Widget"]) {
            return YES;
        }
        v = v.superview;
    }
    return NO;
}

static const void *kDoubleTapInstalledKey = &kDoubleTapInstalledKey;

%group SpringBoardDoubleTapSleep

// ----------------------------------------------------------------------------
// 1. Home Screen Empty Space Double-Tap to Sleep (SBIconListView)
// ----------------------------------------------------------------------------
%hook SBIconListView

- (void)didMoveToWindow {
    %orig;
    if (self.window && !objc_getAssociatedObject(self, kDoubleTapInstalledKey)) {
        // Only attach to root Home Screen / Dock icon lists, not inside open folders if undesired
        UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(aiotweaks_handleDoubleTap:)];
        doubleTap.numberOfTapsRequired = 2;
        doubleTap.numberOfTouchesRequired = 1;
        doubleTap.cancelsTouchesInView = NO;
        doubleTap.delaysTouchesBegan = NO;
        doubleTap.delaysTouchesEnded = NO;
        doubleTap.delegate = self;
        [self addGestureRecognizer:doubleTap];
        objc_setAssociatedObject(self, kDoubleTapInstalledKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

%new
- (void)aiotweaks_handleDoubleTap:(UITapGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateEnded) {
        CGPoint pt = [gesture locationInView:self];
        UIView *hit = [self hitTest:pt withEvent:nil];
        if (!AIOTweaksIsViewInteractiveOnHomeScreen(hit, self)) {
            AIOTweaksSleepDevice();
        }
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]] &&
        ((UITapGestureRecognizer *)gestureRecognizer).numberOfTapsRequired == 2 &&
        gestureRecognizer.view == self) {
        if (AIOTweaksIsViewInteractiveOnHomeScreen(touch.view, self)) {
            return NO;
        }
        return YES;
    }
    return %orig;
}

%end

// ----------------------------------------------------------------------------
// 2. Lock Screen Empty Space Double-Tap to Sleep (CSCoverSheetView)
// ----------------------------------------------------------------------------
%hook CSCoverSheetView

- (void)didMoveToWindow {
    %orig;
    if (self.window && !objc_getAssociatedObject(self, kDoubleTapInstalledKey)) {
        UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(aiotweaks_handleDoubleTap:)];
        doubleTap.numberOfTapsRequired = 2;
        doubleTap.numberOfTouchesRequired = 1;
        doubleTap.cancelsTouchesInView = NO;
        doubleTap.delaysTouchesBegan = NO;
        doubleTap.delaysTouchesEnded = NO;
        doubleTap.delegate = self;
        [self addGestureRecognizer:doubleTap];
        objc_setAssociatedObject(self, kDoubleTapInstalledKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

%new
- (void)aiotweaks_handleDoubleTap:(UITapGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateEnded) {
        CGPoint pt = [gesture locationInView:self];
        UIView *hit = [self hitTest:pt withEvent:nil];
        if (!AIOTweaksIsViewInteractiveOnLockScreen(hit, self)) {
            AIOTweaksSleepDevice();
        }
    }
}

%new
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]] &&
        ((UITapGestureRecognizer *)gestureRecognizer).numberOfTapsRequired == 2 &&
        gestureRecognizer.view == self) {
        if (AIOTweaksIsViewInteractiveOnLockScreen(touch.view, self)) {
            return NO;
        }
    }
    return YES;
}

%end

%end // group SpringBoardDoubleTapSleep

%ctor {
    @autoreleasepool {
        NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
        if ([bundleID isEqualToString:@"com.apple.springboard"]) {
            %init(SpringBoardDoubleTapSleep);
        }
    }
}
