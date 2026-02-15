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

struct ClockConfiguration {
   enum Corner: String {
      case topLeft
      case topRight
      case bottomRight
      case bottomLeft

      var orientationValue: Int {
         switch self {
         case .topLeft: return 0
         case .topRight: return 1
         case .bottomRight: return 2
         case .bottomLeft: return 3
         }
      }
   }

   var fontName: String
   var dateFontSize: Double
   var timeFontSize: Double
   var initialCorner: Corner
   var dodgesMouse: Bool

   private struct Keys {
      static let fontName = "ClockFontName"
      static let dateFontSize = "ClockDateFontSize"
      static let timeFontSize = "ClockTimeFontSize"
      static let initialCorner = "ClockInitialCorner"
      static let dodgesMouse = "ClockDodgesMouse"
   }

   static func load(userDefaults: UserDefaults = .standard) -> ClockConfiguration {
      userDefaults.register(defaults: [
         Keys.fontName: "White Rabbit",
         Keys.dateFontSize: 0.01,
         Keys.timeFontSize: 0.014,
         Keys.initialCorner: Corner.bottomRight.rawValue,
         Keys.dodgesMouse: true,
      ])

      let font = userDefaults.string(forKey: Keys.fontName) ?? "White Rabbit"
      let dateSize = userDefaults.object(forKey: Keys.dateFontSize) as? Double ?? 0.01
      let timeSize = userDefaults.object(forKey: Keys.timeFontSize) as? Double ?? 0.014
      let cornerRaw = userDefaults.string(forKey: Keys.initialCorner) ?? Corner.bottomRight.rawValue
      let corner = Corner(rawValue: cornerRaw) ?? .bottomRight
      let dodges = userDefaults.object(forKey: Keys.dodgesMouse) as? Bool ?? true

      return ClockConfiguration(fontName: font,
                                dateFontSize: dateSize,
                                timeFontSize: timeSize,
                                initialCorner: corner,
                                dodgesMouse: dodges)
   }
}

class Clock: NSObject, NSApplicationDelegate {
   private struct WindowPair {
      let timeWindow: EvasiveWindow
      let dateWindow: EvasiveWindow
   }

   private var windowsByDisplayID: [CGDirectDisplayID: WindowPair] = [:]
   private var screenChangeObserver: NSObjectProtocol?

   var dateFont: String
   var dateFontSize: Double

   var timeFont: String
   var timeFontSize: Double

   var late : Double = 150

   let configuration: ClockConfiguration

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
   }

   func applicationWillTerminate(_ notification: Notification) {
      if let observer = self.screenChangeObserver {
         NotificationCenter.default.removeObserver(observer)
      }
      self.teardownAllScreens()
   }

   deinit {
      if let observer = self.screenChangeObserver {
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

      label.textColor = NSColor(red: 1, green: 1, blue: 1, alpha: 0.5)
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
                                 dodgesMouse: self.configuration.dodgesMouse,
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
         format: "E d",
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
         format: "HH:mm",
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
