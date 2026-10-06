#import "FacebookAuthBridge.h"
#import <FBSDKLoginKit/FBSDKLoginKit.h>

@implementation FacebookAuthBridge

+ (void)loginWithPermissions:(NSArray<NSString *> *)permissions
              viewController:(UIViewController *)viewController
                    tracking:(NSUInteger)tracking
                       nonce:(NSString *)nonce
                  completion:(void (^)(id result, NSError *error, BOOL cancelled))completion {
    FBSDKLoginConfiguration *config = [[FBSDKLoginConfiguration alloc]
        initWithPermissions:permissions
                   tracking:(FBSDKLoginTracking)tracking
                      nonce:nonce];
    if (!config) {
        completion(nil, [NSError errorWithDomain:@"FacebookAuth" code:0 userInfo:@{NSLocalizedDescriptionKey: @"Invalid login configuration"}], NO);
        return;
    }
    FBSDKLoginManager *loginManager = [[FBSDKLoginManager alloc] init];
    [loginManager logInFromViewController:viewController
                            configuration:config
                               completion:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
        if (error) {
            completion(nil, error, NO);
        } else if (result.isCancelled) {
            completion(nil, nil, YES);
        } else {
            completion(result, nil, NO);
        }
    }];
}

@end
