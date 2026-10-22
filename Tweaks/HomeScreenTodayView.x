#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "AIOTweaksPrefs.h"

// ============================================================================
// HomeScreenTodayView.x — AIOTweaks
// Disables the Home Screen Today View (leftmost widget page / swipe right)
//
// Older iOS releases expose a single leading custom view; newer releases also
// expose an indexed list of leading custom views. Both are handled below, and
// the SpringBoard home screen overlay (iPad sidebar) is disabled on the
// leading edge too.
// ============================================================================

@interface SBRootFolderView : UIView
- (NSArray *)leadingCustomViewControllers;
- (UIViewController *)leadingCustomViewController;
- (BOOL)isLeadingCustomViewPageHidden;
- (void)setLeadingCustomViewPageHidden:(BOOL)hidden;
- (BOOL)isLeadingCustomViewPageHiddenAtIndex:(NSUInteger)index;
- (void)setLeadingCustomViewPageHidden:(BOOL)hidden atIndex:(NSUInteger)index;
@end

static BOOL AIOTweaksIsTodayViewController(id viewController) {
    if (!viewController) return NO;
    NSString *className = NSStringFromClass([viewController class]);
    return [className isEqualToString:@"SBTodayViewController"] ||
           [className containsString:@"TodayViewController"];
}

// Hides every Today View page exposed by the root folder view.
static void AIOTweaksHideTodayViewPages(SBRootFolderView *folderView) {
    if (!folderView) return;

    if ([folderView respondsToSelector:@selector(leadingCustomViewControllers)]) {
        NSArray *viewControllers = [folderView leadingCustomViewControllers];
        if (![viewControllers isKindOfClass:[NSArray class]]) return;

        [viewControllers enumerateObjectsUsingBlock:^(id viewController, NSUInteger index, BOOL *stop) {
            if (!AIOTweaksIsTodayViewController(viewController)) return;
            if (![folderView respondsToSelector:@selector(setLeadingCustomViewPageHidden:atIndex:)]) return;
            if ([folderView respondsToSelector:@selector(isLeadingCustomViewPageHiddenAtIndex:)] &&
                [folderView isLeadingCustomViewPageHiddenAtIndex:index]) {
                return;
            }
            [folderView setLeadingCustomViewPageHidden:YES atIndex:index];
        }];
        return;
    }

    if (![folderView respondsToSelector:@selector(leadingCustomViewController)] ||
        ![folderView respondsToSelector:@selector(setLeadingCustomViewPageHidden:)]) {
        return;
    }
    if (!AIOTweaksIsTodayViewController([folderView leadingCustomViewController])) return;
    if ([folderView respondsToSelector:@selector(isLeadingCustomViewPageHidden)] &&
        [folderView isLeadingCustomViewPageHidden]) {
        return;
    }
    [folderView setLeadingCustomViewPageHidden:YES];
}

%group SpringBoardHomeScreenTodayView

%hook SBRootFolderController

// Report the Today View page as hidden to every caller (page count, state
// restoration, rotation, and accessibility).
- (BOOL)isTodayViewPageHidden {
    return YES;
}

%end

%hook SBRootFolderView

- (void)didMoveToWindow {
    %orig;
    AIOTweaksHideTodayViewPages(self);
}

- (void)layoutSubviews {
    %orig;
    AIOTweaksHideTodayViewPages(self);
}

%end

%end // group SpringBoardHomeScreenTodayView

%group SpringBoardHomeScreenTodayViewOverlay

// iPad / overlay-based Home Screen Today View sidebar
%hook SBHomeScreenOverlayController

- (double)presentationProgressForTranslation:(double)translation
                  initialPresentationProgress:(double)initialProgress
                                           fromLeading:(BOOL)fromLeading {
    if (fromLeading) return 0.0;
    return %orig;
}

- (double)finalPresentationProgressForTranslation:(double)translation
                                         velocity:(double)velocity
                  initialPresentationProgress:(double)initialProgress
                                      fromLeading:(BOOL)fromLeading {
    if (fromLeading) return 0.0;
    return %orig;
}

%end

%end // group SpringBoardHomeScreenTodayViewOverlay

%ctor {
    @autoreleasepool {
        NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
        if (![bundleID isEqualToString:@"com.apple.springboard"]) return;
        if (!AIOTweaksPrefEnabled(AIOTweaksPrefHomeScreenTodayView)) return;

        Class rootFolderControllerClass = objc_getClass("SBRootFolderController");
        Class rootFolderViewClass = objc_getClass("SBRootFolderView");
        if (rootFolderControllerClass && rootFolderViewClass) {
            %init(SpringBoardHomeScreenTodayView);
        }

        Class overlayControllerClass = objc_getClass("SBHomeScreenOverlayController");
        if (overlayControllerClass &&
            class_getInstanceMethod(overlayControllerClass,
                @selector(presentationProgressForTranslation:initialPresentationProgress:fromLeading:)) &&
            class_getInstanceMethod(overlayControllerClass,
                @selector(finalPresentationProgressForTranslation:velocity:initialPresentationProgress:fromLeading:))) {
            %init(SpringBoardHomeScreenTodayViewOverlay);
        }
    }
}
