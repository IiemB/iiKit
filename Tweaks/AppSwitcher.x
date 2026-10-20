#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <objc/runtime.h>

// ============================================================================
// AppSwitcher.x — AIOTweaks
// Swipe down on any app card in the App Switcher to close all applications
// with haptic feedback.
// ============================================================================

@interface SBAppLayout : NSObject
@end

@interface SBMainSwitcherViewController : UIViewController
+ (instancetype)sharedInstance;
+ (instancetype)sharedInstanceIfExists;
- (NSArray<SBAppLayout *> *)recentAppLayouts;
- (NSArray<SBAppLayout *> *)appLayouts;
- (void)_deleteAppLayout:(SBAppLayout *)layout forReason:(long long)reason;
- (void)_deleteAppLayoutsMatchingPredicate:(NSPredicate *)predicate forReason:(long long)reason;
@end

@interface SBMainSwitcherControllerCoordinator : NSObject
+ (instancetype)sharedInstance;
+ (instancetype)sharedInstanceIfExists;
- (NSArray<SBAppLayout *> *)recentAppLayouts;
- (NSArray<SBAppLayout *> *)appLayouts;
- (void)_deleteAppLayout:(SBAppLayout *)layout forReason:(long long)reason;
- (void)_deleteAppLayoutsMatchingPredicate:(NSPredicate *)predicate forReason:(long long)reason;
@end

@interface SBFluidSwitcherItemContainer : UIView <UIScrollViewDelegate>
@property (nonatomic, retain) SBAppLayout *appLayout;
@property (nonatomic, weak) id delegate;
@end

@interface SBFluidSwitcherViewController : UIViewController
@property (nonatomic, readonly) NSArray<SBAppLayout *> *appLayouts;
- (NSArray<SBAppLayout *> *)recentAppLayouts;
- (id)_itemContainerForAppLayoutIfExists:(SBAppLayout *)appLayout;
- (void)killAppLayoutOfContainer:(id)container withVelocity:(CGFloat)velocity forReason:(long long)reason;
- (void)killContainer:(id)container forReason:(long long)reason;
- (void)_deleteAppLayout:(SBAppLayout *)layout forReason:(long long)reason;
- (void)_quitAppsRepresentedByAppLayout:(SBAppLayout *)layout forReason:(long long)reason;
@end

static inline id safeGetObjIvarAS(id obj, const char *ivarName) {
    if (!obj || !ivarName) return nil;
    Ivar ivar = class_getInstanceVariable([obj class], ivarName);
    if (!ivar) return nil;
    return object_getIvar(obj, ivar);
}

static __weak SBFluidSwitcherViewController *gActiveFluidSwitcherVC = nil;
static NSTimeInterval gLastClearAllTimestamp = 0;

static void AIOTweaksTriggerHapticFeedback(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIImpactFeedbackGenerator *impact = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleHeavy];
        [impact prepare];
        [impact impactOccurred];
        UINotificationFeedbackGenerator *notif = [[UINotificationFeedbackGenerator alloc] init];
        [notif notificationOccurred:UINotificationFeedbackTypeSuccess];
    });
}

static NSArray<SBAppLayout *> *AIOTweaksGetAllAppLayouts(id controller) {
    if (!controller) return nil;
    if ([controller respondsToSelector:@selector(recentAppLayouts)]) {
        NSArray *arr = [controller recentAppLayouts];
        if ([arr isKindOfClass:[NSArray class]] && arr.count > 0) return [arr copy];
    }
    if ([controller respondsToSelector:@selector(appLayouts)]) {
        NSArray *arr = [controller appLayouts];
        if ([arr isKindOfClass:[NSArray class]] && arr.count > 0) return [arr copy];
    }
    return nil;
}

static void AIOTweaksCloseAllApps(SBFluidSwitcherItemContainer *containerView) {
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    if (now - gLastClearAllTimestamp < 0.8) {
        return;
    }
    gLastClearAllTimestamp = now;

    // 1. Haptic feedback
    AIOTweaksTriggerHapticFeedback();

    dispatch_async(dispatch_get_main_queue(), ^{
        // 2. Try SBMainSwitcherViewController (iOS 14/15/16+) & SBMainSwitcherControllerCoordinator (iOS 16+)
        Class mainSwClass = objc_getClass("SBMainSwitcherViewController");
        SBMainSwitcherViewController *mainSwitcher = nil;
        if (mainSwClass) {
            if ([mainSwClass respondsToSelector:@selector(sharedInstanceIfExists)]) {
                mainSwitcher = [mainSwClass sharedInstanceIfExists];
            } else if ([mainSwClass respondsToSelector:@selector(sharedInstance)]) {
                mainSwitcher = [mainSwClass sharedInstance];
            }
        }

        Class coordClass = objc_getClass("SBMainSwitcherControllerCoordinator");
        SBMainSwitcherControllerCoordinator *coord = nil;
        if (coordClass) {
            if ([coordClass respondsToSelector:@selector(sharedInstanceIfExists)]) {
                coord = [coordClass sharedInstanceIfExists];
            } else if ([coordClass respondsToSelector:@selector(sharedInstance)]) {
                coord = [coordClass sharedInstance];
            }
        }

        SBFluidSwitcherViewController *fluidVC = gActiveFluidSwitcherVC;
        if (!fluidVC && mainSwitcher) {
            id vc = safeGetObjIvarAS(mainSwitcher, "_contentViewController");
            if (vc && [vc isKindOfClass:objc_getClass("SBFluidSwitcherViewController")]) {
                fluidVC = vc;
            }
        }

        // Gather all recent app layouts from whichever singleton/controller holds them
        NSArray<SBAppLayout *> *layouts = AIOTweaksGetAllAppLayouts(mainSwitcher);
        if (!layouts.count) layouts = AIOTweaksGetAllAppLayouts(coord);
        if (!layouts.count) layouts = AIOTweaksGetAllAppLayouts(fluidVC);

        if (!layouts.count) return;

        for (SBAppLayout *item in layouts) {
            BOOL handled = NO;

            // Method A: SBMainSwitcherViewController _deleteAppLayout:forReason: (Standard on iOS 14-16)
            if (mainSwitcher && [mainSwitcher respondsToSelector:@selector(_deleteAppLayout:forReason:)]) {
                [mainSwitcher _deleteAppLayout:item forReason:1];
                handled = YES;
            }

            // Method B: SBMainSwitcherControllerCoordinator _deleteAppLayout:forReason: (iOS 16+)
            if (!handled && coord && [coord respondsToSelector:@selector(_deleteAppLayout:forReason:)]) {
                [coord _deleteAppLayout:item forReason:1];
                handled = YES;
            }

            // Method C: SBFluidSwitcherViewController _quitAppsRepresentedByAppLayout:forReason: or _deleteAppLayout:forReason:
            if (fluidVC) {
                if ([fluidVC respondsToSelector:@selector(_deleteAppLayout:forReason:)]) {
                    [fluidVC _deleteAppLayout:item forReason:1];
                    handled = YES;
                } else if ([fluidVC respondsToSelector:@selector(_quitAppsRepresentedByAppLayout:forReason:)]) {
                    [fluidVC _quitAppsRepresentedByAppLayout:item forReason:1];
                    handled = YES;
                }
                if ([fluidVC respondsToSelector:@selector(_itemContainerForAppLayoutIfExists:)]) {
                    id itemContainer = [fluidVC _itemContainerForAppLayoutIfExists:item];
                    if (itemContainer) {
                        if ([fluidVC respondsToSelector:@selector(killAppLayoutOfContainer:withVelocity:forReason:)]) {
                            [fluidVC killAppLayoutOfContainer:itemContainer withVelocity:1.0 forReason:1];
                            handled = YES;
                        } else if ([fluidVC respondsToSelector:@selector(killContainer:forReason:)]) {
                            [fluidVC killContainer:itemContainer forReason:1];
                            handled = YES;
                        }
                    }
                }
            }
        }
    });
}

%group SpringBoardAppSwitcher

%hook SBFluidSwitcherViewController

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    gActiveFluidSwitcherVC = self;
}

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    gActiveFluidSwitcherVC = self;
}

- (void)layoutStateTransitionCoordinator:(id)arg1 transitionDidBeginWithTransitionContext:(id)arg2 {
    gActiveFluidSwitcherVC = self;
    %orig;
}

%end

%hook SBFluidSwitcherItemContainer

// Detect downward pull on any App Switcher card via its vertical scrollView
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView
                     withVelocity:(CGPoint)velocity
              targetContentOffset:(CGPoint *)targetContentOffset {
    CGFloat offsetY = scrollView.contentOffset.y;
    if (offsetY < -55.0 || (offsetY < -25.0 && velocity.y < -1.2)) {
        AIOTweaksCloseAllApps(self);
    }
    %orig;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    %orig;
    if (scrollView.isDragging && scrollView.contentOffset.y < -95.0) {
        AIOTweaksCloseAllApps(self);
    }
}

%end

%end // group SpringBoardAppSwitcher

%ctor {
    @autoreleasepool {
        NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
        if ([bundleID isEqualToString:@"com.apple.springboard"]) {
            %init(SpringBoardAppSwitcher);
        }
    }
}
