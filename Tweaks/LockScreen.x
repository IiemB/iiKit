#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// ============================================================================
// LockScreen.x — AIOTweaks
// 1. Removes Lock Screen Flashlight and Camera quick action buttons
// 2. Disables Lock Screen Today View (swipe right) and Camera (swipe left)
// ============================================================================

static inline UIView *safeGetViewIvarLS(id obj, const char *ivarName) {
    if (!obj || !ivarName) return nil;
    Ivar ivar = class_getInstanceVariable([obj class], ivarName);
    if (!ivar) return nil;
    id val = object_getIvar(obj, ivar);
    return [val isKindOfClass:[UIView class]] ? (UIView *)val : nil;
}

@interface CSQuickActionsView : UIView
@property (nonatomic, retain) UIView *flashlightButton;
@property (nonatomic, retain) UIView *cameraButton;
@end

@interface SBDashBoardQuickActionsView : UIView
@property (nonatomic, retain) UIView *flashlightButton;
@property (nonatomic, retain) UIView *cameraButton;
@end

@interface CSQuickActionControlView : UIView
@end

%group SpringBoardLockScreen

// ----------------------------------------------------------------------------
// 1. Remove Flashlight & Camera Quick Action Buttons on Lock Screen
// ----------------------------------------------------------------------------

// iOS 13–17+ CoverSheetUI Quick Actions ViewController
%hook CSQuickActionsViewController

+ (BOOL)deviceSupportsButtons {
    return NO;
}

- (BOOL)hasFlashlight {
    return NO;
}

- (BOOL)hasCamera {
    return NO;
}

%end

// Legacy/Wrapper SBDashBoard Quick Actions ViewController
%hook SBDashBoardQuickActionsViewController

+ (BOOL)deviceSupportsButtons {
    return NO;
}

- (BOOL)hasFlashlight {
    return NO;
}

- (BOOL)hasCamera {
    return NO;
}

%end

// Fallback view-level hiding in case CSQuickActionsView is instantiated
%hook CSQuickActionsView

- (void)layoutSubviews {
    %orig;
    self.hidden = YES;
    self.alpha = 0.0;
    self.userInteractionEnabled = NO;

    UIView *flashlight = safeGetViewIvarLS(self, "_flashlightButton");
    if (flashlight) {
        flashlight.hidden = YES;
        flashlight.alpha = 0.0;
    }
    UIView *camera = safeGetViewIvarLS(self, "_cameraButton");
    if (camera) {
        camera.hidden = YES;
        camera.alpha = 0.0;
    }
}

- (void)_layoutQuickActionButtons {
    %orig;
    self.hidden = YES;
    self.alpha = 0.0;
}

%end

// iOS 18+ Customizable Lock Screen Quick Action Controls (PosterBoard / Controls)
%hook CSQuickActionControlView

- (void)layoutSubviews {
    %orig;
    self.hidden = YES;
    self.alpha = 0.0;
    self.userInteractionEnabled = NO;
}

%end

// ----------------------------------------------------------------------------
// 2. Disable Lock Screen Today View (Left Page) & Camera (Right Page) Swipes
// ----------------------------------------------------------------------------

// Main CoverSheet View Controller (iOS 13–17+)
%hook CSCoverSheetViewController

- (BOOL)_isTodayViewEnabled {
    return NO;
}

- (BOOL)isTodayViewEnabled {
    return NO;
}

- (BOOL)_shouldShowTodayView {
    return NO;
}

- (BOOL)_isCameraPageEnabled {
    return NO;
}

- (BOOL)isCameraPageEnabled {
    return NO;
}

- (BOOL)_shouldShowCameraPage {
    return NO;
}

%end

// Policy / Capability Provider for Lock Screen Camera & Today View
%hook SBDashBoardPolicyBasedBehaviorProvider

// Disables Lock Screen Camera swipe
- (BOOL)_canShowCamera {
    return NO;
}

// Disables Lock Screen Today View swipe
- (BOOL)_canShowTodayView {
    return NO;
}

// Filters out Camera and Today View capabilities from CoverSheet restricted capabilities
- (unsigned long long)restrictedCapabilities {
    return %orig | (1ULL << 2) | (1ULL << 6);
}

%end

// Prevent Lock Screen Camera Prewarm on edge touch/swipe so battery isn't used
%hook SBCameraPrewarmManager

- (void)prewarmCameraForIdentifier:(id)arg1 {
    // Do not prewarm camera from Lock Screen swipe
}

- (void)prewarmCameraForIdentifier:(id)arg1 prewarmReason:(id)arg2 {
    // Do not prewarm camera from Lock Screen swipe
}

%end

// Prevent CoverSheet from registering Today View or Camera pages in the horizontal scroll view
%hook SBDashBoardViewController

- (BOOL)_isTodayViewEnabled {
    return NO;
}

- (BOOL)isTodayViewEnabled {
    return NO;
}

- (BOOL)_shouldShowTodayView {
    return NO;
}

- (BOOL)_isCameraPageEnabled {
    return NO;
}

%end

// Ensure Lock Screen Camera & Today View policies report disabled
%hook SBMainDisplayPolicyAggregator

- (BOOL)_allowsCapabilityLockScreenCameraWithExplanation:(id *)arg1 {
    if (arg1) *arg1 = nil;
    return NO;
}

- (BOOL)_allowsCapabilityLockScreenTodayViewWithExplanation:(id *)arg1 {
    if (arg1) *arg1 = nil;
    return NO;
}

%end

%end // group SpringBoardLockScreen

%ctor {
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    if ([bundleID isEqualToString:@"com.apple.springboard"]) {
        %init(SpringBoardLockScreen);
    }
}
