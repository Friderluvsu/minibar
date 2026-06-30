//
//  main.swift
//  Minibar
//

import AppKit

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

app.finishLaunching()

withExtendedLifetime(delegate) {
    app.run()
}
