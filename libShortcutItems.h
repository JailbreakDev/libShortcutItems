#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class LSIApplicationShortcutItem;

typedef void (^LSICallbackBlock)(LSIApplicationShortcutItem *item);

@interface LSICallback : NSObject
@property (nonatomic,getter=isHandledOnSpringBoard,readonly) BOOL handledOnSpringBoard;
@property (nonatomic,copy) LSICallbackBlock callbackBlock;
+(instancetype)callbackWithBlock:(LSICallbackBlock)block;
@end

@interface LSIApplicationShortcutItem : NSObject
@property (nonatomic,copy) NSString *type;
@property (nonatomic,copy) NSString *localizedTitle;
@property (nonatomic,copy) NSString *localizedSubtitle;
@property (nonatomic,copy) NSDictionary *userInfo;
@property (nonatomic) UIApplicationShortcutIconType iconType;
@property (nonatomic,strong) LSICallback *callback;
+(LSIApplicationShortcutItem *)newShortcutItemType:(NSString *)type title:(NSString *)title subtitle:(NSString *)subtitle iconType:(UIApplicationShortcutIconType)iconType;
@end

@interface LSIManager : NSObject
@property (nonatomic,readonly,getter=isRunningInsideSpringBoard) BOOL runningInsideSpringBoard;
+(instancetype)sharedManager;
-(void)addShortcutItems:(NSArray <LSIApplicationShortcutItem *> *)items toApplicationID:(NSString *)applicationID;
-(void)addShortcutItem:(LSIApplicationShortcutItem *)item toApplicationID:(NSString *)applicationID;
-(void)addCallback:(LSICallback *)callback;
@end
