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

class Clock: NSObject, NSApplicationDelegate {
   var dateWindow: EvasiveWindow?
   var timeWindow: EvasiveWindow?

   var dateFont: String = "White Rabbit"
   var dateFontSize: Double = 0.01

   var timeFont: String = "White Rabbit"
   var timeFontSize: Double = 0.014

   var late : Double = 150

   func applicationDidFinishLaunching(_ aNotification: Notification) {
      self.initializeAllScreens()
      self.watchForScreenChanges()
   }

   func initializeAllScreens() {

      for screen in NSScreen.screens {
         self.initTimer(screen: screen)
         self.initDater(screen: screen)
      }
   }

   func watchForScreenChanges() {
      NotificationCenter.default.addObserver(
         forName: NSNotification.Name(rawValue: "NSApplicationDidChangeScreenParametersNotification"),
         object: NSApplication.shared,
         queue: .main) { notification in
            if let dateWindow = self.dateWindow {
               dateWindow.close()
            }
            if let timeWindow = self.timeWindow {
               timeWindow.close()
            }
            self.initializeAllScreens()
         }
   }

   func initLabel(font: String, fontHeight: Double, screen: NSScreen, format: String, interval: TimeInterval, dummytext: String) -> TickingTextField {

      let formatter = DateFormatter()
      formatter.dateFormat = format

//      let tmpLabel = NSTextField()
//      tmpLabel.font = NSFont(name: font, size: 20)
//      tmpLabel.isBezeled = false
//      tmpLabel.isEditable = false
//      tmpLabel.drawsBackground = false
//      tmpLabel.alignment = .center
//      tmpLabel.stringValue = dummytext

      let pixelsPerPoint = NSFont(name: font, size: 20)!.boundingRectForFont.height / 20.0
//      let tmpLabelHeight = tmpLabel.frame.height
//      let pixelsPerPoint = Double(tmpLabelHeight) / 20.0

      let label = TickingTextField()

      if fontHeight < 1.0 {
         let resolvedFontSize = screen.frame.height * fontHeight / pixelsPerPoint
         label.font = NSFont(name: font, size: resolvedFontSize)
      }
      else {
         label.font = NSFont(name: font, size: fontHeight)
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

   func initWindow(label: TickingTextField, name: String, screen: NSScreen, stickWin: EvasiveWindow? = nil) -> EvasiveWindow {
      let window = EvasiveWindow(label: label, name: name, screen: screen, stickWin: stickWin)

      return window
   }

   func initDater(screen: NSScreen) {
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

      self.dateWindow = self.initWindow(
         label: label,
         name: "dater",
         screen: screen,
         stickWin: self.timeWindow!
      )
   }

   func initTimer(screen: NSScreen) {
      let label = self.initLabel(
         font: self.timeFont,
         fontHeight: self.timeFontSize,
         screen: screen,
         format: "HH:mm",
         interval: 1,
         dummytext: "99:99"
      )

      self.timeWindow = self.initWindow(
         label: label,
         name: "timer",
         screen: screen
      )
   }
}
