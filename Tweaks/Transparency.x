#import <UIKit/UIKit.h>

// ============================================================================
// Transparency.x — AIOTweaks
// 1. Transparent Dock background (SBDockView, SBFloatingDockPlatterView)
// 2. Transparent Folders — both Closed Icon Grid & Open Folder Background/Blur
// 3. Transparent Home Bar (Home Grabber) globally across SpringBoard & all Apps
//    while keeping swipe gestures active
// ============================================================================

@interface SBDockView : UIView
- (void)setBackgroundAlpha:(double)alpha;
@end

@interface SBFloatingDockPlatterView : UIView
@end

@interface SBFolderBackgroundView : UIView
@end

@interface SBFolderControllerBackgroundView : UIView
@end

@interface SBFloatyFolderView : UIView
- (void)setBackgroundAlpha:(CGFloat)alpha;
@end

@interface SBFolderIconImageView : UIView
@property (nonatomic, retain) UIView *backgroundView;
@end

@interface _SBIconGridWrapperView : UIView
@end

@interface MTLumaDodgePillView : UIView
@end

@interface SBFHomeGrabberView : UIView
@end

@interface SBHomeGrabberView : UIView
@end

// ============================================================================
// GROUP 1: SpringBoard-Only Hooks (Dock, Open/Closed Folders, SB Home Grabber)
// ============================================================================
%group SpringBoardTransparency

// ----------------------------------------------------------------------------
// 1. Transparent Dock
// ----------------------------------------------------------------------------
%hook SBDockView

- (void)layoutSubviews {
    %orig;
    UIView *bgView = [self valueForKey:@"_backgroundView"];
    if (bgView) {
        bgView.hidden = YES;
        bgView.alpha = 0.0;
    }
    UIView *highlightView = [self valueForKey:@"_highlightView"];
    if (highlightView) {
        highlightView.hidden = YES;
        highlightView.alpha = 0.0;
    }
}

- (void)setBackgroundAlpha:(double)alpha {
    %orig(0.0);
}

- (double)backgroundAlpha {
    return 0.0;
}

%end

%hook SBFloatingDockPlatterView

- (void)layoutSubviews {
    %orig;
    UIView *bgView = [self valueForKey:@"_backgroundView"];
    if (bgView) {
        bgView.hidden = YES;
        bgView.alpha = 0.0;
    }
}

%end

// ----------------------------------------------------------------------------
// 2A. Transparent Open Folder View (Inner Platter + Outer Wallpaper Blur)
// ----------------------------------------------------------------------------
%hook SBFolderBackgroundView

- (void)layoutSubviews {
    %orig;
    self.hidden = YES;
    self.alpha = 0.0;
    for (UIView *subview in self.subviews) {
        subview.hidden = YES;
        subview.alpha = 0.0;
    }
}

%end

%hook SBFloatyFolderView

- (void)setBackgroundAlpha:(CGFloat)alpha {
    %orig(0.0);
}

- (void)_configureScrolling {
    %orig;
    UIView *bgView = [self valueForKey:@"_scrollView"];
    if (bgView) {
        bgView.backgroundColor = [UIColor clearColor];
    }
}

%end

// Remove outer wallpaper blur when opening a folder
%hook SBFolderControllerBackgroundView

- (void)layoutSubviews {
    %orig;
    self.hidden = YES;
    self.alpha = 0.0;
}

- (void)setEffectActive:(BOOL)active {
    %orig(NO);
}

%end

// ----------------------------------------------------------------------------
// 2B. Transparent Closed Folder Icon on Home Screen
// ----------------------------------------------------------------------------
%hook SBFolderIconImageView

- (void)layoutSubviews {
    %orig;
    UIView *bgView = [self valueForKey:@"_backgroundView"];
    if (bgView) {
        bgView.hidden = YES;
        bgView.alpha = 0.0;
    }
    UIView *solidColorView = [self valueForKey:@"_solidColorBackgroundView"];
    if (solidColorView) {
        solidColorView.hidden = YES;
        solidColorView.alpha = 0.0;
    }
}

- (void)setBackgroundView:(UIView *)view {
    %orig(view);
    if (view) {
        view.hidden = YES;
        view.alpha = 0.0;
    }
}

- (UIImage *)_folderIconImageWithGridImage:(UIImage *)gridImage {
    // Ensure closed folder background isn't baked into cached icon image
    UIView *bgView = [self valueForKey:@"_backgroundView"];
    if (bgView) {
        bgView.hidden = YES;
        bgView.alpha = 0.0;
    }
    return %orig;
}

%end

// Also suppress static folder icon background image generation if used during caching/zoom
%hook SBFolderIcon

+ (id)_iconGridImageWithSize:(CGSize)size {
    return %orig;
}

%end

// ----------------------------------------------------------------------------
// 3A. Transparent Home Bar in SpringBoard
// ----------------------------------------------------------------------------
%hook SBFHomeGrabberView

- (void)layoutSubviews {
    %orig;
    self.alpha = 0.0;
    self.hidden = YES;
}

- (void)setHidden:(BOOL)hidden forReason:(id)reason withAnimationSettings:(id)settings {
    %orig(YES, reason, settings);
}

%end

%hook SBHomeGrabberView

- (void)layoutSubviews {
    %orig;
    self.alpha = 0.0;
    self.hidden = YES;
}

- (void)setHidden:(BOOL)hidden forReason:(id)reason withAnimationSettings:(id)settings {
    %orig(YES, reason, settings);
}

%end

%end // group SpringBoardTransparency

// ============================================================================
// GROUP 2: Global Hooks (SpringBoard + All Apps via com.apple.UIKit)
// Hides the Home Bar visual pill (MTLumaDodgePillView) in every app and
// SpringBoard while keeping all swipe-up / app-switching gestures intact.
// ============================================================================
%group GlobalHomeBarTransparency

%hook MTLumaDodgePillView

- (void)layoutSubviews {
    %orig;
    self.alpha = 0.0;
    self.hidden = YES;
}

- (void)didMoveToWindow {
    %orig;
    self.alpha = 0.0;
    self.hidden = YES;
}

- (void)setStyle:(long long)style {
    %orig(0);
    self.alpha = 0.0;
    self.hidden = YES;
}

- (void)setBackgroundLuminance:(long long)luminance {
    %orig(luminance);
    self.alpha = 0.0;
    self.hidden = YES;
}

%end

%end // group GlobalHomeBarTransparency

%ctor {
    // Initialize global Home Bar transparency in SpringBoard and all UIKit apps
    %init(GlobalHomeBarTransparency);

    // Initialize Dock & Folder transparency only inside SpringBoard
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    if ([bundleID isEqualToString:@"com.apple.springboard"]) {
        %init(SpringBoardTransparency);
    }
}
