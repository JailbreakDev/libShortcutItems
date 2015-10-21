#import <Foundation/NSObject.h>
#import <objc/runtime.h>

@class SBApplication,SBSApplicationShortcutItem,SBSApplicationShortcutIcon;
@class LSIManager;

@interface LSIManager : NSObject
@property (nonatomic,readonly,getter=isRunningInsideSpringBoard) BOOL runningInsideSpringBoard;
@property (nonatomic,copy) void(^shortcutHandlerBlock)(UIApplicationShortcutItem *item);
+(instancetype)sharedManager;
-(SBSApplicationShortcutItem *)newShortcutItemType:(NSString *)type title:(NSString *)title subtitle:(NSString *)subtitle icon:(SBSApplicationShortcutIcon *)icon;
-(SBSApplicationShortcutItem *)newShortcutItemType:(NSString *)type title:(NSString *)title subtitle:(NSString *)subtitle iconType:(UIApplicationShortcutIconType)iconType;
-(SBSApplicationShortcutItem *)itemForType:(NSString *)type forApplication:(SBApplication *)app;
-(SBSApplicationShortcutItem *)itemForType:(NSString *)type forApplicationID:(NSString *)applicationID;
-(BOOL)updateShortcutItem:(SBSApplicationShortcutItem *)item forType:(NSString *)type forApplication:(SBApplication *)app;
-(BOOL)updateShortcutItem:(SBSApplicationShortcutItem *)item forType:(NSString *)type forApplicationID:(NSString *)appID;
-(void)addShortcutItems:(NSArray <SBSApplicationShortcutItem *> *)items toApplication:(SBApplication *)application;
-(void)addShortcutItems:(NSArray <SBSApplicationShortcutItem *> *)items toApplicationID:(NSString *)applicationID;
@end

@interface SBSApplicationShortcutIcon : NSObject
@end

@interface SBSApplicationShortcutSystemIcon : SBSApplicationShortcutIcon
-(instancetype)initWithType:(NSInteger)type;
@end

@interface SBSApplicationShortcutContactIcon : SBSApplicationShortcutIcon
-(instancetype)initWithContactIdentifier:(NSString *)contactIdentifier;
-(instancetype)initWithFirstName:(NSString *)firstName lastName:(NSString *)lastName;
-(instancetype)initWithFirstName:(NSString *)firstName lastName:(NSString *)lastName imageData:(NSData *)imageData;
@end

@interface SBSApplicationShortcutCustomImageIcon : SBSApplicationShortcutIcon
-(instancetype)initWithImagePNGData:(NSData *)imageData;
@end

@interface SBSApplicationShortcutItem : NSObject
@property (nonatomic,copy) NSString *type;
@property (nonatomic,copy) NSString *localizedTitle;
@property (nonatomic,copy) NSString *localizedSubtitle;
@property (nonatomic,copy) SBSApplicationShortcutIcon *icon;
@property (nonatomic,copy) NSDictionary *userInfo;
@end