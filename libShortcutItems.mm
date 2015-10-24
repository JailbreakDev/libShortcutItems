#import "libShortcutItems.h"

static IMP application = NULL;
static IMP itemsToDisplay = NULL;
static IMP performActionForShortcutItem = NULL;
void (*oldActivateShortcutItem)(id self, SEL _cmd,SBSApplicationShortcutItem *item, SBApplication *app);

@interface SBApplication : NSObject
@property (nonatomic,copy) NSArray *dynamicShortcutItems;
-(NSString *)bundleIdentifier;
@end

@interface SBApplicationController : NSObject
+(instancetype)sharedInstance;
-(SBApplication *)applicationWithBundleIdentifier:(NSString *)bundleIdentifier;
@end

@interface LSIManager ()
@property (nonatomic,strong,readonly) NSMutableDictionary *customDynamicShortcuts;
@end

@implementation LSIManager
@synthesize runningInsideSpringBoard = _runningInsideSpringBoard;
@synthesize shortcutHandlerBlock = _shortcutHandlerBlock;
@synthesize customDynamicShortcuts = _customDynamicShortcuts;

-(instancetype)init {
	self = [super init];
	if (self) {
		_runningInsideSpringBoard = (objc_getClass("SBApplication") != nil);
		if (!_runningInsideSpringBoard) {
			[[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
				if (note.userInfo[UIApplicationLaunchOptionsShortcutItemKey]) {
					if (_shortcutHandlerBlock) {
   						_shortcutHandlerBlock(note.userInfo[UIApplicationLaunchOptionsShortcutItemKey]);
   					}	
				}
				[self setupHooks];
			}];
		} else {
			_customDynamicShortcuts = [[NSMutableDictionary alloc] init];

			Class menuClass = objc_getClass("SBApplicationShortcutMenu");
			Method applicationMethod = class_getInstanceMethod(menuClass,@selector(application));
			application = method_getImplementation(applicationMethod);

			MSHookMessageEx(objc_getClass("SBIconController"), @selector(_activateShortcutItem:fromApplication:),(IMP)&activateShortcutItem,(IMP *)&oldActivateShortcutItem);

			Method itemsToDisplayMethod = class_getInstanceMethod(menuClass,@selector(_shortcutItemsToDisplay));
			itemsToDisplay = method_getImplementation(itemsToDisplayMethod);
			Method replacementMethod = class_getInstanceMethod([self class], @selector(_shortcutItemsToDisplay));
			method_exchangeImplementations(itemsToDisplayMethod,replacementMethod);
		}
	}
	return self;
}

void activateShortcutItem(id self, SEL _cmd, SBSApplicationShortcutItem *item, SBApplication *app) {
	if ([item isKindOfClass:objc_getClass("LSISBSApplicationShortcutItem")]) {
		NSArray *itemsForApp = [[LSIManager sharedManager].customDynamicShortcuts objectForKey:[app bundleIdentifier]];
		NSArray *filteredItems = [itemsForApp filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self.type = %@",item.type]];
		BOOL ignoreApp = ![[LSIManager sharedManager].customDynamicShortcuts.allKeys containsObject:[app bundleIdentifier]];
		BOOL ignoreItem = (filteredItems.count == 0);
		if (ignoreApp || ignoreItem) {
			(*oldActivateShortcutItem)(self, _cmd, item, app);
			return;
		}
		if (((LSISBSApplicationShortcutItem *)item).isHandledBySpringBoard) {
			if ([LSIManager sharedManager].SBShortcutHandlerBlock) {
   				[LSIManager sharedManager].SBShortcutHandlerBlock((LSISBSApplicationShortcutItem *)item);
   			}
		} else {
			(*oldActivateShortcutItem)(self, _cmd, item, app);
		}
	} else {
		(*oldActivateShortcutItem)(self, _cmd, item, app);
	}
}

-(NSArray <SBSApplicationShortcutItem *>*)_shortcutItemsToDisplay {
	NSArray *originalValue = ((NSArray * (*) (id,SEL))itemsToDisplay)(self,@selector(_shortcutItemsToDisplay));
	SBApplication *app = ((SBApplication * (*) (id,SEL))application)(self,@selector(application));
	if (![[LSIManager sharedManager].customDynamicShortcuts.allKeys containsObject:[app bundleIdentifier]]) {
		return originalValue;
	}
	NSMutableArray *items = [originalValue mutableCopy];
	NSArray *newShortcutItems = [[LSIManager sharedManager].customDynamicShortcuts objectForKey:[app bundleIdentifier]];
	[items addObjectsFromArray:newShortcutItems];
	return (NSArray *)[items copy];
}

+(instancetype)sharedManager {
	static dispatch_once_t p = 0;
	static __strong LSIManager *_sharedSelf = nil;
	dispatch_once(&p,^{
		_sharedSelf = [[self alloc] init];
	});
	return _sharedSelf;
}

void lsi_performActionForShortcutItem(id self, SEL _cmd, id app, UIApplicationShortcutItem *item, void(^completionHandler)(BOOL)) {
	if ([LSIManager sharedManager].shortcutHandlerBlock) {
   		[LSIManager sharedManager].shortcutHandlerBlock(item);
   	}
}

-(void)setupHooks {
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
}

-(void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler {
    performActionForShortcutItem(self,@selector(application:performActionForShortcutItem:completionHandler:),application,shortcutItem,completionHandler);
    if ([LSIManager sharedManager].shortcutHandlerBlock) {
   		[LSIManager sharedManager].shortcutHandlerBlock(shortcutItem);
   	}
}

-(LSISBSApplicationShortcutItem *)newShortcutItemType:(NSString *)type title:(NSString *)title subtitle:(NSString *)subtitle icon:(SBSApplicationShortcutIcon *)icon {
	LSISBSApplicationShortcutItem *item = [[LSISBSApplicationShortcutItem alloc] init];
	[item setType:type];
	[item setLocalizedTitle:title];
	[item setLocalizedSubtitle:subtitle];
	[item setIcon:icon];
	return item;
}

-(LSISBSApplicationShortcutItem *)newShortcutItemType:(NSString *)type title:(NSString *)title subtitle:(NSString *)subtitle iconType:(UIApplicationShortcutIconType)iconType {
	SBSApplicationShortcutSystemIcon *icon = [SBSApplicationShortcutSystemIcon alloc];
	icon = [icon initWithType:UIApplicationShortcutIconTypeCompose];
	return [self newShortcutItemType:type title:title subtitle:subtitle icon:icon];
}

-(LSISBSApplicationShortcutItem *)itemForType:(NSString *)type forApplication:(SBApplication *)app {
	NSArray *filteredItems = [app.dynamicShortcutItems filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self.type = %@",type]];
	if (filteredItems.count > 0) {
		return [[filteredItems firstObject] copy];
	}
	return nil;
}

-(LSISBSApplicationShortcutItem *)itemForType:(NSString *)type forApplicationID:(NSString *)applicationID {
	SBApplication *app = [[objc_getClass("SBApplicationController") sharedInstance] applicationWithBundleIdentifier:applicationID];
	return [self itemForType:type forApplication:app];
}

-(BOOL)updateShortcutItem:(LSISBSApplicationShortcutItem *)item forType:(NSString *)type forApplication:(SBApplication *)app {
	return [self updateShortcutItem:item forType:type forApplicationID:[app bundleIdentifier]];
}

-(BOOL)updateShortcutItem:(LSISBSApplicationShortcutItem *)item forType:(NSString *)type forApplicationID:(NSString *)appID {
	LSISBSApplicationShortcutItem *currentItem = [self itemForType:type forApplicationID:appID];
	if (currentItem) {
		NSMutableArray *items = [_customDynamicShortcuts[appID] mutableCopy];
		if (items) {
			NSInteger index = [items indexOfObject:currentItem];
			if (index != NSNotFound) {
				[items replaceObjectAtIndex:index withObject:item];
				[_customDynamicShortcuts setObject:items forKey:appID];
			}
		}
	}
	return FALSE;
}

-(void)addShortcutItems:(NSArray <SBSApplicationShortcutItem *> *)items toApplication:(SBApplication *)application {
	[self addShortcutItems:items toApplicationID:[application bundleIdentifier]];
}

-(void)addShortcutItems:(NSArray <SBSApplicationShortcutItem *> *)items toApplicationID:(NSString *)applicationID {
	NSMutableArray *existingItems = [_customDynamicShortcuts[applicationID] mutableCopy] ?: [NSMutableArray array];
	[existingItems addObjectsFromArray:items];
	[_customDynamicShortcuts setObject:existingItems forKey:applicationID];
}

@end

@implementation LSISBSApplicationShortcutItem
@synthesize handledBySpringBoard;

@end