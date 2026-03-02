//
//  SettingsWindow.swift
//  clockfloat
//

import Cocoa

final class SettingsWindow: NSWindow {

    static let shared = SettingsWindow()

    private init() {
        let windowRect = NSRect(x: 0, y: 0, width: 400, height: 300)

        super.init(contentRect: windowRect,
                   styleMask: [.titled, .closable],
                   backing: .buffered,
                   defer: true)

        self.title = "Clock Settings"
        self.isReleasedWhenClosed = false
        self.level = .floating
        self.center()
    }

    func showSettings() {
        self.center()
        self.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
