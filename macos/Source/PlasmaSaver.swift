import AppKit
import ScreenSaver
import UniformTypeIdentifiers

private let domain = "com.plasmalab.screensaver" + (ProcessInfo.processInfo.environment["PLASMA_LAB_TEST_ID"].map { ".test." + $0 } ?? "")
private let keys = ["width", "height", "density", "gap", "speed", "scale", "complexity", "cycle"]
private let initial: [String: Double] = ["width":25,"height":25,"density":100,"gap":0,"speed":50,"scale":75,"complexity":50,"cycle":35]
private let colors: [[String]] = [
 ["100a36","3322a3","b21fbe","ff527d","ffb267","ffeea3","83e1d0","3453bd"],
 ["180924","6b133c","d73347","ff7538","ffd16b","fff4be","f76567"],
 ["020b27","113087","3d3dc4","7964e8","4ac9ed","8bfff0","147aab"],
 ["211047","8b19c9","ff3598","ffab78","ecff78","62f8bb","25afc4"],
 ["030f13","064a42","14a575","85df6b","e2ffb4","369b74"],
 ["080e24","273657","778ba2","dfe8dd","9fadd0","39446e"]]
private let paletteNames = ["Amiga dreams", "Molten sunset", "Electric ocean", "Acid candy", "Phosphor green", "Moonlight"]
private let presetValues: [[Double]] = [[12,12,100,4,65,100,55,20], [8,8,100,0,40,65,70,12], [6,12,110,4,35,130,38,15], [28,28,95,18,115,150,85,50]]
private struct Settings: Codable {
 var profileID = "screenshot-defaults-v2"
 var values = initial
 var palette = 0
 var crt = false
 var fps = 30
 static func load() -> Settings {
  var s = Settings()
  if let url = Bundle(for: PlasmaSaverView.self).url(forResource:"Defaults",withExtension:"json"),
     let data = try? Data(contentsOf:url), let embedded = try? JSONDecoder().decode(Settings.self,from:data) { s = embedded }
  guard let d = ScreenSaverDefaults(forModuleWithName: domain) else { return s }
  // Old defaults belong to v1; an exported profile gets its own preference generation.
  d.synchronize()
  guard d.string(forKey:"profileID") == s.profileID else { return s }
  let ranges: [(Double,Double)] = [(3,48),(3,48),(40,200),(0,60),(0,250),(30,250),(0,100),(0,100)]
  for (i,k) in keys.enumerated() { if d.object(forKey:k) != nil { let n = d.double(forKey:k); if n.isFinite { s.values[k] = min(ranges[i].1,max(ranges[i].0,n)) } } }
  s.palette = min(5,max(0,d.integer(forKey:"palette")))
  if d.object(forKey:"crt") != nil { s.crt = d.bool(forKey:"crt") }
  if [15,30,60].contains(d.integer(forKey:"fps")) { s.fps = d.integer(forKey:"fps") }
  return s
 }
 func save() {
  guard let d = ScreenSaverDefaults(forModuleWithName: domain) else { return }
  d.set(profileID,forKey:"profileID")
  for (k,v) in values { d.set(v,forKey:k) }
  d.set(palette,forKey:"palette"); d.set(crt,forKey:"crt"); d.set(fps,forKey:"fps"); d.synchronize()
 }
}

@objc(PlasmaSaverView)
final class PlasmaSaverView: ScreenSaverView {
 private var settings = Settings.load()
 private var table: [CGColor] = []
 private var phase: Double = 0
 private var previous: TimeInterval = 0
 private static var options: OptionsController?
 private var settingsTick = 0
 fileprivate var usesDraftSettings = false
 override init?(frame: NSRect, isPreview: Bool) {
  super.init(frame: frame, isPreview: isPreview)
  animationTimeInterval = 1 / Double(settings.fps)
  rebuildPalette()
 }
 required init?(coder: NSCoder) { super.init(coder:coder); rebuildPalette() }
 override var isOpaque: Bool { true }
 override var hasConfigureSheet: Bool { true }
 override var configureSheet: NSWindow? {
  let makeWindow: () -> NSWindow? = {
   if Self.options == nil { Self.options = OptionsController { _ in } }
   Self.options?.reload()
   return Self.options?.window
  }
  return Thread.isMainThread ? makeWindow() : DispatchQueue.main.sync(execute:makeWindow)
 }
 fileprivate func apply(_ s: Settings) {
  settings = s; animationTimeInterval = 1 / Double(s.fps); rebuildPalette(); needsDisplay = true
 }
 private func rebuildPalette() {
  let p = colors[settings.palette].map { hex -> (Double,Double,Double) in
   let n = UInt32(hex,radix:16) ?? 0
   return (Double((n >> 16) & 255)/255,Double((n >> 8) & 255)/255,Double(n & 255)/255)
  }
  table = (0..<1024).map { i in
   let x = Double(i)/1024*Double(p.count), a = p[Int(x)], b = p[(Int(x)+1)%p.count], f = x-floor(x)
   return CGColor(red:a.0*(1-f)+b.0*f,green:a.1*(1-f)+b.1*f,blue:a.2*(1-f)+b.2*f,alpha:1)
  }
 }
 override func startAnimation() { settingsTick = 0; apply(Settings.load()); previous = ProcessInfo.processInfo.systemUptime; super.startAnimation() }
 override func stopAnimation() { super.stopAnimation(); previous = 0 }
 override func animateOneFrame() {
  let now = ProcessInfo.processInfo.systemUptime
  let dt = previous > 0 ? min(0.1,max(0,now-previous)) : 0
  previous = now; phase += dt * settings.values["speed"]! / 100
  settingsTick += 1
  if !usesDraftSettings && settingsTick >= settings.fps * 2 { settingsTick = 0; apply(Settings.load()) }
  needsDisplay = true
 }
 override func draw(_ dirtyRect: NSRect) {
  guard let c = NSGraphicsContext.current?.cgContext, bounds.width > 0, bounds.height > 0 else { return }
  c.setFillColor(CGColor(gray:0.02,alpha:1)); c.fill(bounds)
  // Work in a reference space so tiny previews and large monitors show the same composition.
  let w = 1280.0, h = w * Double(bounds.height / bounds.width)
  let v = settings.values
  var bw = v["width"]! * 100/v["density"]!, bh = v["height"]! * 100/v["density"]!
  let budgetScale = max(1,sqrt((w/bw)*(h/bh)/36000))
  bw *= budgetScale; bh *= budgetScale
  let cols = Int(ceil(w/bw)), rows = Int(ceil(h/bh)), aspect = w/h, sc = v["scale"]!/100
  let turbulence = v["complexity"]!/100, gap = v["gap"]!/100, t = phase
  c.saveGState(); c.scaleBy(x:bounds.width/w,y:bounds.height/h); c.setShouldAntialias(false)
  for y in 0..<rows {
   let py = ((Double(y)+0.5)/Double(rows)-0.5)*sc*7
   for x in 0..<cols {
    let px = ((Double(x)+0.5)/Double(cols)-0.5)*aspect*sc*7
    var z = sin(px*1.4+t*0.9)+sin(py*1.7-t*0.7)+sin((px+py)*0.8+t*0.5)
    z += sin(hypot(px+sin(t*0.36)*2,py+cos(t*0.29)*2)*2.1-t*1.2)
    z += turbulence*(sin(px*2.7+sin(py*1.8+t))+cos(py*2.4+cos(px+t*0.7)))
    let p = z/(8+4*turbulence)+0.5+t*v["cycle"]!/100*0.08
    let index = ((Int(floor(p*1024)) % 1024)+1024)%1024
    c.setFillColor(table[index]); c.fill(CGRect(x:Double(x)*bw,y:h-Double(y+1)*bh,width:bw*(1-gap),height:bh*(1-gap)))
   }
  }
  if settings.crt {
   c.setFillColor(CGColor(gray:0,alpha:0.16))
   for y in stride(from:0.0,to:h,by:3) { c.fill(CGRect(x:0,y:y,width:w,height:1)) }
   let space = CGColorSpaceCreateDeviceRGB()
   if let gradient = CGGradient(colorsSpace:space,colors:[CGColor(gray:0,alpha:0),CGColor(gray:0,alpha:0.55)] as CFArray,locations:[0,1]) {
    c.drawRadialGradient(gradient,startCenter:CGPoint(x:w/2,y:h/2),startRadius:min(w,h)*0.2,endCenter:CGPoint(x:w/2,y:h/2),endRadius:max(w,h)*0.65,options:.drawsAfterEndLocation)
   }
  }
  c.restoreGState()
 }
}

// Render the editor into an ordinary AppKit image view. ScreenSaverView's own
// display lifecycle is controlled by the system host, so it is not used as a UI subview.
@objc(PlasmaPreviewView)
private final class PlasmaPreviewView: NSImageView {
 private let renderer: PlasmaSaverView
 override init(frame:NSRect) {
  renderer = PlasmaSaverView(frame:NSRect(origin:.zero,size:frame.size),isPreview:true)!
  renderer.usesDraftSettings = true
  super.init(frame:frame)
  imageScaling = .scaleAxesIndependently
  setAccessibilityLabel("Live plasma preview")
 }
 required init?(coder:NSCoder) { fatalError("Not supported") }
 fileprivate func apply(_ settings:Settings) { renderer.apply(settings); renderFrame() }
 fileprivate func animateOneFrame() { renderer.animateOneFrame(); renderFrame() }
 private func renderFrame() {
  guard bounds.width > 0, bounds.height > 0 else { return }
  let scale = window?.backingScaleFactor ?? 1
  guard let bitmap = NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:Int(ceil(bounds.width*scale)),pixelsHigh:Int(ceil(bounds.height*scale)),bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0),
        let context = NSGraphicsContext(bitmapImageRep:bitmap) else { return }
  bitmap.size = bounds.size
  renderer.setFrameSize(bounds.size)
  NSGraphicsContext.saveGraphicsState()
  NSGraphicsContext.current = context
  context.cgContext.scaleBy(x:scale,y:scale)
  renderer.draw(renderer.bounds)
  NSGraphicsContext.restoreGraphicsState()
  // A fresh image avoids reusing a cached layer backing store after a control changes.
  let next = NSImage(size:bounds.size); next.addRepresentation(bitmap)
  image = next
  needsDisplay = true
  displayIfNeeded()
 }
}

private final class OptionsController: NSWindowController, NSWindowDelegate {
 private var draft = Settings.load()
 private var sliders: [String:NSSlider] = [:]
 private var readouts: [String:NSTextField] = [:]
 private let palette = NSPopUpButton()
 private let preset = NSPopUpButton()
 private let fps = NSPopUpButton()
 private let crt = NSButton(checkboxWithTitle:"CRT scanlines and vignette",target:nil,action:nil)
 private var preview: PlasmaPreviewView!
 private var timer: Timer?
 private let onSave: (Settings)->Void
 private let standalone: Bool
 init(standalone: Bool = false, onSave: @escaping (Settings)->Void) {
  self.onSave = onSave; self.standalone = standalone
  let window = NSWindow(contentRect:NSRect(x:0,y:0,width:750,height:640),styleMask:standalone ? [.titled,.closable,.miniaturizable] : [.titled],backing:.buffered,defer:false)
  window.title = standalone ? "Plasma Lab Settings" : "Plasma Lab Options"
  window.isReleasedWhenClosed = false
  super.init(window:window)
  let root = NSView(frame:NSRect(x:0,y:0,width:750,height:640))
  let content = NSViewController(); content.view = root; window.contentViewController = content
  window.delegate = self
  func text(_ title:String,_ rect:NSRect,_ font:NSFont = .systemFont(ofSize:13)) {
   let l = NSTextField(labelWithString:title); l.frame = rect; l.font = font; root.addSubview(l)
  }
  text("Plasma Lab",NSRect(x:24,y:595,width:400,height:27),.systemFont(ofSize:22,weight:.semibold))
  text("Amiga-inspired plasma, made for your Mac.",NSRect(x:24,y:571,width:550,height:20))
  preview = PlasmaPreviewView(frame:NSRect(x:24,y:318,width:332,height:234))
  preview.wantsLayer = true; preview.layer?.cornerRadius = 9; preview.layer?.masksToBounds = true; root.addSubview(preview)
  text("LIVE PREVIEW",NSRect(x:24,y:293,width:332,height:18),.systemFont(ofSize:10,weight:.medium))
  text("Preset",NSRect(x:24,y:248,width:90,height:22))
  preset.frame = NSRect(x:108,y:247,width:248,height:26); preset.addItems(withTitles:["Amiga dreams","Liquid heat","Deep space","Pixel party","Custom"]); preset.target = self; preset.action = #selector(presetChanged); root.addSubview(preset)
  text("Palette",NSRect(x:24,y:207,width:90,height:22))
  palette.frame = NSRect(x:108,y:206,width:248,height:26); palette.addItems(withTitles:paletteNames); palette.target = self; palette.action = #selector(changed); root.addSubview(palette)
  text("Frame rate",NSRect(x:24,y:166,width:90,height:22))
  fps.frame = NSRect(x:108,y:165,width:248,height:26); fps.addItems(withTitles:["15 fps · Lower power","30 fps · Balanced","60 fps · Smooth"]); fps.target = self; fps.action = #selector(changed); root.addSubview(fps)
  crt.frame = NSRect(x:24,y:123,width:330,height:25); crt.target = self; crt.action = #selector(changed); root.addSubview(crt)
  text(standalone ? "Save & Install creates a configured screen saver.\nApprove its replacement in the macOS installer." : "Movement dismisses the screen saver.\nSet idle time and password behavior in System Settings.",NSRect(x:24,y:72,width:335,height:43),.systemFont(ofSize:11))
  let names = ["Block width","Block height","Grid density","Pixel gap","Wave speed","Wave scale","Turbulence","Color drift"]
  let limits: [(Double,Double)] = [(3,48),(3,48),(40,200),(0,60),(0,250),(30,250),(0,100),(0,100)]
  for (i,k) in keys.enumerated() {
   let y = 522 - i*55
   text(names[i],NSRect(x:389,y:y+10,width:190,height:19))
   let out = NSTextField(labelWithString:""); out.frame = NSRect(x:605,y:y+10,width:117,height:19); out.alignment = .right; out.font = .monospacedDigitSystemFont(ofSize:12,weight:.regular); root.addSubview(out); readouts[k] = out
   let slider = NSSlider(value:draft.values[k]!,minValue:limits[i].0,maxValue:limits[i].1,target:self,action:#selector(sliderChanged(_:)))
   slider.frame = NSRect(x:389,y:y-15,width:333,height:24); slider.identifier = NSUserInterfaceItemIdentifier(k); slider.isContinuous = true; slider.setAccessibilityLabel(names[i]); root.addSubview(slider); sliders[k] = slider
  }
  let line = NSBox(frame:NSRect(x:24,y:58,width:702,height:1)); line.boxType = .separator; root.addSubview(line)
  let reset = NSButton(title:"Restore Defaults",target:self,action:#selector(resetDefaults)); reset.frame = NSRect(x:20,y:15,width:150,height:30); reset.bezelStyle = .rounded; root.addSubview(reset)
  let random = NSButton(title:"Surprise Me",target:self,action:#selector(randomize)); random.frame = NSRect(x:180,y:15,width:120,height:30); random.bezelStyle = .rounded; root.addSubview(random)
  let cancel = NSButton(title:"Cancel",target:self,action:#selector(cancel)); cancel.frame = NSRect(x:standalone ? 500 : 536,y:15,width:90,height:30); cancel.bezelStyle = .rounded; cancel.keyEquivalent = "\u{1b}"; root.addSubview(cancel)
  let save = NSButton(title:standalone ? "Save & Install…" : "Save",target:self,action:#selector(save)); save.frame = NSRect(x:standalone ? 600 : 632,y:15,width:standalone ? 126 : 90,height:30); save.bezelStyle = .rounded; save.keyEquivalent = "\r"; root.addSubview(save)
 }
 required init?(coder:NSCoder) { fatalError("Not supported") }
 func reload() {
  draft = Settings.load()
  if standalone, let data = UserDefaults.standard.data(forKey:"lastExport"), let last = try? JSONDecoder().decode(Settings.self,from:data) { draft = last }
  preset.selectItem(at:4); sync()
 }
 private func sync() {
  for k in keys { sliders[k]?.doubleValue = draft.values[k]! }
  palette.selectItem(at:draft.palette); crt.state = draft.crt ? .on : .off; fps.selectItem(at:[15,30,60].firstIndex(of:draft.fps) ?? 1)
  refresh()
 }
 private func refresh() {
  for k in keys {
   let n = draft.values[k]!
   readouts[k]?.stringValue = (k == "width" || k == "height") ? "\(Int(n)) px" : ((k == "speed" || k == "scale") ? String(format:"%.2f×",n/100) : "\(Int(n))%")
  }
  preview.apply(draft)
  let interval = 1.0/Double(draft.fps)
  // Preserve the timer while dragging; restarting it on every input starves animation.
  if timer == nil || timer?.isValid == false || abs((timer?.timeInterval ?? 0)-interval) > 0.0001 {
   timer?.invalidate()
   timer = Timer(timeInterval:interval,repeats:true) { [weak self] _ in self?.preview.animateOneFrame() }
   RunLoop.main.add(timer!,forMode:.common)
  }
 }
 @objc private func sliderChanged(_ sender:NSSlider) { if let k = sender.identifier?.rawValue { draft.values[k] = sender.doubleValue.rounded() }; preset.selectItem(at:4); refresh() }
 @objc private func changed() { draft.palette = palette.indexOfSelectedItem; draft.crt = crt.state == .on; draft.fps = [15,30,60][fps.indexOfSelectedItem]; preset.selectItem(at:4); refresh() }
 @objc private func presetChanged() { let i = preset.indexOfSelectedItem; guard i < 4 else { return }; for (j,k) in keys.enumerated() { draft.values[k] = presetValues[i][j] }; draft.palette = i; sync() }
 @objc private func resetDefaults() { draft = Settings(); preset.selectItem(at:4); sync() }
 @objc private func randomize() { for k in keys { if let s = sliders[k] { draft.values[k] = Double.random(in:s.minValue...s.maxValue).rounded() } }; draft.palette = Int.random(in:0..<6); preset.selectItem(at:4); sync() }
 private func dismiss() { timer?.invalidate(); timer = nil; if let w = window { if let parent = w.sheetParent { parent.endSheet(w) } else { w.orderOut(nil) } } }
 func windowWillClose(_ notification: Notification) { timer?.invalidate(); timer = nil; if standalone { NSApp.terminate(nil) } }
 @objc private func cancel() { dismiss(); if standalone { NSApp.terminate(nil) } }
 @objc private func save() {
  if standalone { PlasmaSettingsLauncher.chooseExport(draft,parent:window!) }
  else { draft.save(); onSave(draft); dismiss() }
 }
 deinit { timer?.invalidate() }
}


/// The companion app hosts the same controls without relying on System Settings' sheet routing.
@objc(PlasmaSettingsLauncher)
final class PlasmaSettingsLauncher: NSObject {
 private static var editor: OptionsController?
 @objc static func run() {
  NSApp.setActivationPolicy(.regular)
  editor = OptionsController(standalone:true) { _ in }
  editor?.reload(); editor?.window?.center(); editor?.showWindow(nil)
  NSApp.activate(ignoringOtherApps:true)
 }
 fileprivate static func chooseExport(_ settings:Settings,parent:NSWindow) {
  let panel = NSSavePanel()
  panel.title = "Save a configured Plasma Lab screen saver"
  panel.nameFieldStringValue = "Plasma Lab.saver"
  panel.allowedContentTypes = [UTType(filenameExtension:"saver") ?? .bundle]
  panel.canCreateDirectories = true
  panel.message = "Save outside your installed Screen Savers folder. The macOS installer will handle replacement."
  panel.beginSheetModal(for:parent) { response in
   guard response == .OK, let url = panel.url else { return }
   do {
    var profile = settings; profile.profileID = UUID().uuidString
    let data = try JSONEncoder().encode(profile)
    try exportSaver(to:url,configuration:data)
    UserDefaults.standard.set(data,forKey:"lastExport")
    if !NSWorkspace.shared.open(url) { throw NSError(domain:domain,code:2,userInfo:[NSLocalizedDescriptionKey:"The screen saver was saved, but macOS could not open its installer. Double-click the saved .saver in Finder."]) }
   } catch {
    let alert = NSAlert(error:error); alert.beginSheetModal(for:parent)
   }
  }
 }
 @objc static func exportSaver(to url:URL,configuration:Data) throws {
  // Configuration is embedded, then the bundle is signed again. No other process's container is accessed.
  _ = try JSONDecoder().decode(Settings.self,from:configuration)
  let fm = FileManager.default
  let source = Bundle(for:PlasmaSaverView.self).bundleURL
  let destination = url.standardizedFileURL.resolvingSymlinksInPath()
  let installed = fm.homeDirectoryForCurrentUser.appendingPathComponent("Library/Screen Savers",isDirectory:true).standardizedFileURL.resolvingSymlinksInPath().path
  guard !destination.path.hasPrefix(installed + "/"), !destination.path.hasPrefix("/Library/Screen Savers/"), destination.pathExtension == "saver", !destination.path.hasPrefix(source.path + "/"), destination.path != source.path else {
   throw NSError(domain:domain,code:1,userInfo:[NSLocalizedDescriptionKey:"Choose a .saver file in Downloads or another folder outside the installed Screen Savers folder and this app."])
  }
  let temp = fm.temporaryDirectory.appendingPathComponent("PlasmaExport-" + UUID().uuidString,isDirectory:true)
  try fm.createDirectory(at:temp,withIntermediateDirectories:true)
  defer { try? fm.removeItem(at:temp) }
  let staged = temp.appendingPathComponent("Plasma Lab.saver",isDirectory:true)
  try fm.copyItem(at:source,to:staged)
  try configuration.write(to:staged.appendingPathComponent("Contents/Resources/Defaults.json"),options:.atomic)
  // Clear only bundle metadata which codesign rejects; leave quarantine and security attributes alone.
  for attribute in ["com.apple.FinderInfo","com.apple.ResourceFork"] {
   let clean = Process(); clean.executableURL = URL(fileURLWithPath:"/usr/bin/xattr"); clean.arguments = ["-dr",attribute,staged.path]
   clean.standardError = FileHandle.nullDevice; try clean.run(); clean.waitUntilExit()
  }
  let sign = Process(); sign.executableURL = URL(fileURLWithPath:"/usr/bin/codesign"); sign.arguments = ["--force","--sign","-",staged.path]
  let errors = Pipe(); sign.standardError = errors; try sign.run()
  let errorData = errors.fileHandleForReading.readDataToEndOfFile(); sign.waitUntilExit()
  guard sign.terminationStatus == 0 else { throw NSError(domain:domain,code:3,userInfo:[NSLocalizedDescriptionKey:"Could not sign the configured screen saver: " + (String(data:errorData,encoding:.utf8) ?? "unknown error")]) }
  // NSSavePanel explicitly authorizes replacing an existing export at the selected location.
  if fm.fileExists(atPath:destination.path) { _ = try fm.replaceItemAt(destination,withItemAt:staged) }
  else { try fm.moveItem(at:staged,to:destination) }
 }
}
