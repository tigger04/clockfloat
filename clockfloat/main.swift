//
//  main.swift
//  clockfloat
//
//  Created by tigger on 18/02/2023.
//

import Foundation
import Cocoa

let app = NSApplication.shared
let clock = Clock()
app.delegate = clock
app.setActivationPolicy(.accessory)
app.run()
