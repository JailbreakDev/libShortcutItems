@interface SBSApplicationShortcutIcon : NSObject
@end

@interface SBSApplicationShortcutSystemIcon : SBSApplicationShortcutIcon
@property(readonly, nonatomic) UIApplicationShortcutIconType type;
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

@interface UIApplicationShortcutIcon (PrivateAPI)
@property (nonatomic, readonly) SBSApplicationShortcutIcon *sbsShortcutIcon;
@end

@interface SBApplication : NSObject
@property (nonatomic,copy) NSArray *dynamicShortcutItems;
-(NSString *)bundleIdentifier;
@end

@interface SBApplicationController : NSObject
+(instancetype)sharedInstance;
-(SBApplication *)applicationWithBundleIdentifier:(NSString *)bundleIdentifier;
@end
