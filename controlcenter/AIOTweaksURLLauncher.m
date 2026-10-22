#import "AIOTweaksURLLauncher.h"
#import <objc/runtime.h>
#import "../Tweaks/AIOTweaksPrefs.h"

// Fallback deep link used when no URL has been configured yet.
static NSString *const kAIOTweaksPreferencesDeepLink = @"prefs:root=AIOTweaks";

@interface LSApplicationWorkspace : NSObject
+ (instancetype)defaultWorkspace;
- (BOOL)openURL:(NSURL *)url;
- (BOOL)openURL:(NSURL *)url withOptions:(NSDictionary *)options;
@end

// A scheme must start with a letter and contain only RFC 3986 scheme characters,
// so "example.com" and "192.168.1.1:8080" are treated as hosts, not schemes.
static BOOL AIOTweaksHasValidScheme(NSString *candidate) {
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
static NSString *AIOTweaksNormalizedURLString(NSString *rawValue) {
    NSString *trimmed = [rawValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmed.length == 0) return nil;

    NSString *candidate = AIOTweaksHasValidScheme(trimmed)
        ? trimmed
        : [@"https://" stringByAppendingString:trimmed];

    if ([NSURL URLWithString:candidate]) return candidate;
    return [candidate stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
}

// SpringBoard is blocked until this returns, so the launch is handed to the
// asynchronous UIApplication API and only falls back to the synchronous
// LSApplicationWorkspace call from a background queue.
static void AIOTweaksOpenURL(NSURL *url) {
    if (!url) return;

    void (^workspaceFallback)(void) = ^{
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
            Class workspaceClass = objc_getClass("LSApplicationWorkspace");
            if (!workspaceClass) return;
            id workspace = [workspaceClass respondsToSelector:@selector(defaultWorkspace)]
                ? [workspaceClass defaultWorkspace]
                : nil;
            if ([workspace respondsToSelector:@selector(openURL:withOptions:)]) {
                [(LSApplicationWorkspace *)workspace openURL:url withOptions:@{}];
            } else if ([workspace respondsToSelector:@selector(openURL:)]) {
                [(LSApplicationWorkspace *)workspace openURL:url];
            }
        });
    };

    void (^openOnMainThread)(void) = ^{
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success) {
            if (!success) {
                workspaceFallback();
            }
        }];
    };

    if ([NSThread isMainThread]) {
        openOnMainThread();
    } else {
        dispatch_async(dispatch_get_main_queue(), openOnMainThread);
    }
}

@implementation AIOTweaksURLLauncher

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

    // Defer so the tile can finish its tap animation before SpringBoard starts
    // launching the target app.
    dispatch_async(dispatch_get_main_queue(), ^{
        static NSTimeInterval lastOpenTimestamp = 0;
        NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
        if (now - lastOpenTimestamp < 1.0) return;
        lastOpenTimestamp = now;

        NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:AIOTweaksPrefsDomain];
        NSString *normalized = AIOTweaksNormalizedURLString([defaults stringForKey:AIOTweaksPrefURLLauncher]);
        if (!normalized) {
            normalized = kAIOTweaksPreferencesDeepLink;
        }

        AIOTweaksOpenURL([NSURL URLWithString:normalized]);
    });
}

@end
