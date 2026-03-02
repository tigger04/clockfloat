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

   static let positionCount = 6

   var xpadding: CGFloat = 5
   var ypadding: CGFloat = 5
   var wMarginRatio: CGFloat = 1.3
   var hMarginRatio: CGFloat = 1.3

   var stickToWindow: EvasiveWindow?
   var stuckToMeWindow: EvasiveWindow? = nil

   var orientation: Int = 2 // default
   // 0 = topleft, 1 = topright, 2 = bottomright, 3 = bottomleft
   // 4 = centerTop, 5 = centerBottom

   var name: String = "untitled"

   var tickingLabel: TickingTextField?

   var targetScreen: NSScreen?

   private let hoverBehavior: HoverBehavior
   private var hideTimer: Timer?

   public init(label: TickingTextField,
               name: String,
               screen: NSScreen,
               stickWin: EvasiveWindow? = nil,
               hoverBehavior: HoverBehavior = .dodge,
               backgroundOpacity: Double = 0.75,
               initialOrientation: Int? = nil)
   {
      self.name = name
      self.targetScreen = screen
      self.hoverBehavior = hoverBehavior

      let winHeight = label.fittingSize.height * self.hMarginRatio
      var winWidth = label.fittingSize.width * self.wMarginRatio

      if stickWin != nil {
         self.stickToWindow = stickWin
         winWidth = self.stickToWindow!.frame.width
      }

      if let initialOrientation = initialOrientation {
         self.orientation = initialOrientation % EvasiveWindow.positionCount
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
      cell.hoverBehavior = hoverBehavior
      cell.frame = NSRect(x: 0, y: 0, width: winWidth, height: label.fittingSize.height)
      label.frame = cell.frame
      label.alignment = .center

      let frame = label.frame
      var titleRect: NSRect = label.cell!.titleRect(forBounds: frame)

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
      self.backgroundColor = NSColor(red: 0, green: 0, blue: 0, alpha: CGFloat(backgroundOpacity))

      self.orderFrontRegardless()
      self.refreshOrigin()
   }

   public func move() {
      guard self.hoverBehavior == .dodge else { return }
      print("\(self.name) move")

      if self.stickToWindow == nil {
         self.orientation = Int(self.getOrientation() + 1) % EvasiveWindow.positionCount
         self.refreshOrigin()

         if self.stuckToMeWindow != nil {
            self.stuckToMeWindow!.refreshOrigin()
         }
      }
      else {
         self.stickToWindow!.move()
      }
   }

   /// Fade out the window, then fade back in after 5 seconds.
   public func hideTemporarily() {
      guard self.hoverBehavior == .hide else { return }

      // Cancel any pending reappearance
      self.hideTimer?.invalidate()
      self.stuckToMeWindow?.hideTimer?.invalidate()

      self.ignoresMouseEvents = true
      self.stuckToMeWindow?.ignoresMouseEvents = true

      NSAnimationContext.runAnimationGroup({ context in
         context.duration = 0.3
         self.animator().alphaValue = 0.0
         self.stuckToMeWindow?.animator().alphaValue = 0.0
      }) {
         self.hideTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.ignoresMouseEvents = false
            self.stuckToMeWindow?.ignoresMouseEvents = false
            NSAnimationContext.runAnimationGroup({ context in
               context.duration = 0.5
               self.animator().alphaValue = 1.0
               self.stuckToMeWindow?.animator().alphaValue = 1.0
            })
         }
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

         // Top positions: date goes below time. Bottom positions: date goes above time.
         let isTopPosition = [0, 1, 4].contains(self.getOrientation())
         let x = stickWin.frame.origin.x
         if isTopPosition {
            let y = stickWin.frame.origin.y - self.frame.height
            self.setFrameOrigin(NSPoint(x: x, y: y))
         }
         else {
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
         case 4: // centerTop
            x = (screenW - width) / 2 + screenX
            y = screenH - height - self.ypadding + screenY
         case 5: // centerBottom
            x = (screenW - width) / 2 + screenX
            y = self.ypadding + screenY
         default:
            x = screenW - width - self.xpadding + screenX
            y = self.ypadding + screenY
         }

         self.setFrameOrigin(NSPoint(x: x, y: y))
      }
   }

   override func close() {
      self.hideTimer?.invalidate()
      self.tickingLabel?.killTimer()
      super.close()
   }

   override func mouseDown(with event: NSEvent) {
      if event.modifierFlags.contains(.shift) {
         SettingsWindow.shared.showSettings()
         return
      }
      super.mouseDown(with: event)
   }

   override func rightMouseDown(with event: NSEvent) {
      super.rightMouseDown(with: event)
      print("right mouse button down")
      self.move()
   }

   deinit {
      print("EvasiveWindow.deinit (\(self.name))")
      self.hideTimer?.invalidate()
      if let tickingLabel = self.tickingLabel {
         tickingLabel.killTimer()
      }
   }
}

private final class HoverTrackingCellView: NSTableCellView {
   weak var windowOwner: EvasiveWindow?
   private var trackingArea: NSTrackingArea?
   var hoverBehavior: HoverBehavior = .dodge {
      didSet {
         if hoverBehavior != oldValue {
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

      guard self.hoverBehavior != .none else { return }

      let options: NSTrackingArea.Options = [.activeAlways, .mouseEnteredAndExited, .inVisibleRect]
      let area = NSTrackingArea(rect: self.bounds, options: options, owner: self, userInfo: nil)
      self.addTrackingArea(area)
      self.trackingArea = area
   }

   override func mouseEntered(with event: NSEvent) {
      super.mouseEntered(with: event)
      guard self.hoverBehavior != .none else { return }
      // Shift held: stay put so the user can interact with the clock
      guard !event.modifierFlags.contains(.shift) else { return }

      switch self.hoverBehavior {
      case .dodge:
         self.windowOwner?.move()
      case .hide:
         self.windowOwner?.hideTemporarily()
      case .none:
         break
      }
   }
}
