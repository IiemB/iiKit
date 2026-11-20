#import "iiKitURLLauncher.h"
#import <objc/runtime.h>
#import "../Tweaks/iiKitPrefs.h"

// Fallback deep link used when no URL has been configured yet.
static NSString *const kiiKitPreferencesDeepLink = @"prefs:root=iiKit";

@interface LSApplicationWorkspace : NSObject
+ (instancetype)defaultWorkspace;
- (BOOL)openURL:(NSURL *)url;
- (BOOL)openURL:(NSURL *)url withOptions:(NSDictionary *)options;
@end

@interface SBLockScreenManager : NSObject
+ (instancetype)sharedInstanceIfExists;
- (BOOL)isUILocked;
@end

// Provided by ControlCenterUIKit and handed to the module by Control Center.
// Its open service is the sanctioned path for launching an app while the device
// is locked, once the user authenticates.
@interface CCUIContentModuleContext : NSObject
- (void)openURL:(NSURL *)url completionHandler:(void (^)(BOOL success))completionHandler;
- (void)requestAuthenticationWithCompletionHandler:(void (^)(BOOL authenticated))completionHandler;
- (void)dismissControlCenter;
@end

@interface CCUIToggleModule (iiKitContentModuleContext)
- (id)contentModuleContext;
@end

// A scheme must start with a letter and contain only RFC 3986 scheme characters,
// so "example.com" and "192.168.1.1:8080" are treated as hosts, not schemes.
static BOOL iiKitHasValidScheme(NSString *candidate) {
    NSRange colonRange = [candidate rangeOfString:@":"];
    if (colonRange.location == NSNotFound || colonRange.location == 0) return NO;

    NSString *scheme = [candidate substringToIndex:colonRange.location];
    NSCharacterSet *letters = [NSCharacterSet letterCharacterSet];
    NSCharacterSet *alphanumerics = [NSCharacterSet alphanumericCharacterSet];
    for (NSUInteger index = 0; index < scheme.length; index++) {
        unichar character = [scheme characterAtIndex:index];
        if (index == 0) {
            if (![letters characterIsMember:character]) return NO;
        } else if (![alphanumerics characterIsMember:character] &&
                   character != '+' && character != '-' && character != '.') {
            return NO;
        }
    }
    return YES;
}

// Accepts bare hosts ("example.com") as well as full schemes ("prefs:root=WIFI").
static NSString *iiKitNormalizedURLString(NSString *rawValue) {
    NSString *trimmed = [rawValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmed.length == 0) return nil;

    NSString *candidate = iiKitHasValidScheme(trimmed)
        ? trimmed
        : [@"https://" stringByAppendingString:trimmed];

    if ([NSURL URLWithString:candidate]) return candidate;
    return [candidate stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
}

static BOOL iiKitDeviceIsLocked(void) {
    Class managerClass = objc_getClass("SBLockScreenManager");
    if (!managerClass) return NO;

    id manager = [(id)managerClass respondsToSelector:@selector(sharedInstanceIfExists)]
        ? [(id)managerClass sharedInstanceIfExists]
        : nil;
    if ([manager respondsToSelector:@selector(isUILocked)]) {
        return [(SBLockScreenManager *)manager isUILocked];
    }
    return NO;
}

// LSApplicationWorkspace blocks until the target app finishes launching, so it
// is only ever called off the main thread.
static void iiKitOpenURLWithWorkspace(NSURL *url) {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        Class workspaceClass = objc_getClass("LSApplicationWorkspace");
        if (!workspaceClass) return;

        id workspace = [(id)workspaceClass respondsToSelector:@selector(defaultWorkspace)]
            ? [(id)workspaceClass defaultWorkspace]
            : nil;
        if ([workspace respondsToSelector:@selector(openURL:withOptions:)]) {
            [(LSApplicationWorkspace *)workspace openURL:url withOptions:@{}];
        } else if ([workspace respondsToSelector:@selector(openURL:)]) {
            [(LSApplicationWorkspace *)workspace openURL:url];
        }
    });
}

// Asynchronous, never blocks SpringBoard. Used when no module context is available.
static void iiKitOpenURLAsync(NSURL *url) {
    if (!url) return;

    void (^openOnMainThread)(void) = ^{
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success) {
            if (!success) {
                iiKitOpenURLWithWorkspace(url);
            }
        }];
    };

    if ([NSThread isMainThread]) {
        openOnMainThread();
    } else {
        dispatch_async(dispatch_get_main_queue(), openOnMainThread);
    }
}

@implementation iiKitURLLauncher

- (UIImage *)iconGlyph {
    return [UIImage imageNamed:@"icon"
                      inBundle:[NSBundle bundleForClass:[self class]]
  compatibleWithTraitCollection:nil];
}

- (UIColor *)selectedColor {
    return [UIColor colorWithRed:0.455 green:0.180 blue:0.878 alpha:1.0];
}

// This tile performs an action instead of holding state, so it always reports
// "off" and springs back after a tap.
- (BOOL)isSelected {
    return NO;
}

- (void)setSelected:(BOOL)selected {
    if (!selected) return;

    // Defer so the tile can finish its tap animation before the launch starts.
    dispatch_async(dispatch_get_main_queue(), ^{
        static NSTimeInterval lastOpenTimestamp = 0;
        NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
        if (now - lastOpenTimestamp < 1.0) return;
        lastOpenTimestamp = now;

        [self iikOpenConfiguredURL];
    });
}

- (void)iikOpenConfiguredURL {
    id configured = iiKitPrefObject(iiKitPrefURLLauncher);
    NSString *normalized = iiKitNormalizedURLString([configured isKindOfClass:[NSString class]] ? configured : nil);
    NSURL *url = [NSURL URLWithString:normalized ?: kiiKitPreferencesDeepLink];
    if (!url) return;

    id context = [self respondsToSelector:@selector(contentModuleContext)] ? [self contentModuleContext] : nil;
    if (![context respondsToSelector:@selector(openURL:completionHandler:)]) {
        iiKitOpenURLAsync(url);
        return;
    }

    void (^openInControlCenter)(void) = ^{
        [(CCUIContentModuleContext *)context openURL:url completionHandler:^(BOOL success) {
            if (!success) {
                iiKitOpenURLWithWorkspace(url);
            }
        }];
    };

    // Launching an app while locked is refused, so authenticate first and only
    // open once the user has actually unlocked.
    if (iiKitDeviceIsLocked() &&
        [context respondsToSelector:@selector(requestAuthenticationWithCompletionHandler:)]) {
        [(CCUIContentModuleContext *)context requestAuthenticationWithCompletionHandler:^(BOOL authenticated) {
            if (!authenticated) return;
            dispatch_async(dispatch_get_main_queue(), openInControlCenter);
        }];
        return;
    }

    dispatch_async(dispatch_get_main_queue(), openInControlCenter);
}

@end
