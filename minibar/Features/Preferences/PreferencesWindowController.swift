//
//  PreferencesWindowController.swift
//  Minibar
//

import Cocoa
import SwiftUI

class PreferencesWindowController: NSWindowController {
    
    static let shared: PreferencesWindowController = {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 350, height: 400),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Minibar Settings"
        window.isReleasedWhenClosed = false
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.backgroundColor = .clear
        window.isOpaque = false
        
        window.contentView = NSHostingView(rootView: PreferencesView())
        
        let wc = PreferencesWindowController(window: window)
        return wc
    }()
    
    override func windowDidLoad() {
        super.windowDidLoad()
    }
}
