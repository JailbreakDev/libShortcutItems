# libShortcutItems
libShortcutItems allows you to easily add shortcut items to applications on SpringBoard. It is a library for 3D Touch compatible devices.

## Usage ##

You need to import libShortcutItems.h first

```objc
#import <libShortcutItems/libShortcutItems.h>
```

### SpringBord ###
In SpringBoard you register the items you want to add to applications.

```objc
if ([LSIManager sharedManager].isRunningInsideSpringBoard) {
	LSISBSApplicationShortcutItem *item = [[LSIManager sharedManager] newShortcutItemType:@"test_icon" title:@"Test" subtitle:@"Testing libShortcutItems" iconType:UIApplicationShortcutIconTypeAdd];
	[[LSIManager sharedManager] addShortcutItems:@[item] toApplicationID:@"com.apple.Preferences"];
}
```

You can also have a callback that won't open the app and is handled on SpringBoard

```objc
LSIApplicationShortcutItem *testItem = [LSIApplicationShortcutItem newShortcutItemType:@"test_icon" title:@"Test" subtitle:@"Testing libShortcutItems" iconType:UIApplicationShortcutIconTypeAdd];
LSICallback *callback = [LSICallback callbackWithBlock:^(LSIApplicationShortcutItem *item) {
	NSLog(@"Handled %@ on SpringBoard",item.localizedTitle);
	[[LSIManager sharedManager] removeShortcutItemType:@"test2_icon" fromApplicationID:@"com.apple.Preferences"];
}];
[testItem setCallback:callback];
[[LSIManager sharedManager] addShortcutItems:@[testItem,test2Item] toApplicationID:@"com.apple.Preferences"];
```

### In Preferences (example) ###
In the Preferences Process you tell LSIManager that you want to be notified of any item that you added before by adding a callback

```objc
[[LSIManager sharedManager] addCallback:[LSICallback callbackWithBlock:^(LSIApplicationShortcutItem *item) {
	NSLog(@"Handled %@ in Preferences",item.localizedTitle);
}]];
```

### In Preferences (example 2) ###
You can also specify an array of item identifiers to be notified for (preferable your own identifiers)

```objc
[[LSIManager sharedManager] addCallback:[LSICallback callbackWithBlock:^(LSIApplicationShortcutItem *item) {
	NSLog(@"Handled %@ in Preferences",item.localizedTitle);
} forIdentifiers:@[@"test3_icon"]]]; 
//adding forIdentifiers and specifying an array of your identifiers ensures only your items are send to your callback
```

As easy as that :) a few lines of code enables lots of cool features.

## Future ##

- I am planning to add custom views inside the Shortcut Item Menu.

## Example ###

[Example Project on Github](https://github.com/sharedRoutine/test-libShortcutItems/)

![libShortcutItems in action](https://pbs.twimg.com/media/CRZN8iFVEAAZe7Z.jpg)
