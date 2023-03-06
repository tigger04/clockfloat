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

class EvasiveWindow: NSWindow {
   var screenW: CGFloat = NSScreen.main!.frame.width
   var screenH: CGFloat = NSScreen.main!.frame.height

   var dateFont: String = "New"
   var dateFontSize: CGFloat = 14

   var timeFont: String = "New"
   var timeFontSize: CGFloat = 22

   var xpadding: CGFloat = 10
   var ypadding: CGFloat = 10
   var wMarginRatio: CGFloat = 3.7
   var hMarginRatio: CGFloat = 3.7

   var stickToWindow: EvasiveWindow?
   var orientation: Int = 0

   var name: String = "untitled"

   public init(label: NSTextField, name: String,
               stickWin: EvasiveWindow? = nil)
   {
      self.name = name

      let winHeight = label.fittingSize.height * self.hMarginRatio
      var winWidth = label.fittingSize.width * self.wMarginRatio

      if stickWin != nil {
         self.stickToWindow = stickWin
         winWidth = self.stickToWindow!.frame.width
      }

      let winRect = NSRect(x: 0, y: 0,
                           width: winWidth,
                           height: winHeight)

      super.init(contentRect: winRect,
                 styleMask: .borderless,
                 backing: .buffered,
                 defer: true)

      print("\(self.name).init winWidth=\(winWidth), winHeight=\(winHeight)")
      print("\(self.name).init frame.width=\(self.frame.width), frame.height=\(self.frame.height)")

      // hack to get the damned thing vertically centered
      // thanks for nothing Cocoa
      let stringHeight: CGFloat = label.fittingSize.height
      let cell = NSTableCellView()
      cell.frame = NSRect(x: 0, y: 0, width: winWidth, height: label.fittingSize.height)
      label.frame = cell.frame
      label.alignment = .center

      let frame = label.frame
      var titleRect: NSRect = label.cell!.titleRect(forBounds: frame)

      //        titleRect.size.height = label.fittingSize.height
      //        titleRect.size.width = label.fittingSize.width
      titleRect.origin.y = frame.origin.y + (winHeight - stringHeight) / 2
      label.frame = titleRect
      cell.addSubview(label)

      self.contentView = cell
      self.ignoresMouseEvents = false
      self.isMovableByWindowBackground = true
      self.level = .floating
      self.collectionBehavior = .canJoinAllSpaces
      self.backgroundColor = NSColor(red: 0, green: 0, blue: 0, alpha: 0.75)
      self.orderFrontRegardless()
      self.refreshOrigin()
   }

   func move() {
      print("\(self.name) move")
      self.orientation = Int(self.orientation + 1) % 4
      self.refreshOrigin()
   }

   //    func getWidth() -> CGFloat {
   //        return self.frame.width
   //    }

   func refreshOrigin() {
      print("\(self.name) refresh origin. I have an orientation of \(self.orientation)")

      if let stickWin = self.stickToWindow {
         print("\(self.name) must stick to \(stickWin.name)")

         if self.orientation < 2 {
            let x = stickWin.frame.origin.x
            let y = stickWin.frame.origin.y - self.frame.height
            self.setFrameOrigin(NSPoint(x: x, y: y))
         }
         else {
            let x = stickWin.frame.origin.x
            let y = stickWin.frame.origin.y + self.frame.height
            self.setFrameOrigin(NSPoint(x: x, y: y))
         }
      }
      else {
         print("\(self.name) is free and easy")

         let screenW = self.screen?.frame.width ?? 0
         let screenH = self.screen?.frame.height ?? 0
         //        let screenW = NSScreen.main!.frame.width
         //        let screenH = NSScreen.main!.frame.height
         let width = self.frame.width
         let height = self.frame.height

         var x: CGFloat
         var y: CGFloat

         switch self.orientation {
         case 0: // topleft
            x = self.xpadding
            y = screenH - height - self.ypadding
         case 1: // topright
            x = screenW - width - self.xpadding
            y = screenH - height - self.ypadding
         case 2: // bottomright
            x = screenW - width - self.xpadding
            y = self.ypadding
         case 3: // bottomleft
            x = self.xpadding
            y = self.ypadding
         default:
            exit(1)
         }

         self.setFrameOrigin(NSPoint(x: x, y: y))
      }
      //        self.setContentSize(NSSize(width: width, height: height))
   }

   public func getOrientation() -> Int {
      return self.orientation
   }

   //    public func setStickToWindow(win: EvasiveWindow) {
   //        self.stickToWindow = win
   //        self.frame.size.width = self.stickToWindow.frame.size.width
   //        self.refreshOrigin()
   //    }

   override func mouseEntered(with event: NSEvent) {
      super.mouseEntered(with: event)
      print("mouse entered")
      self.move()
   }

   override func mouseExited(with event: NSEvent) {
      super.mouseExited(with: event)
      print("mouse exited")
   }

   override func mouseDown(with event: NSEvent) {
      super.mouseDown(with: event)
      print("mouse down")
      //        self.move()
   }

   override func rightMouseDown(with event: NSEvent) {
      super.rightMouseDown(with: event)
      print("right mouse button down")
      self.move()
   }
}
