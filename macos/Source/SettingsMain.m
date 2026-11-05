#import <AppKit/AppKit.h>
int main(int argc, const char *argv[]) { @autoreleasepool {
 [NSApplication sharedApplication];
 NSMenu *menu = [[NSMenu alloc] init]; NSMenuItem *appItem = [[NSMenuItem alloc] init]; [menu addItem:appItem];
 NSMenu *appMenu = [[NSMenu alloc] initWithTitle:@"Plasma Lab Settings"];
 NSMenuItem *quit = [appMenu addItemWithTitle:@"Quit Plasma Lab Settings" action:@selector(terminate:) keyEquivalent:@"q"]; quit.target = NSApp;
 appItem.submenu = appMenu; NSApp.mainMenu = menu;
 NSURL *url = [[NSBundle mainBundle] URLForResource:@"Plasma Lab" withExtension:@"saver"];
 NSError *error = nil;
 NSBundle *bundle = [NSBundle bundleWithURL:url];
 if (!bundle || ![bundle loadAndReturnError:&error]) {
  NSAlert *alert = [[NSAlert alloc] init]; alert.messageText = @"Plasma Lab could not start"; alert.informativeText = error.localizedDescription ?: @"The bundled screen saver is missing."; [alert runModal]; return 1;
 }
 Class launcher = NSClassFromString(@"PlasmaSettingsLauncher");
 if (!launcher || ![launcher respondsToSelector:@selector(run)]) return 2;
 [launcher performSelector:@selector(run)];
 if (argc > 1 && !strcmp(argv[1],"--self-test")) {
  [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
  NSWindow *editor = nil;
  for (NSWindow *w in NSApp.windows) if ([w.title isEqualToString:@"Plasma Lab Settings"]) editor = w;
  if (!editor || !editor.isVisible || !editor.contentViewController) return 3;
  NSUInteger count = 0; BOOL exportButton = NO;
  for (NSView *v in editor.contentView.subviews) {
   if ([v isKindOfClass:[NSSlider class]]) count++;
   if ([v isKindOfClass:[NSButton class]] && [[(NSButton *)v title] isEqualToString:@"Save & Install…"]) exportButton = [(NSButton *)v isEnabled];
  }
  [editor orderOut:nil];
  if (count != 8 || !exportButton) return 4;
  printf("PASS: companion app resource loading, visible native settings window, 8 sliders, and enabled Save & Install button.\n");
  return 0;
 }
 [NSApp run];
 return 0;
} }
