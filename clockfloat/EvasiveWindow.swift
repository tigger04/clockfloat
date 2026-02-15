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

   var xpadding: CGFloat = 5
   var ypadding: CGFloat = 5
   var wMarginRatio: CGFloat = 1.3
   var hMarginRatio: CGFloat = 1.3

   var stickToWindow: EvasiveWindow?
   var stuckToMeWindow: EvasiveWindow? = nil

   var orientation: Int = 2 // default
   // 0 = topleft, 1 = topright, 2 = bottomright, 3 = bottomleft

   var name: String = "untitled"

   var tickingLabel : TickingTextField?

   var targetScreen : NSScreen?

   private let dodgesMouse: Bool

   public init(label: TickingTextField,
               name: String,
               screen: NSScreen,
               stickWin: EvasiveWindow? = nil,
               dodgesMouse: Bool = true,
               initialOrientation: Int? = nil)
   {
      self.name = name
      self.targetScreen = screen
      self.dodgesMouse = dodgesMouse

      let winHeight = label.fittingSize.height * self.hMarginRatio
      var winWidth = label.fittingSize.width * self.wMarginRatio

      if stickWin != nil {
         self.stickToWindow = stickWin
         winWidth = self.stickToWindow!.frame.width
      }

      if let initialOrientation = initialOrientation {
         self.orientation = initialOrientation % 4
      }

      let winRect = NSRect(x: 0, y: 0,
                           width: winWidth,
                           height: winHeight)

      super.init(contentRect: winRect,
                 styleMask: .borderless,
                 backing: .buffered,
                 defer: true)

      if stickWin != nil {
         print("\(self.stickToWindow!.name) is stuck to \(self.name)")
         self.stickToWindow!.stuckToMeWindow = self
      }

      // hack to get the damned thing vertically centered
      // thanks for nothing Cocoa
      let stringHeight: CGFloat = label.fittingSize.height
      let cell = HoverTrackingCellView()
      cell.windowOwner = self
      cell.hoverEnabled = dodgesMouse
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
      self.tickingLabel = label

      self.contentView = cell
      cell.updateTrackingAreas()
      self.ignoresMouseEvents = false
      self.isMovableByWindowBackground = true
      self.level = .floating
      self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
      self.backgroundColor = NSColor(red: 0, green: 0, blue: 0, alpha: 0.75)

      self.orderFrontRegardless()
      self.refreshOrigin()
   }

   public func move() {
      guard self.dodgesMouse else { return }
      print("\(self.name) move")

      if self.stickToWindow == nil {
         self.orientation = Int(self.getOrientation() + 1) % 4
         self.refreshOrigin()

         if self.stuckToMeWindow != nil {
            self.stuckToMeWindow!.refreshOrigin()
         }
      }
      else {
         self.stickToWindow!.move()
      }
   }

   public func getOrientation() -> Int {
      if self.stickToWindow == nil {
         return self.orientation
      }
      else {
         return self.stickToWindow!.getOrientation()
      }
   }

   func refreshOrigin() {
      print("\(self.name) refresh origin. I have an orientation of \(self.getOrientation())")

      if let stickWin = self.stickToWindow {
         print("\(self.name) must stick to \(stickWin.name)")

         if self.getOrientation() < 2 {
            let x = stickWin.frame.origin.x
            let y = stickWin.frame.origin.y - self.frame.height
            self.setFrameOrigin(NSPoint(x: x, y: y))
         }
         else {
            let x = stickWin.frame.origin.x
            let y = stickWin.frame.origin.y + stickWin.frame.height
            self.setFrameOrigin(NSPoint(x: x, y: y))
         }
      }
      else {
         print("\(self.name) is free and easy")

         let screenFrame = self.targetScreen?.visibleFrame ?? self.targetScreen?.frame ?? .zero
         let screenW = screenFrame.width
         let screenH = screenFrame.height
         let screenX = screenFrame.origin.x
         let screenY = screenFrame.origin.y

         let width = self.frame.width
         let height = self.frame.height

         var x: CGFloat
         var y: CGFloat

         switch self.getOrientation() {
         case 0: // topleft
            x = self.xpadding + screenX
            y = screenH - height - self.ypadding + screenY
         case 1: // topright
            x = screenW - width - self.xpadding + screenX
            y = screenH - height - self.ypadding + screenY
         case 2: // bottomright
            x = screenW - width - self.xpadding + screenX
            y = self.ypadding + screenY
         case 3: // bottomleft
            x = self.xpadding + screenX
            y = self.ypadding + screenY
         default:
            exit(1)
         }

         self.setFrameOrigin(NSPoint(x: x, y: y))
      }
      //        self.setContentSize(NSSize(width: width, height: height))
   }

   //    public func setStickToWindow(win: EvasiveWindow) {
   //        self.stickToWindow = win
   //        self.frame.size.width = self.stickToWindow.frame.size.width
   //        self.refreshOrigin()
   //    }

   override func close() {
      self.tickingLabel?.killTimer()
      super.close()
   }

   override func rightMouseDown(with event: NSEvent) {
      super.rightMouseDown(with: event)
      print("right mouse button down")
      self.move()
   }

   deinit {
      print("EvasiveWindow.deinit (\(self.name))")
      if let tickingLabel = self.tickingLabel {
         tickingLabel.killTimer()
      }
   }
}

private final class HoverTrackingCellView: NSTableCellView {
   weak var windowOwner: EvasiveWindow?
   private var trackingArea: NSTrackingArea?
   var hoverEnabled: Bool = true {
      didSet {
         if hoverEnabled != oldValue {
            self.updateTrackingAreas()
         }
      }
   }

   override func updateTrackingAreas() {
      super.updateTrackingAreas()

      if let trackingArea = self.trackingArea {
         self.removeTrackingArea(trackingArea)
         self.trackingArea = nil
      }

      guard self.hoverEnabled else { return }

      let options: NSTrackingArea.Options = [.activeAlways, .mouseEnteredAndExited, .inVisibleRect]
      let area = NSTrackingArea(rect: self.bounds, options: options, owner: self, userInfo: nil)
      self.addTrackingArea(area)
      self.trackingArea = area
   }

   override func mouseEntered(with event: NSEvent) {
      super.mouseEntered(with: event)
      guard self.hoverEnabled else { return }
      self.windowOwner?.move()
   }
}
