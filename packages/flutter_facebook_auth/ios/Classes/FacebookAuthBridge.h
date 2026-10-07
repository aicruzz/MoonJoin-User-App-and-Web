#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface FacebookAuthBridge : NSObject
+ (void)loginWithPermissions:(NSArray<NSString *> *)permissions
              viewController:(UIViewController *)viewController
                    tracking:(NSUInteger)tracking
                       nonce:(NSString *)nonce
                  completion:(void (^)(id result, NSError *error, BOOL cancelled))completion;
@end
