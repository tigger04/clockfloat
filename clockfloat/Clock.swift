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
    var dater : NSWindow?
    var timer : NSWindow?
    var screenW : CGFloat = NSScreen.main!.frame.width
    var screenH : CGFloat = NSScreen.main!.frame.height
    
    var dateFont : String = "New"
    var dateFontSize : CGFloat = 14
    var dateW : CGFloat = 100
    var dateH : CGFloat = 20
    
    var timeFont : String = "New"
    var timeFontSize : CGFloat = 22
    var timeW : CGFloat = 1000
    var timeH : CGFloat = 1000
    
    var xpadding : CGFloat = 10
    var ypadding : CGFloat = 10
    var wMarginRatio : CGFloat = 1.1
    var hMarginRatio : CGFloat = 1.3
    
    var orientation : Int = 3
    // 1 = topleft, 2 = topright, 3 = bottomright, 4 = bottomleft

//    var clockOrigin : CGPoint = CGPoint(x: 0 , y: 0)
    var clockRect : CGRect = CGRect(x:0, y:0, width: 0, height: 0)
    var Rect : CGRect = CGRect(x:0, y:0, width: 0, height: 0)
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        screenW = NSScreen.main!.frame.width
        screenH = NSScreen.main!.frame.height
        
        self.initTimer()
        self.initDater()
    }

    func initLabel(font: NSFont, format: String, interval: TimeInterval) -> NSTextField {
        let formatter = DateFormatter()
        formatter.dateFormat = format

        let label = NSTextField()
        label.font = font
        label.isBezeled = false
        label.isEditable = false
        label.drawsBackground = false
        label.alignment = .center
        
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

    func initWindow(rect: NSRect, label: NSTextField) -> NSWindow {
        let window = NSWindow(
            contentRect : rect,
            styleMask   : .borderless,
            backing     : .buffered,
            defer       : true
        )

        // hack to get the damned thing vertically centered
        // thanks for nothing Cocoa
        let cell = NSTableCellView()
        cell.frame = NSRect(x: 0, y: 0, width: rect.width, height: rect.height)
        label.frame = cell.frame
//        tf.stringValue = "MyTextfield"
        label.alignment = .center

        let stringHeight: CGFloat = label.fittingSize.height
        let frame = label.frame
        var titleRect:  NSRect = label.cell!.titleRect(forBounds: frame)

        titleRect.size.height = rect.height
        titleRect.size.width = rect.width
//        titleRect.origin.y = frame.size.height / 2  - label.lastBaselineOffsetFromBottom - label.font!.xHeight / 2
        titleRect.origin.y = frame.origin.y - ( frame.size.height - stringHeight ) / 2
        label.frame = titleRect
        cell.addSubview(label)
        
        window.contentView = cell
//        window.ignoresMouseEvents = false
        window.ignoresMouseEvents = true
//        window.isMovableByWindowBackground = true
        window.level = .floating
        window.collectionBehavior = .canJoinAllSpaces
        window.backgroundColor = NSColor(red: 0, green: 0, blue: 0, alpha: 0.25)
        window.orderFrontRegardless()
//        window.isMovableByWindowBackground = true
        
        return window
    }
    
    func mouseEntered(with event: NSEvent) {
        // this needs to move to a custom NSView or something
        orientation = Int( orientation + 1 ) % 4
    }

    func initDater() {
        let label = self.initLabel(
//            font     : NSFont.monospacedDigitSystemFont(ofSize: 18, weight: .regular),
            font     : NSFont(name: dateFont, size: dateFontSize)!,
            format   : "E d",
            interval : 10
        )
        
        let width = clockRect.width
        let height = label.fittingSize.height * hMarginRatio
        
        var x : CGFloat
        var y : CGFloat
        
        switch orientation {
            
            case 1: // topleft
                x = clockRect.minX
                y = clockRect.minY - height
            
            case 2: // topright
                x = clockRect.minX
                y = clockRect.minY - height
            
            case 3: // bottomright
                x = clockRect.minX
                y = clockRect.minY + clockRect.height

            case 4: // bottomleft
                x = clockRect.minX
                y = clockRect.minY + clockRect.height
                
            default:
                exit(1)
                
        }
        
        self.dater = self.initWindow(
            rect     : NSMakeRect(x,
                                  y,
                                  width,
                                  height),
            label    : label
        )
    }

    func initTimer() {
        
        let label = self.initLabel(
            //            font     : NSFont.monospacedDigitSystemFont(ofSize: 36, weight: .regular),
            font     : NSFont(name: timeFont, size: timeFontSize)!,
            format   : "HH:mm",
            interval : 1
        )
        
        let width = label.fittingSize.width * wMarginRatio
        let height = label.fittingSize.height * hMarginRatio
        
        var x : CGFloat
        var y : CGFloat
        
        switch orientation {
        case 1: // topleft
            x = xpadding
            y = screenH - height - ypadding
        case 2: // topright
            x = screenW - width - xpadding
            y = screenH - height - ypadding
        case 3: // bottomright
            x = screenW - width - xpadding
            y = ypadding
        case 4: // bottomleft
            x = xpadding
            y = ypadding
        default:
            exit(1)
        }
        
        clockRect = CGRect(x: x, y: y, width: width, height: height)
        
        self.timer = self.initWindow(
            rect     : NSMakeRect(x,
                                  y,
                                  width,
                                  height),
            label    : label
        )
    }
}

