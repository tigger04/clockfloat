// The MIT License

// Copyright (c) 2018 Daniel

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
   var dater: EvasiveWindow?
   var timer: EvasiveWindow?
//    var screenW : CGFloat = NSScreen.main!.frame.width
//    var screenH : CGFloat = NSScreen.main!.frame.height

   var dateFont: String = "New"
   var dateFontSize: CGFloat = 14

   var timeFont: String = "New"
   var timeFontSize: CGFloat = 22

//    var xpadding : CGFloat = 10
//    var ypadding : CGFloat = 10
//    var wMarginRatio : CGFloat = 1.1
//    var hMarginRatio : CGFloat = 1.3

//    var clockRect : CGRect = CGRect(x:0, y:0, width: 0, height: 0)

   func applicationDidFinishLaunching(_ aNotification: Notification) {
      self.initTimer()
      self.initDater()
   }

   func initLabel(font: NSFont, format: String, interval: TimeInterval, dummytext: String) -> NSTextField {
      let formatter = DateFormatter()
      formatter.dateFormat = format

      let label = NSTextField()
      label.font = font
      label.isBezeled = false
      label.isEditable = false
      label.drawsBackground = false
      label.alignment = .center
      label.stringValue = dummytext

//        label.textColor = NSColor(red: 1, green: 1, blue: 1, alpha: 1-(1/3)*(1/3))
      label.textColor = NSColor(red: 1, green: 1, blue: 1, alpha: 0.5)
//        label.sizeToFit()

      let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
         label.stringValue = formatter.string(from: Date())
      }
      timer.tolerance = interval / 10
      timer.fire()

      return label
   }

   func initWindow(label: NSTextField, name: String, stickWin: EvasiveWindow? = nil) -> EvasiveWindow {
      let window = EvasiveWindow(label: label, name: name, stickWin: stickWin)

      return window
   }

   func initDater() {
      let label = self.initLabel(
         font: NSFont(name: self.dateFont, size: self.dateFontSize)!,
         format: "E d",
         interval: 10,
         dummytext: "XXX XX"
      )

      self.dater = self.initWindow(
         label: label,
         name: "dater",
         stickWin: self.timer!
      )
   }

   func initTimer() {
      let label = self.initLabel(
         //            font     : NSFont.monospacedDigitSystemFont(ofSize: 36, weight: .regular),
         font: NSFont(name: self.timeFont, size: self.timeFontSize)!,
         format: "HH:mm",
         interval: 1,
         dummytext: "99:99"
      )

      self.timer = self.initWindow(
         label: label,
         name: "timer"
      )
   }
}
