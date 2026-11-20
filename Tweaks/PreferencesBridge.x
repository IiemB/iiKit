#import <Foundation/Foundation.h>
#import <signal.h>
#import <unistd.h>

// ============================================================================
// PreferencesBridge.x — iiKit
// Restarts SpringBoard when the Settings page asks for a respring.
// ============================================================================

static void iiKitRespringNotificationCallback(CFNotificationCenterRef center,
                                                  void *observer,
                                                  CFStringRef name,
                                                  const void *object,
                                                  CFDictionaryRef userInfo) {
    kill(getpid(), SIGKILL);
}

%ctor {
    @autoreleasepool {
        NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
        if (![bundleID isEqualToString:@"com.apple.springboard"]) return;

        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                        NULL,
                                        iiKitRespringNotificationCallback,
                                        CFSTR("com.iiemb.iikit/respring"),
                                        NULL,
                                        CFNotificationSuspensionBehaviorDeliverImmediately);
    }
}
