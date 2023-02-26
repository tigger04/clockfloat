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

    var screenW : CGFloat = NSScreen.main!.frame.width
    var screenH : CGFloat = NSScreen.main!.frame.height
    
    var dateFont : String = "New"
    var dateFontSize : CGFloat = 14
    
    var timeFont : String = "New"
    var timeFontSize : CGFloat = 22
    
    var xpadding : CGFloat = 10
    var ypadding : CGFloat = 10
    var wMarginRatio : CGFloat = 3.7
    var hMarginRatio : CGFloat = 3.7
    
    var orientation : Int = 3
    
    var theLabel : NSTextField = NSTextField()
    
//    override public init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool)
    public init(label: NSTextField) {
        
//        super.init( contentRect: NSMakeRect(300,300,300,300),
//                    styleMask:   .borderless,
//                    backing:     .buffered,
//                    defer:       true)
//
        let winWidth = label.fittingSize.width * wMarginRatio
        let winHeight = label.fittingSize.height * hMarginRatio
        
        let winRect = NSRect(x:0, y:0,
                             width: winWidth,
                             height: winHeight)
        
        super.init( contentRect: winRect,
                    styleMask:   .borderless,
                    backing:     .buffered,
                    defer:       true)
        
        // hack to get the damned thing vertically centered
        // thanks for nothing Cocoa
        let stringHeight: CGFloat = label.fittingSize.height
        let cell = NSTableCellView()
        cell.frame = NSRect(x: 0, y: 0, width: winWidth, height: label.fittingSize.height)
        label.frame = cell.frame
        label.alignment = .center

        let frame = label.frame
        var titleRect:  NSRect = label.cell!.titleRect(forBounds: frame)

//        titleRect.size.height = label.fittingSize.height
//        titleRect.size.width = label.fittingSize.width
        titleRect.origin.y = frame.origin.y + ( winHeight - stringHeight ) / 2
        label.frame = titleRect
        cell.addSubview(label)
        
        
        self.theLabel = label
        
        self.contentView = cell
        self.ignoresMouseEvents = false
        self.level = .floating
        self.collectionBehavior = .canJoinAllSpaces
        self.backgroundColor = NSColor(red: 0, green: 0, blue: 0, alpha: 0.25)
        self.orderFrontRegardless()
        self.move()
    }
    
    func move() {
        let screenW = self.screen?.frame.width ?? 0
        let screenH = self.screen?.frame.height ?? 0
//        let screenW = NSScreen.main!.frame.width
//        let screenH = NSScreen.main!.frame.height
        let width = self.frame.width
        let height = self.frame.height
        
        var x : CGFloat
        var y : CGFloat
        
        self.orientation = (orientation+1) % 4
        
        switch orientation {
        case 0: // topleft
            x = xpadding
            y = screenH - height - ypadding
        case 1: // topright
            x = screenW - width - xpadding
            y = screenH - height - ypadding
        case 2: // bottomright
            x = screenW - width - xpadding
            y = ypadding
        case 3: // bottomleft
            x = xpadding
            y = ypadding
        default:
            exit(1)
        }
        
        self.setFrameOrigin(NSPoint(x:x, y:y))
//        self.setContentSize(NSSize(width: width, height: height))
    }
    
    //    refresh() {
    //
    //    }
    //
    override func mouseEntered(with event: NSEvent) {
        orientation = Int( orientation + 1 ) % 4
//        move()
    }
}
