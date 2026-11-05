#import <AppKit/AppKit.h>
#import <ScreenSaver/ScreenSaver.h>
@interface NSObject (PlasmaExport)
+ (BOOL)exportSaverTo:(NSURL *)url configuration:(NSData *)data error:(NSError **)error;
@end
static NSSlider *slider(NSWindow *sheet, NSString *key) {
 for (NSView *v in sheet.contentView.subviews) if ([v isKindOfClass:[NSSlider class]] && [v.identifier isEqualToString:key]) return (NSSlider *)v;
 return nil;
}
static NSData *pixels(NSImageView *preview) {
 NSBitmapImageRep *bitmap = nil;
 for (NSImageRep *rep in preview.image.representations) if ([rep isKindOfClass:[NSBitmapImageRep class]]) bitmap = (NSBitmapImageRep *)rep;
 return bitmap ? [NSData dataWithBytes:bitmap.bitmapData length:bitmap.bytesPerRow*bitmap.pixelsHigh] : nil;
}
static void tick(NSString *mode, NSTimeInterval seconds) {
 NSDate *end = [NSDate dateWithTimeIntervalSinceNow:seconds];
 while (end.timeIntervalSinceNow > 0) [[NSRunLoop mainRunLoop] runMode:mode beforeDate:end];
}
static void button(NSWindow *sheet, NSString *title) {
 for (NSView *v in sheet.contentView.subviews) if ([v isKindOfClass:[NSButton class]] && [[(NSButton *)v title] isEqualToString:title]) { [(NSButton *)v performClick:nil]; return; }
}
int main(int argc, const char *argv[]) { @autoreleasepool {
 if (argc < 3) return 64;
 NSString *testID = NSUUID.UUID.UUIDString;
 setenv("PLASMA_LAB_TEST_ID",testID.UTF8String,1);
 [NSApplication sharedApplication];
 NSBundle *b = [NSBundle bundleWithPath:[NSString stringWithUTF8String:argv[1]]];
 NSError *error = nil;
 if (![b loadAndReturnError:&error]) { NSLog(@"Load failed: %@",error); return 1; }
 Class cls = b.principalClass;
 if (!cls || ![cls isSubclassOfClass:[ScreenSaverView class]]) return 2;
 ScreenSaverView *view = [[cls alloc] initWithFrame:NSMakeRect(0,0,640,400) isPreview:YES];
 [view startAnimation]; [view animateOneFrame];
 NSBitmapImageRep *rep = [view bitmapImageRepForCachingDisplayInRect:view.bounds];
 [view cacheDisplayInRect:view.bounds toBitmapImageRep:rep];
 [[rep representationUsingType:NSBitmapImageFileTypePNG properties:@{}] writeToFile:[NSString stringWithUTF8String:argv[2]] atomically:YES];
 NSWindow *sheet = view.configureSheet;
 if (!view.hasConfigureSheet || !sheet || !sheet.contentViewController || sheet.contentView.subviews.count < 20) return 3;
 double expectedWidth = argc > 3 && !strcmp(argv[3],"--exported") ? 31 : 25;
 NSDictionary *expected = @{@"width":@(expectedWidth),@"height":@25,@"density":@100,@"gap":@0,@"speed":@50,@"scale":@75,@"complexity":@50,@"cycle":@35};
 for (NSString *key in expected) if (slider(sheet,key).doubleValue != [expected[key] doubleValue]) { NSLog(@"Default mismatch: %@",key); return 5; }
 for (NSView *v in sheet.contentView.subviews) if ([v isKindOfClass:[NSButton class]] && [[(NSButton *)v title] isEqualToString:@"CRT scanlines and vignette"] && [(NSButton *)v state] != NSControlStateValueOff) return 6;
 // Check the actual displayed preview pixels, not just control values or renderer state.
 NSImageView *live = nil;
 for (NSView *v in sheet.contentView.subviews) if ([v isKindOfClass:[NSImageView class]]) live = (NSImageView *)v;
 if (!live || !pixels(live).length) return 20;
 NSData *original = pixels(live);
 for (NSString *key in @[@"width",@"height",@"density",@"gap",@"scale",@"complexity"]) {
  NSSlider *s = slider(sheet,key); double old = s.doubleValue;
  s.doubleValue = s.maxValue; [s sendAction:s.action to:s.target];
  if ([original isEqualToData:pixels(live)]) { NSLog(@"Preview did not change for %@",key); return 21; }
  s.doubleValue = old; [s sendAction:s.action to:s.target];
  if (![original isEqualToData:pixels(live)]) return 22;
 }
 for (NSView *v in sheet.contentView.subviews) {
  if ([v isKindOfClass:[NSPopUpButton class]] && [[(NSPopUpButton *)v itemTitles] containsObject:@"Molten sunset"]) {
   NSPopUpButton *p = (NSPopUpButton *)v;
   [p selectItemAtIndex:1]; [p sendAction:p.action to:p.target];
   if ([original isEqualToData:pixels(live)]) return 23;
   [p selectItemAtIndex:0]; [p sendAction:p.action to:p.target];
  }
  if ([v isKindOfClass:[NSButton class]] && [[(NSButton *)v title] isEqualToString:@"CRT scanlines and vignette"]) {
   NSButton *b = (NSButton *)v; b.state = NSControlStateValueOn; [b sendAction:b.action to:b.target];
   if ([original isEqualToData:pixels(live)]) return 24;
   b.state = NSControlStateValueOff; [b sendAction:b.action to:b.target];
  }
 }
 NSDate *dragEnd = [NSDate dateWithTimeIntervalSinceNow:0.15];
 while (dragEnd.timeIntervalSinceNow > 0) {
  NSSlider *drag = slider(sheet,@"width"); [drag sendAction:drag.action to:drag.target];
  tick(NSEventTrackingRunLoopMode,0.005);
 }
 if ([original isEqualToData:pixels(live)]) { NSLog(@"Repeated slider events starved preview animation"); return 29; }
 tick(NSEventTrackingRunLoopMode,0.15);
 NSData *animated = pixels(live);
 if ([original isEqualToData:animated]) { NSLog(@"Preview did not animate in slider tracking mode"); return 25; }
 NSSlider *drift = slider(sheet,@"cycle"); drift.doubleValue = 100; [drift sendAction:drift.action to:drift.target];
 if ([animated isEqualToData:pixels(live)]) return 26;
 NSSlider *speed = slider(sheet,@"speed"); speed.doubleValue = 0; [speed sendAction:speed.action to:speed.target];
 NSData *frozen = pixels(live); tick(NSDefaultRunLoopMode,0.12);
 if (![frozen isEqualToData:pixels(live)]) return 27;
 speed.doubleValue = 50; [speed sendAction:speed.action to:speed.target];
 tick(NSDefaultRunLoopMode,0.12);
 if ([frozen isEqualToData:pixels(live)]) return 28;
 NSUInteger sliders = 0;
 for (NSView *v in sheet.contentView.subviews) {
  if ([v isKindOfClass:[NSSlider class]]) { NSSlider *s = (NSSlider *)v; s.doubleValue = s.maxValue; [s sendAction:s.action to:s.target]; sliders++; }
  if ([v isKindOfClass:[NSPopUpButton class]]) { NSPopUpButton *p = (NSPopUpButton *)v; for (NSInteger i=0;i<p.numberOfItems;i++) { [p selectItemAtIndex:i]; [p sendAction:p.action to:p.target]; } }
 }
 if (sliders != 8) return 4;
 button(sheet,@"Cancel");
 sheet = view.configureSheet;
 if (slider(sheet,@"width").doubleValue != expectedWidth) return 7;
 // Test a real AppKit sheet session, independently of Apple's System Settings host.
 NSWindow *parent = [[NSWindow alloc] initWithContentRect:NSMakeRect(0,0,900,700) styleMask:NSWindowStyleMaskTitled backing:NSBackingStoreBuffered defer:NO];
 [parent beginSheet:sheet completionHandler:nil];
 if (sheet.sheetParent != parent) return 8;
 button(sheet,@"Cancel");
 [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
 if (sheet.sheetParent != nil) return 9;
 ScreenSaverView *second = [[cls alloc] initWithFrame:NSMakeRect(0,0,320,200) isPreview:YES];
 if (second.configureSheet != sheet) return 10;
 NSSlider *width = slider(sheet,@"width"); width.doubleValue = 37; [width sendAction:width.action to:width.target];
 button(sheet,@"Save");
 if (slider(view.configureSheet,@"width").doubleValue != 37) return 11;
 button(sheet,@"Restore Defaults");
 if (slider(sheet,@"width").doubleValue != 25 || slider(sheet,@"cycle").doubleValue != 35) return 12;
 button(sheet,@"Cancel");
 ScreenSaverDefaults *d = [ScreenSaverDefaults defaultsForModuleWithName:[@"com.plasmalab.screensaver.test." stringByAppendingString:testID]];
 for (NSString *key in @[@"width",@"height",@"density",@"gap",@"speed",@"scale",@"complexity",@"cycle",@"palette",@"crt",@"fps",@"profileID"]) [d removeObjectForKey:key];
 [d synchronize];
 if (argc > 3 && strcmp(argv[3],"--exported")) {
  NSMutableDictionary *config = [@{@"values":[expected mutableCopy],@"palette":@0,@"crt":@NO,@"fps":@30,@"profileID":NSUUID.UUID.UUIDString} mutableCopy];
  config[@"values"][@"width"] = @31;
  NSData *data = [NSJSONSerialization dataWithJSONObject:config options:0 error:&error];
  Class exporter = NSClassFromString(@"PlasmaSettingsLauncher");
  NSURL *destination = [NSURL fileURLWithPath:[NSString stringWithUTF8String:argv[3]]];
  if (![exporter exportSaverTo:destination configuration:data error:&error]) { NSLog(@"Export failed: %@",error); return 13; }
 }
 [view stopAnimation];
 printf("PASS: live preview pixel changes, palette/CRT redraw, tracking-mode animation, zero-speed freeze/resume, screenshot defaults, bundle loading/rendering, 8 sliders and all menus, AppKit sheet attach/detach, shared lifetime, Cancel, isolated Save/reload, Restore Defaults, and configured export.\n");
 return 0;
} }
