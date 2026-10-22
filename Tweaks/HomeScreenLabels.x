#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// ============================================================================
// HomeScreenLabels.x — AIOTweaks
// 1. Hides all Home Screen and Dock app icon & folder labels
// 2. Removes TestFlight beta orange/yellow dot & update blue dot
// 3. Hides open folder title header text
// ============================================================================

// Safe ivar helper: checks class_getInstanceVariable first so it NEVER throws NSUndefinedKeyException
static inline UIView *safeGetViewIvarHSL(id obj, const char *ivarName) {
    if (!obj || !ivarName) return nil;
    Ivar ivar = class_getInstanceVariable([obj class], ivarName);
    if (!ivar) return nil;
    id val = object_getIvar(obj, ivar);
    return [val isKindOfClass:[UIView class]] ? (UIView *)val : nil;
}

@interface SBIconView : UIView
@property (nonatomic, assign, getter=isLabelHidden) BOOL labelHidden;
@property (nonatomic, readonly) UIView *labelView;
@property (nonatomic, readonly) UIView *labelAccessoryView;
- (void)setLabelHidden:(BOOL)hidden;
- (void)_updateLabelAccessoryView;
- (void)_updateLabel;
@end

@interface SBIconLabelImageParameters : NSObject
@property (nonatomic, readonly, copy) NSString *text;
@end

@interface SBIconLabelImageParametersBuilder : NSObject
- (void)setText:(NSString *)text;
- (void)setHasAccessory:(BOOL)hasAccessory;
@end

@interface SBFolderTitleTextField : UITextField
@end

%group SpringBoardIconLabels

// 1. Hide icon and folder labels on Home Screen & Dock, and remove accessory dots (TestFlight orange/yellow dot, blue update dot, green/cloud accessories)
%hook SBIconView

- (void)setLabelHidden:(BOOL)hidden {
    %orig(YES);
}

- (BOOL)isLabelHidden {
    return YES;
}

- (BOOL)shouldShowLabelAccessoryView {
    return NO;
}

- (BOOL)hasLabelAccessoryView {
    return NO;
}

- (long long)currentLabelAccessoryType {
    return 0;
}

- (void)_updateLabelAccessoryView {
    %orig;
    UIView *accessoryView = safeGetViewIvarHSL(self, "_labelAccessoryView");
    if (accessoryView) {
        accessoryView.hidden = YES;
        accessoryView.alpha = 0.0;
    }
}

- (void)_updateLabel {
    %orig;
    UIView *labelView = safeGetViewIvarHSL(self, "_labelView");
    if (labelView) {
        labelView.hidden = YES;
        labelView.alpha = 0.0;
    }
    UIView *accessoryView = safeGetViewIvarHSL(self, "_labelAccessoryView");
    if (accessoryView) {
        accessoryView.hidden = YES;
        accessoryView.alpha = 0.0;
    }
}

- (void)layoutSubviews {
    %orig;
    UIView *labelView = safeGetViewIvarHSL(self, "_labelView");
    if (labelView) {
        labelView.hidden = YES;
        labelView.alpha = 0.0;
    }
    UIView *accessoryView = safeGetViewIvarHSL(self, "_labelAccessoryView");
    if (accessoryView) {
        accessoryView.hidden = YES;
        accessoryView.alpha = 0.0;
    }
}

%end

// 2. Prevent label text and dot accessories from being built in SBIconLabelImageParametersBuilder
%hook SBIconLabelImageParametersBuilder

- (id)buildParameters {
    [self setText:@""];
    return %orig;
}

- (void)setText:(NSString *)text {
    %orig(@"");
}

- (long long)labelAccessoryType {
    return 0;
}

%end

// 3. Ensure SBIconLabelImageParameters always returns an empty string & no accessory
%hook SBIconLabelImageParameters

- (NSString *)text {
    return @"";
}

%end

// 4. Suppress TestFlight / Beta & Newly Updated dots at the SBIcon / SBApplicationIcon data model level
%hook SBIcon

- (long long)labelAccessoryType {
    return 0;
}

%end

%hook SBApplicationIcon

- (long long)labelAccessoryType {
    return 0;
}

%end

%hook SBApplication

- (BOOL)isBeta {
    return NO;
}

- (BOOL)hasBeenUpdated {
    return NO;
}

- (BOOL)isRecentlyUpdated {
    return NO;
}

%end

// 5. Hide open folder title header text on Home Screen
%hook SBFolderTitleTextField

- (void)layoutSubviews {
    %orig;
    if (!self.isEditing) {
        self.alpha = 0.0;
        self.hidden = YES;
    }
}

- (void)setText:(NSString *)text {
    %orig(@"");
}

%end

%end // group SpringBoardIconLabels

%ctor {
    @autoreleasepool {
        NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
        if ([bundleID isEqualToString:@"com.apple.springboard"]) {
            %init(SpringBoardIconLabels);
        }
    }
}
