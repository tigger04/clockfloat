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
    var wMarginRatio : CGFloat = 1.1
    var hMarginRatio : CGFloat = 1.3
    
    var orientation : Int = 3
    
    var label : NSTextField = NSTextField()
    
//    override public init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool)
    public init(label: NSTextField) {
        
        // hack to get the damned thing vertically centered
        // thanks for nothing Cocoa
        let stringHeight: CGFloat = label.fittingSize.height
        let cell = NSTableCellView()
        cell.frame = NSRect(x: 0, y: 0, width: label.fittingSize.width, height: label.fittingSize.height)
        label.frame = cell.frame
        label.alignment = .center

        let frame = label.frame
        var titleRect:  NSRect = label.cell!.titleRect(forBounds: frame)

        titleRect.size.height = label.fittingSize.height
        titleRect.size.width = label.fittingSize.width
        titleRect.origin.y = frame.origin.y - ( frame.size.height - stringHeight ) / 2
        label.frame = titleRect
        cell.addSubview(label)
        
        super.init( contentRect: titleRect,
                    styleMask:   .borderless,
                    backing:     .buffered,
                    defer:       true)
        
        self.label = label
        
        self.contentView = cell
        self.ignoresMouseEvents = false
        self.level = .floating
        self.collectionBehavior = .canJoinAllSpaces
        self.backgroundColor = NSColor(red: 0, green: 0, blue: 0, alpha: 0.25)
        self.orderFrontRegardless()
        
    }
    
    func move() {
        let screenW = NSScreen.main!.frame.width
        let screenH = NSScreen.main!.frame.height
        
        let width = self.label.fittingSize.width * wMarginRatio
        let height = self.label.fittingSize.height * hMarginRatio
        
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
        
        self.rect = NSMakeRect(x, y, width, height)
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
