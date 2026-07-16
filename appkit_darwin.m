#import <Cocoa/Cocoa.h>

void app_start(void);

static NSWindow *gControlWindow = nil;
static NSWindow *gOverlayWindow = nil;
static NSPopUpButton *gDisplayPopup = nil;
static NSPopUpButton *gOpacityPopup = nil;
static NSButton *gToggleButton = nil;
static NSButton *gQuitButton = nil;
static NSTextField *gStatusLabel = nil;
static BOOL gVisible = NO;
static NSInteger gOpacityPercent = 60;
static NSInteger gScreenIndex = 0;

@interface AppDelegate : NSObject <NSApplicationDelegate>
- (void)buildUI;
- (void)refreshDisplayMenu;
- (void)refreshControls;
- (void)rebuildOverlay;
- (void)toggleOverlay:(id)sender;
- (void)selectOpacity:(id)sender;
- (void)selectDisplay:(id)sender;
- (void)quitApp:(id)sender;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
	[self buildUI];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
	return NO;
}

- (void)buildUI {
	[NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];

	NSRect frame = NSMakeRect(0, 0, 320, 180);
	gControlWindow = [[NSWindow alloc] initWithContentRect:frame
	                                             styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable
	                                               backing:NSBackingStoreBuffered
	                                                 defer:NO];
	gControlWindow.title = @"sudare";
	gControlWindow.releasedWhenClosed = NO;
	gControlWindow.level = NSScreenSaverWindowLevel + 2;
	gControlWindow.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces |
	                                    NSWindowCollectionBehaviorFullScreenAuxiliary;
	[gControlWindow center];

	NSView *content = gControlWindow.contentView;

	gToggleButton = [[NSButton alloc] initWithFrame:NSMakeRect(24, 124, 200, 32)];
	gToggleButton.bezelStyle = NSBezelStyleRounded;
	gToggleButton.target = self;
	gToggleButton.action = @selector(toggleOverlay:);
	[content addSubview:gToggleButton];

	gQuitButton = [[NSButton alloc] initWithFrame:NSMakeRect(232, 124, 64, 32)];
	gQuitButton.title = @"終了";
	gQuitButton.bezelStyle = NSBezelStyleRounded;
	gQuitButton.target = self;
	gQuitButton.action = @selector(quitApp:);
	[content addSubview:gQuitButton];

	NSTextField *opacityLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(24, 88, 88, 24)];
	opacityLabel.stringValue = @"透明度";
	opacityLabel.editable = NO;
	opacityLabel.bezeled = NO;
	opacityLabel.drawsBackground = NO;
	[content addSubview:opacityLabel];

	gOpacityPopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(112, 84, 184, 28)];
	gOpacityPopup.target = self;
	gOpacityPopup.action = @selector(selectOpacity:);
	for (NSInteger percent = 10; percent <= 100; percent += 10) {
		[gOpacityPopup addItemWithTitle:[NSString stringWithFormat:@"%ld%%", (long)percent]];
		gOpacityPopup.lastItem.tag = percent;
	}
	[content addSubview:gOpacityPopup];

	NSTextField *displayLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(24, 52, 88, 24)];
	displayLabel.stringValue = @"対象モニター";
	displayLabel.editable = NO;
	displayLabel.bezeled = NO;
	displayLabel.drawsBackground = NO;
	[content addSubview:displayLabel];

	gDisplayPopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(112, 48, 184, 28)];
	gDisplayPopup.target = self;
	gDisplayPopup.action = @selector(selectDisplay:);
	[content addSubview:gDisplayPopup];

	gStatusLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(24, 18, 272, 20)];
	gStatusLabel.editable = NO;
	gStatusLabel.bezeled = NO;
	gStatusLabel.drawsBackground = NO;
	gStatusLabel.textColor = [NSColor secondaryLabelColor];
	gStatusLabel.font = [NSFont systemFontOfSize:12.0];
	[content addSubview:gStatusLabel];

	[[NSNotificationCenter defaultCenter] addObserver:self
	                                         selector:@selector(screenParametersChanged:)
	                                             name:NSApplicationDidChangeScreenParametersNotification
	                                           object:nil];

	[self refreshDisplayMenu];
	[self refreshControls];
	[self rebuildOverlay];

	[gControlWindow makeKeyAndOrderFront:nil];
	[NSApp activateIgnoringOtherApps:YES];
}

- (void)screenParametersChanged:(NSNotification *)notification {
	[self refreshDisplayMenu];
	[self refreshControls];
	[self rebuildOverlay];
}

- (NSString *)displayNameForScreen:(NSScreen *)screen index:(NSInteger)index {
	NSString *name = screen.localizedName;
	if (name == nil || name.length == 0) {
		name = [NSString stringWithFormat:@"Display %ld", (long)index + 1];
	}
	return [NSString stringWithFormat:@"%@ (%ld)", name, (long)index + 1];
}

- (void)refreshDisplayMenu {
	[gDisplayPopup removeAllItems];

	NSArray<NSScreen *> *screens = [NSScreen screens];
	if (screens.count == 0) {
		[gDisplayPopup addItemWithTitle:@"利用可能なモニターなし"];
		gDisplayPopup.enabled = NO;
		gScreenIndex = 0;
		return;
	}

	gDisplayPopup.enabled = YES;
	if (gScreenIndex >= (NSInteger)screens.count) {
		gScreenIndex = (NSInteger)screens.count - 1;
	}
	if (gScreenIndex < 0) {
		gScreenIndex = 0;
	}

	for (NSInteger i = 0; i < (NSInteger)screens.count; i++) {
		[gDisplayPopup addItemWithTitle:[self displayNameForScreen:screens[(NSUInteger)i] index:i]];
		gDisplayPopup.lastItem.tag = i;
	}
	[gDisplayPopup selectItemWithTag:gScreenIndex];
}

- (void)refreshControls {
	gToggleButton.title = gVisible ? @"簾を上げる" : @"簾を下ろす";
	[gOpacityPopup selectItemWithTag:gOpacityPercent];
	gStatusLabel.stringValue = gVisible ? @"表示中" : @"非表示";
}

- (void)rebuildOverlay {
	if (gOverlayWindow != nil) {
		[gOverlayWindow orderOut:nil];
		[gOverlayWindow release];
		gOverlayWindow = nil;
	}

	if (!gVisible) {
		return;
	}

	NSArray<NSScreen *> *screens = [NSScreen screens];
	if (screens.count == 0) {
		return;
	}

	if (gScreenIndex >= (NSInteger)screens.count) {
		gScreenIndex = (NSInteger)screens.count - 1;
	}
	if (gScreenIndex < 0) {
		gScreenIndex = 0;
	}

	NSScreen *screen = screens[(NSUInteger)gScreenIndex];
	NSRect frame = screen.frame;
	NSWindow *window = [[NSWindow alloc] initWithContentRect:frame
	                                               styleMask:NSWindowStyleMaskBorderless
	                                                 backing:NSBackingStoreBuffered
	                                                   defer:NO
	                                                  screen:screen];
	window.level = NSScreenSaverWindowLevel + 1;
	window.opaque = NO;
	window.backgroundColor = [NSColor colorWithCalibratedWhite:0.08 alpha:(CGFloat)gOpacityPercent / 100.0];
	window.ignoresMouseEvents = YES;
	window.hasShadow = NO;
	window.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces |
	                           NSWindowCollectionBehaviorStationary |
	                           NSWindowCollectionBehaviorIgnoresCycle |
	                           NSWindowCollectionBehaviorFullScreenAuxiliary;
	[window setFrame:frame display:YES];
	[window orderFrontRegardless];

	gOverlayWindow = window;
}

- (void)toggleOverlay:(id)sender {
	gVisible = !gVisible;
	[self refreshControls];
	[self rebuildOverlay];
	[gControlWindow makeKeyAndOrderFront:nil];
}

- (void)selectOpacity:(id)sender {
	gOpacityPercent = gOpacityPopup.selectedItem.tag;
	[self refreshControls];
	[self rebuildOverlay];
	[gControlWindow makeKeyAndOrderFront:nil];
}

- (void)selectDisplay:(id)sender {
	gScreenIndex = gDisplayPopup.selectedItem.tag;
	[self refreshControls];
	[self rebuildOverlay];
	[gControlWindow makeKeyAndOrderFront:nil];
}

- (void)quitApp:(id)sender {
	if (gOverlayWindow != nil) {
		[gOverlayWindow orderOut:nil];
		[gOverlayWindow release];
		gOverlayWindow = nil;
	}
	[NSApp terminate:nil];
}

@end

void app_start(void) {
	@autoreleasepool {
		[NSApplication sharedApplication];
		AppDelegate *delegate = [[AppDelegate alloc] init];
		[NSApp setDelegate:delegate];
		[NSApp run];
	}
}
