// ABOUTME: Thin singleton shell hosting the SwiftUI SettingsView.
// ABOUTME: Floating window opened via right-click on the clock.

import Cocoa
import SwiftUI

final class SettingsWindow: NSWindow {

    static let shared = SettingsWindow()

    private init() {
        let windowRect = NSRect(x: 0, y: 0, width: 350, height: 500)

        super.init(contentRect: windowRect,
                   styleMask: [.titled, .closable],
                   backing: .buffered,
                   defer: true)

        self.title = "Clock Settings"
        self.isReleasedWhenClosed = false
        self.level = .floating
        self.contentViewController = NSHostingController(rootView: SettingsView())
        self.center()
    }

    func showSettings() {
        self.center()
        self.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
