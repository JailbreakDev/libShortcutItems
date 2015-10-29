#import <objc/runtime.h>
#import <substrate.h>
#import "libShortcutItems.h"
#import "Classes.h"

typedef NS_ENUM(NSInteger, LSINotifySource) {
    LSINotifySourceLaunch,
    LSINotifySourceReopen,
};

static IMP application = NULL;
static IMP itemsToDisplay = NULL;
static IMP performActionForShortcutItem = NULL;
void (*oldActivateShortcutItem)(id self, SEL _cmd, SBSApplicationShortcutItem *item, SBApplication *app);

@interface LSIApplicationShortcutItem ()
@property (nonatomic,strong) SBSApplicationShortcutItem *item;
@property (nonatomic,strong) SBSApplicationShortcutSystemIcon *icon;
@end

@implementation LSIApplicationShortcutItem
@synthesize item = _item;
@synthesize icon = _icon;
@synthesize type = _type;
@synthesize localizedTitle = _localizedTitle;
@synthesize localizedSubtitle = _localizedSubtitle;
@synthesize userInfo = _userInfo;
@synthesize iconType = _iconType;

+(LSIApplicationShortcutItem *)newShortcutItemType:(NSString *)type title:(NSString *)title subtitle:(NSString *)subtitle iconType:(UIApplicationShortcutIconType)iconType {
	LSIApplicationShortcutItem *lsiItem = [[LSIApplicationShortcutItem alloc] init];
	lsiItem.item = [[SBSApplicationShortcutItem alloc] init];
	[lsiItem setType:type];
	[lsiItem setUserInfo:@{@"isCustomItem":@(TRUE)}];
	[lsiItem setLocalizedTitle:title];
	[lsiItem setLocalizedSubtitle:subtitle];
	lsiItem.icon = [SBSApplicationShortcutSystemIcon alloc];
	lsiItem.icon = [lsiItem.icon initWithType:iconType];
	[lsiItem.item setIcon:lsiItem.icon];
	return lsiItem;
}

-(NSString *)type {
	if (!_type) {
		_type = _item.type;
	}
	return _type;
}

-(void)setType:(NSString *)type {
	_type = type;
	[_item setType:type];
}

-(NSString *)localizedTitle {
	if (!_localizedTitle) {
		_localizedTitle = _item.localizedTitle;
	}
	return _localizedTitle;
}

-(void)setLocalizedTitle:(NSString *)title {
	_localizedTitle = title;
	[_item setLocalizedTitle:_localizedTitle];
}

-(NSString *)localizedSubtitle {
	if (!_localizedSubtitle) {
		_localizedSubtitle = _item.localizedSubtitle;
	}
	return _localizedSubtitle;
}

-(void)setLocalizedSubtitle:(NSString *)subtitle {
	_localizedSubtitle = subtitle;
	[_item setLocalizedSubtitle:_localizedSubtitle];
}

-(NSDictionary *)userInfo {
	if (!_userInfo) {
		_userInfo = _item.userInfo;
	}
	return _userInfo;
}

-(void)setUserInfo:(NSDictionary *)userInfo {
	_userInfo = userInfo;
	[_item setUserInfo:_userInfo];
}

-(UIApplicationShortcutIconType)iconType {
	return _iconType;
}

-(void)setIconType:(UIApplicationShortcutIconType)iconType {
	if (_iconType != iconType) {
		_iconType = iconType;
		_icon = nil;
		_icon = [SBSApplicationShortcutSystemIcon alloc];
		_icon = [_icon initWithType:iconType];
		[_item setIcon:_icon];
	}
}

@end

@interface LSICallback()
@property (nonatomic,strong) NSArray *itemIdentifiers;
@end

@implementation LSICallback
@synthesize callbackBlock = _callbackBlock;
@synthesize handledOnSpringBoard = _handledOnSpringBoard;
@synthesize itemIdentifiers = _itemIdentifiers;

-(instancetype)initWithBlock:(LSICallbackBlock)block handledOnSpringBoard:(BOOL)sb {
	self = [super init];
	if (self) {
		_callbackBlock = block;
		_handledOnSpringBoard = sb;
	}
	return self;
}

+(instancetype)callbackWithBlock:(LSICallbackBlock)block forIdentifiers:(NSArray *)identifiers {
  LSICallback *callback = [[LSICallback alloc] initWithBlock:block handledOnSpringBoard:[LSIManager sharedManager].isRunningInsideSpringBoard];
  if (callback) {
    callback.itemIdentifiers = identifiers;
  }
  return callback;
}

+(instancetype)callbackWithBlock:(LSICallbackBlock)block {
	LSICallback *callback = [[LSICallback alloc] initWithBlock:block handledOnSpringBoard:[LSIManager sharedManager].isRunningInsideSpringBoard];
	return callback;
}

@end

@interface LSIManager ()
@property (nonatomic,strong,readonly) NSMutableDictionary *customDynamicShortcuts;
@property (nonatomic,strong,readonly) NSMutableArray *callbacks;
@property (nonatomic) BOOL hasHandledLaunch;
-(void)notifyCallbacks:(UIApplicationShortcutItem *)uiItem fromSource:(LSINotifySource)source;
@end

@implementation LSIManager
@synthesize customDynamicShortcuts = _customDynamicShortcuts;
@synthesize callbacks = _callbacks;
@synthesize hasHandledLaunch = _hasHandledLaunch;

+(instancetype)sharedManager {
	static dispatch_once_t p = 0;
	static __strong LSIManager *_sharedSelf = nil;
	dispatch_once(&p,^{
		_sharedSelf = [[self alloc] init];
	});
	return _sharedSelf;
}

-(instancetype)init {
	self = [super init];
	if (self) {
		_runningInsideSpringBoard = ([[[NSProcessInfo processInfo] processName] isEqualToString:@"SpringBoard"]);
		[self initApp:_runningInsideSpringBoard];
	}
	return self;
}

#pragma mark - Hooks and Logic

-(void)notifyCallbacks:(UIApplicationShortcutItem *)uiItem fromSource:(LSINotifySource)source {
	if (!uiItem) {
		return;
	}
	//on launch both reopen and launch handlers are called, so if an app is launched and it is handled, reopen once will not be executed
	if (source == LSINotifySourceReopen && _hasHandledLaunch) {
		_hasHandledLaunch = FALSE;
		return;
	}
	if (source == LSINotifySourceLaunch) {
		_hasHandledLaunch = TRUE;
	} else {
		_hasHandledLaunch = FALSE;
	}
	for (LSICallback *callback in _callbacks) {
		if (callback.callbackBlock && !callback.isHandledOnSpringBoard) {
      if (callback.itemIdentifiers && callback.itemIdentifiers.count > 0) {
        if (![callback.itemIdentifiers containsObject:uiItem.type]) {
          continue;
        }
      }
      UIApplicationShortcutIconType type = UIApplicationShortcutIconTypeAdd; //default type. will be changed later with other LSIApplicationShortcutItem types
      if (uiItem.icon.sbsShortcutIcon && [uiItem.icon.sbsShortcutIcon isKindOfClass:objc_getClass("SBSApplicationShortcutSystemIcon")]) {
        type = ((SBSApplicationShortcutSystemIcon *)uiItem.icon.sbsShortcutIcon).type;
      }
      LSIApplicationShortcutItem *item = [LSIApplicationShortcutItem newShortcutItemType:uiItem.type title:uiItem.localizedTitle subtitle:uiItem.localizedSubtitle iconType:type];
      callback.callbackBlock(item);
		}
	}
}

-(void)initApp:(BOOL)sb {
	if (sb) {
		_customDynamicShortcuts = [[NSMutableDictionary alloc] init];

		Class menuClass = objc_getClass("SBApplicationShortcutMenu");
		Method applicationMethod = class_getInstanceMethod(menuClass,@selector(application));
		application = method_getImplementation(applicationMethod);

		MSHookMessageEx(objc_getClass("SBIconController"), @selector(_activateShortcutItem:fromApplication:),(IMP)&activateShortcutItem,(IMP *)&oldActivateShortcutItem);

		Method itemsToDisplayMethod = class_getInstanceMethod(menuClass,@selector(_shortcutItemsToDisplay));
		itemsToDisplay = method_getImplementation(itemsToDisplayMethod);
		Method replacementMethod = class_getInstanceMethod([self class], @selector(_shortcutItemsToDisplay));
		method_exchangeImplementations(itemsToDisplayMethod,replacementMethod);

	} else {

		_callbacks = [[NSMutableArray alloc] init];

		[[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
			if (note.userInfo[UIApplicationLaunchOptionsShortcutItemKey]) {
				[self notifyCallbacks:note.userInfo[UIApplicationLaunchOptionsShortcutItemKey] fromSource:LSINotifySourceLaunch];
			}
			id delegate = [[UIApplication sharedApplication] delegate];
			if (delegate) {
				Class delegateClass = [delegate class];
				Method performActionForShortcutItemMethod = class_getInstanceMethod(delegateClass, @selector(application:performActionForShortcutItem:completionHandler:));
				performActionForShortcutItem = method_getImplementation(performActionForShortcutItemMethod);
				if (performActionForShortcutItem == NULL) {
					class_addMethod(delegateClass,@selector(application:performActionForShortcutItem:completionHandler:),(IMP)lsi_performActionForShortcutItem,"v@:@@@?");
				}
		    Method replacedPerformAction = class_getInstanceMethod([self class], @selector(application:performActionForShortcutItem:completionHandler:));
		    method_exchangeImplementations(performActionForShortcutItemMethod, replacedPerformAction);
			}
		}];
	}
}

-(void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler {
    performActionForShortcutItem(self,@selector(application:performActionForShortcutItem:completionHandler:),application,shortcutItem,completionHandler);
		[[LSIManager sharedManager] notifyCallbacks:shortcutItem fromSource:LSINotifySourceReopen];
}

void lsi_performActionForShortcutItem(id self, SEL _cmd, id app, UIApplicationShortcutItem *item, void(^completionHandler)(BOOL)) {
	[[LSIManager sharedManager] notifyCallbacks:item fromSource:LSINotifySourceReopen];
}

void activateShortcutItem(id self, SEL _cmd, SBSApplicationShortcutItem *item, SBApplication *app) {
	if ([[item.userInfo objectForKey:@"isCustomItem"] boolValue]) {
		NSArray <LSIApplicationShortcutItem *> *itemsForApp = [[LSIManager sharedManager].customDynamicShortcuts objectForKey:[app bundleIdentifier]];
		if (itemsForApp && itemsForApp.count > 0) {
			NSArray <LSIApplicationShortcutItem *> *filteredItems = [itemsForApp filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self.item.type = %@",item.type]];
			BOOL ignoreItem = (filteredItems.count == 0);
			if (!ignoreItem) {
				LSIApplicationShortcutItem *lsiItem = (LSIApplicationShortcutItem *)[filteredItems firstObject];
				if (lsiItem && lsiItem.callback) {
					if (lsiItem.callback.isHandledOnSpringBoard && lsiItem.callback.callbackBlock) {
						lsiItem.callback.callbackBlock(lsiItem);
						return;
					}
				}
			}
		}
	}
	(*oldActivateShortcutItem)(self, _cmd, item, app);
}

-(NSArray <SBSApplicationShortcutItem *>*)_shortcutItemsToDisplay {
	NSArray *originalValue = ((NSArray * (*) (id,SEL))itemsToDisplay)(self,@selector(_shortcutItemsToDisplay));
	SBApplication *app = ((SBApplication * (*) (id,SEL))application)(self,@selector(application));
	if (![[LSIManager sharedManager].customDynamicShortcuts.allKeys containsObject:[app bundleIdentifier]]) {
		return originalValue;
	}
	NSMutableArray *items = [originalValue mutableCopy];
	NSArray *newShortcutItems = [[LSIManager sharedManager].customDynamicShortcuts objectForKey:[app bundleIdentifier]];
	if (newShortcutItems) {
			NSArray *validItems = [newShortcutItems filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self.item != nil"]];
			NSArray *sbsItems = [validItems valueForKey:@"item"];
			if (sbsItems && sbsItems.count > 0) {
				[items addObjectsFromArray:sbsItems];
			}
	}
	return (NSArray *)[items copy];
}

#pragma mark - API

-(void)addShortcutItems:(NSArray <LSIApplicationShortcutItem *> *)items toApplicationID:(NSString *)applicationID {
	if (!_customDynamicShortcuts) {
		_customDynamicShortcuts = [[NSMutableDictionary alloc] init];
	}
	NSMutableArray *existingItems = [_customDynamicShortcuts[applicationID] mutableCopy] ?: [NSMutableArray array];
	[existingItems addObjectsFromArray:items];
	[_customDynamicShortcuts setObject:existingItems forKey:applicationID];
}

-(void)addShortcutItem:(LSIApplicationShortcutItem *)item toApplicationID:(NSString *)applicationID {
	[self addShortcutItems:@[item] toApplicationID:applicationID];
}

-(void)removeShortcutItems:(NSArray <LSIApplicationShortcutItem *> *)items fromApplicationID:(NSString *)applicationID {
  if (!_customDynamicShortcuts) {
    return;
  }
  NSMutableArray *existingItems = [_customDynamicShortcuts[applicationID] mutableCopy] ?: [NSMutableArray array];
  [existingItems removeObjectsInArray:items];
  [_customDynamicShortcuts setObject:existingItems forKey:applicationID];
}

-(void)removeShortcutItem:(LSIApplicationShortcutItem *)item fromApplicationID:(NSString *)applicationID {
  [self removeShortcutItems:@[item] fromApplicationID:applicationID];
}

-(void)addCallback:(LSICallback *)callback {
	if (!_callbacks) {
		_callbacks = [[NSMutableArray alloc] init];
	}
	if (callback) {
		[_callbacks addObject:callback];
	}
}

@end
