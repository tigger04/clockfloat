//
//  TickingTextArea.swift
//  clockfloat
//
//  Created by tigger on 12/03/2023.
//

import Foundation
import Cocoa

class TickingTextField: NSTextField {
   var timer : Timer?

   func killTimer() {
      if let timer = self.timer {
         print("invalidaing timer")
         timer.invalidate()
      }
   }
}
