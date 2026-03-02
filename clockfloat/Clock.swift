// The MIT License

// Copyright (c) 2023 Tadhg O'Brien

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Cocoa
import CoreGraphics
import CoreText

// MARK: - Notification

extension Notification.Name {
   static let clockConfigurationDidChange = Notification.Name("clockConfigurationDidChange")
}

// MARK: - HoverBehavior

enum HoverBehavior: String {
   case dodge   // move to opposite corner
   case hide    // fade out for 5s
   case none    // do nothing, draggable
}

// MARK: - ClockConfiguration

struct ClockConfiguration {
   enum Corner: String {
      case topLeft
      case topRight
      case bottomRight
      case bottomLeft
      case centerTop
      case centerBottom

      var orientationValue: Int {
         switch self {
         case .topLeft: return 0
         case .topRight: return 1
         case .bottomRight: return 2
         case .bottomLeft: return 3
         case .centerTop: return 4
         case .centerBottom: return 5
         }
      }
   }

   var fontName: String
   var dateFontSize: Double
   var timeFontSize: Double
   var initialCorner: Corner
   var hoverBehavior: HoverBehavior
   var timeFormat: String
   var dateFormat: String
   var lateEnabled: Bool
   var lateOffsetMinutes: Int
   var opacity: Double

   /// Late offset converted to seconds; 0 when disabled.
   var lateOffsetSeconds: Double {
      lateEnabled ? Double(lateOffsetMinutes) * 60.0 : 0.0
   }

   /// Text alpha derived from opacity (approximately 2/3 of background).
   var textAlpha: Double {
      opacity * 0.67
   }

   struct Keys {
      static let fontName = "ClockFontName"
      static let dateFontSize = "ClockDateFontSize"
      static let timeFontSize = "ClockTimeFontSize"
      static let initialCorner = "ClockInitialCorner"
      static let hoverBehavior = "ClockHoverBehavior"
      static let timeFormat = "ClockTimeFormat"
      static let dateFormat = "ClockDateFormat"
      static let lateEnabled = "ClockLateEnabled"
      static let lateOffsetMinutes = "ClockLateOffsetMinutes"
      static let opacity = "ClockOpacity"
      static let fontSizeMigrated = "ClockFontSizeMigrated"
   }

   // MARK: - Load

   static func load(userDefaults: UserDefaults = .standard) -> ClockConfiguration {
      userDefaults.register(defaults: [
         Keys.fontName: "White Rabbit",
         Keys.dateFontSize: 0.01,
         Keys.timeFontSize: 0.014,
         Keys.initialCorner: Corner.bottomRight.rawValue,
         Keys.hoverBehavior: HoverBehavior.dodge.rawValue,
         Keys.timeFormat: "HH:mm",
         Keys.dateFormat: "E d",
         Keys.lateEnabled: true,
         Keys.lateOffsetMinutes: 3,
         Keys.opacity: 0.75,
      ])

      let fontName = userDefaults.string(forKey: Keys.fontName) ?? "White Rabbit"
      var dateSize = userDefaults.object(forKey: Keys.dateFontSize) as? Double ?? 0.01
      var timeSize = userDefaults.object(forKey: Keys.timeFontSize) as? Double ?? 0.014
      let cornerRaw = userDefaults.string(forKey: Keys.initialCorner) ?? Corner.bottomRight.rawValue
      let corner = Corner(rawValue: cornerRaw) ?? .bottomRight
      let behaviorRaw = userDefaults.string(forKey: Keys.hoverBehavior) ?? HoverBehavior.dodge.rawValue
      let behavior = HoverBehavior(rawValue: behaviorRaw) ?? .dodge
      let timeFormat = userDefaults.string(forKey: Keys.timeFormat) ?? "HH:mm"
      let dateFormat = userDefaults.string(forKey: Keys.dateFormat) ?? "E d"
      let lateEnabled = userDefaults.object(forKey: Keys.lateEnabled) as? Bool ?? true
      let lateMinutes = userDefaults.object(forKey: Keys.lateOffsetMinutes) as? Int ?? 3
      let opacity = userDefaults.object(forKey: Keys.opacity) as? Double ?? 0.75

      // Migrate ratio-based font sizes to absolute point sizes
      if !userDefaults.bool(forKey: Keys.fontSizeMigrated) && dateSize < 1.0 && timeSize < 1.0 {
         let screenHeight = NSScreen.main?.visibleFrame.height ?? 1055.0
         let baseFont = NSFont(name: fontName, size: 20) ?? NSFont.monospacedDigitSystemFont(ofSize: 20, weight: .regular)
         let pixelsPerPoint = baseFont.boundingRectForFont.height / baseFont.pointSize

         dateSize = screenHeight * dateSize / pixelsPerPoint
         timeSize = screenHeight * timeSize / pixelsPerPoint

         userDefaults.set(dateSize, forKey: Keys.dateFontSize)
         userDefaults.set(timeSize, forKey: Keys.timeFontSize)
         userDefaults.set(true, forKey: Keys.fontSizeMigrated)
      }

      return ClockConfiguration(fontName: fontName,
                                dateFontSize: dateSize,
                                timeFontSize: timeSize,
                                initialCorner: corner,
                                hoverBehavior: behavior,
                                timeFormat: timeFormat,
                                dateFormat: dateFormat,
                                lateEnabled: lateEnabled,
                                lateOffsetMinutes: lateMinutes,
                                opacity: opacity)
   }

   // MARK: - Save

   func save(to userDefaults: UserDefaults = .standard) {
      userDefaults.set(fontName, forKey: Keys.fontName)
      userDefaults.set(dateFontSize, forKey: Keys.dateFontSize)
      userDefaults.set(timeFontSize, forKey: Keys.timeFontSize)
      userDefaults.set(initialCorner.rawValue, forKey: Keys.initialCorner)
      userDefaults.set(hoverBehavior.rawValue, forKey: Keys.hoverBehavior)
      userDefaults.set(timeFormat, forKey: Keys.timeFormat)
      userDefaults.set(dateFormat, forKey: Keys.dateFormat)
      userDefaults.set(lateEnabled, forKey: Keys.lateEnabled)
      userDefaults.set(lateOffsetMinutes, forKey: Keys.lateOffsetMinutes)
      userDefaults.set(opacity, forKey: Keys.opacity)
      userDefaults.set(true, forKey: Keys.fontSizeMigrated)

      NotificationCenter.default.post(name: .clockConfigurationDidChange, object: nil)
   }
}

class Clock: NSObject, NSApplicationDelegate {
   private struct WindowPair {
      let timeWindow: EvasiveWindow
      let dateWindow: EvasiveWindow
   }

   private var windowsByDisplayID: [CGDirectDisplayID: WindowPair] = [:]
   private var screenChangeObserver: NSObjectProtocol?
   private var configChangeObserver: NSObjectProtocol?

   var dateFont: String
   var dateFontSize: Double

   var timeFont: String
   var timeFontSize: Double

   var configuration: ClockConfiguration

   /// Late offset in seconds, derived from configuration.
   var late: Double {
      configuration.lateOffsetSeconds
   }

   override init() {
      let configuration = ClockConfiguration.load()
      self.configuration = configuration
      self.dateFont = configuration.fontName
      self.timeFont = configuration.fontName
      self.dateFontSize = configuration.dateFontSize
      self.timeFontSize = configuration.timeFontSize
      super.init()
   }

   func applicationDidFinishLaunching(_ aNotification: Notification) {
      self.registerEmbeddedFonts()
      self.initializeAllScreens()
      self.watchForScreenChanges()
      self.watchForConfigChanges()
   }

   func applicationWillTerminate(_ notification: Notification) {
      if let observer = self.screenChangeObserver {
         NotificationCenter.default.removeObserver(observer)
      }
      if let observer = self.configChangeObserver {
         NotificationCenter.default.removeObserver(observer)
      }
      self.teardownAllScreens()
   }

   deinit {
      if let observer = self.screenChangeObserver {
         NotificationCenter.default.removeObserver(observer)
      }
      if let observer = self.configChangeObserver {
         NotificationCenter.default.removeObserver(observer)
      }
   }

   func initializeAllScreens() {
      self.teardownAllScreens()

      for screen in NSScreen.screens {
         guard let displayID = screen.displayID else { continue }

         let timeWindow = self.initTimer(screen: screen)
         let dateWindow = self.initDater(screen: screen, stickWindow: timeWindow)

         self.windowsByDisplayID[displayID] = WindowPair(timeWindow: timeWindow, dateWindow: dateWindow)
      }
   }

   func teardownAllScreens() {
      for pair in self.windowsByDisplayID.values {
         pair.dateWindow.close()
         pair.timeWindow.close()
      }
      self.windowsByDisplayID.removeAll()
   }

   func watchForScreenChanges() {
      if let observer = self.screenChangeObserver {
         NotificationCenter.default.removeObserver(observer)
      }
      self.screenChangeObserver = NotificationCenter.default.addObserver(
         forName: NSApplication.didChangeScreenParametersNotification,
         object: nil,
         queue: .main) { [weak self] _ in
            self?.initializeAllScreens()
         }
   }

   func watchForConfigChanges() {
      if let observer = self.configChangeObserver {
         NotificationCenter.default.removeObserver(observer)
      }
      self.configChangeObserver = NotificationCenter.default.addObserver(
         forName: .clockConfigurationDidChange,
         object: nil,
         queue: .main) { [weak self] _ in
            guard let self = self else { return }
            self.configuration = ClockConfiguration.load()
            self.dateFont = self.configuration.fontName
            self.timeFont = self.configuration.fontName
            self.dateFontSize = self.configuration.dateFontSize
            self.timeFontSize = self.configuration.timeFontSize
            self.initializeAllScreens()
         }
   }

   func registerEmbeddedFonts() {
      guard let fontURL = Bundle.main.url(forResource: "white-rabbit", withExtension: "ttf") else {
         return
      }

      _ = CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
   }

   func initLabel(font: String, fontHeight: Double, screen: NSScreen, format: String, interval: TimeInterval, dummytext: String) -> TickingTextField {

      let formatter = DateFormatter()
      formatter.dateFormat = format
      formatter.locale = Locale.autoupdatingCurrent

//      let tmpLabel = NSTextField()
//      tmpLabel.font = NSFont(name: font, size: 20)
//      tmpLabel.isBezeled = false
//      tmpLabel.isEditable = false
//      tmpLabel.drawsBackground = false
//      tmpLabel.alignment = .center
//      tmpLabel.stringValue = dummytext

      let baseFont = NSFont(name: font, size: 20) ?? NSFont.monospacedDigitSystemFont(ofSize: 20, weight: .regular)
      let pixelsPerPoint = baseFont.boundingRectForFont.height / baseFont.pointSize
//      let tmpLabelHeight = tmpLabel.frame.height
//      let pixelsPerPoint = Double(tmpLabelHeight) / 20.0

      let label = TickingTextField()

      if fontHeight < 1.0 {
         let resolvedFontSize = screen.visibleFrame.height * fontHeight / pixelsPerPoint
         label.font = NSFont(name: font, size: resolvedFontSize) ?? NSFont.monospacedDigitSystemFont(ofSize: resolvedFontSize, weight: .regular)
      }
      else {
         label.font = NSFont(name: font, size: fontHeight) ?? NSFont.monospacedDigitSystemFont(ofSize: fontHeight, weight: .regular)
      }

      label.isBezeled = false
      label.isEditable = false
      label.drawsBackground = false
      label.alignment = .center
      label.stringValue = dummytext

      label.textColor = NSColor(red: 1, green: 1, blue: 1, alpha: self.configuration.textAlpha)
//        label.sizeToFit()

      label.timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
         label.stringValue = formatter.string(from: Date().addingTimeInterval(self.late))
      }
      label.timer!.tolerance = interval / 10
      label.timer!.fire()

      return label
   }

   func initWindow(label: TickingTextField, name: String, screen: NSScreen, stickWin: EvasiveWindow? = nil, orientation: Int? = nil) -> EvasiveWindow {
      let window = EvasiveWindow(label: label,
                                 name: name,
                                 screen: screen,
                                 stickWin: stickWin,
                                 hoverBehavior: self.configuration.hoverBehavior,
                                 backgroundOpacity: self.configuration.opacity,
                                 initialOrientation: orientation)

      return window
   }

   func initDater(screen: NSScreen, stickWindow: EvasiveWindow) -> EvasiveWindow {
//      if self.dateFontSize < 1.0 {
//         self.dateFontSize = self.dateFontSize * screen.frame.height
//      }

      let label = self.initLabel(
         font: self.dateFont,
         fontHeight: self.dateFontSize,
         screen: screen,
         format: self.configuration.dateFormat,
         interval: 10,
         dummytext: "XXX XX"
      )

      return self.initWindow(
         label: label,
         name: "dater",
         screen: screen,
         stickWin: stickWindow
      )
   }

   func initTimer(screen: NSScreen) -> EvasiveWindow {
      let label = self.initLabel(
         font: self.timeFont,
         fontHeight: self.timeFontSize,
         screen: screen,
         format: self.configuration.timeFormat,
         interval: 1,
         dummytext: "99:99"
      )

      return self.initWindow(
         label: label,
         name: "timer",
         screen: screen,
         orientation: self.configuration.initialCorner.orientationValue
      )
   }
}

private extension NSScreen {
   var displayID: CGDirectDisplayID? {
      let key = NSDeviceDescriptionKey("NSScreenNumber")
      guard let screenNumber = self.deviceDescription[key] as? NSNumber else {
         return nil
      }

      return CGDirectDisplayID(screenNumber.uint32Value)
   }
}
