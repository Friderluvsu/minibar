//
//  StatusBarController.swift
//  Minibar
//

import AppKit

class StatusBarController {
    
    //MARK: - Variables
    private var timer: Timer? = nil
    
    //MARK: - BarItems
        
    private let btnExpandCollapse = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let btnSeparate = NSStatusBar.system.statusItem(withLength: 1)
    
    private var btnHiddenLength: CGFloat = 20
    private var btnHiddenCollapseLength: CGFloat = 2000
    
    private let imgIconLine = NSImage(named: NSImage.Name("ic_line"))
    
    private var isCollapsed: Bool {
        return self.btnSeparate.length > self.btnHiddenLength
    }
    
    private var isBtnSeparateValidPosition: Bool {
        guard
            let btnExpandCollapseX = self.btnExpandCollapse.button?.getOrigin?.x,
            let btnSeparateX = self.btnSeparate.button?.getOrigin?.x
            else { return false }
        
        if Constant.isUsingLTRLanguage {
            return btnExpandCollapseX >= btnSeparateX
        } else {
            return btnExpandCollapseX <= btnSeparateX
        }
    }
    
    private var isToggle = false
    private var hideMechanismChecked = false
    private var hoverMonitor: Any?
    private var hoverDwellTimer: Timer?

    // True while the pointer sits in any screen's menubar band
    private var isMouseInMenuBar: Bool {
        let mouse = NSEvent.mouseLocation
        return NSScreen.screens.contains { screen in
            mouse.x >= screen.frame.minX && mouse.x <= screen.frame.maxX
                && mouse.y >= screen.visibleFrame.maxY && mouse.y <= screen.frame.maxY
        }
    }

    // The preferences window is an ordinary app window, not in the menu bar
    private var isPreferencesWindowVisible: Bool {
        let wc = PreferencesWindowController.shared
        return wc.isWindowLoaded && (wc.window?.isVisible ?? false)
    }
    
    //MARK: - Methods
    init() {
        NSLog("Minibar: StatusBarController init started")
        updateCollapsedLengths()
        setupUI()
        restoreRemovedStatusItems()
        setupHoverToExpandIfEnabled()
        NotificationCenter.default.addObserver(self, selector: #selector(handleScreenParametersChanged), name: NSApplication.didChangeScreenParametersNotification, object: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            NSLog("Minibar: triggering initial collapseMenuBar")
            self?.collapseMenuBar()
        }
        
        if Preferences.areSeparatorsHidden {
            hideSeparators()
        } else {
            showSeparators()
        }
        autoCollapseIfNeeded()
        NSLog("Minibar: StatusBarController init finished")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        hoverDwellTimer?.invalidate()
        if let monitor = hoverMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    // Opt-in via `defaults write com.frider.minibar hoverToExpand -bool true`.
    private func setupHoverToExpandIfEnabled() {
        guard Preferences.hoverToExpand else { return }
        NSLog("HoverToExpand: enabled, installing global mouse monitor")
        hoverMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] _ in
            guard let self = self else { return }
            guard self.isCollapsed && self.isMouseInMenuBar else {
                self.hoverDwellTimer?.invalidate()
                self.hoverDwellTimer = nil
                return
            }
            guard self.hoverDwellTimer == nil else { return }
            self.hoverDwellTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
                guard let self = self else { return }
                self.hoverDwellTimer = nil
                if self.isCollapsed && self.isMouseInMenuBar {
                    self.expandMenubar()
                }
            }
        }
    }
    
    @objc private func handleScreenParametersChanged() {
        let wasCollapsed = isCollapsed
        updateCollapsedLengths()
        if wasCollapsed {
            btnSeparate.length = btnHiddenCollapseLength
        }
    }

    private func updateCollapsedLengths() {
        btnHiddenCollapseLength = 1200
    }
    
    private func restoreRemovedStatusItems() {
        btnExpandCollapse.isVisible = true
        btnSeparate.isVisible = true
    }

    private func setupUI() {
        NSLog("Minibar: setupUI started")
        if let button = btnSeparate.button {
            button.image = Preferences.areSeparatorsHidden ? nil : self.imgIconLine
            NSLog("Minibar: btnSeparate.button image set. hidden=\(Preferences.areSeparatorsHidden)")
        } else {
            NSLog("Minibar: WARNING - btnSeparate.button is nil")
        }
        let menu = self.getContextMenu()
        btnSeparate.menu = menu

        updateAutoCollapseMenuTitle()
        
        if let button = btnExpandCollapse.button {
            let img = Assets.collapseImage
            button.image = img
            button.title = (img == nil) ? "◀" : "" // Backup text title if image is nil
            button.target = self
            
            button.action = #selector(self.btnExpandCollapsePressed(sender:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            NSLog("Minibar: btnExpandCollapse.button initialized. image exists=\(img != nil)")
        } else {
            NSLog("Minibar: WARNING - btnExpandCollapse.button is nil")
        }
        
        btnExpandCollapse.autosaveName = "minibar_expandcollapse"
        btnSeparate.autosaveName = "minibar_separate"
        NSLog("Minibar: setupUI finished")
    }
    
    @objc func btnExpandCollapsePressed(sender: NSStatusBarButton) {
        if let event = NSApp.currentEvent {
            let isOptionKeyPressed = event.modifierFlags.contains(NSEvent.ModifierFlags.option)

            if event.type == NSEvent.EventType.leftMouseUp && !isOptionKeyPressed {
                self.expandCollapseIfNeeded()
            } else if event.type == NSEvent.EventType.rightMouseUp && !isOptionKeyPressed {
                showContextMenu(from: sender)
            } else {
                self.toggleSeparators()
            }
        }
    }

    private func showContextMenu(from button: NSStatusBarButton) {
        guard let menu = btnSeparate.menu else { return }
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.maxY + 5), in: button)
    }
    
    func toggleSeparators() {
        Preferences.areSeparatorsHidden.toggle()
        if self.isCollapsed { self.expandMenubar() }
    }
    
    private func showSeparators() {
        if let button = btnSeparate.button {
            button.image = self.imgIconLine
        }
        if !self.isCollapsed {
            self.btnSeparate.length = self.btnHiddenLength
        }
    }
    
    private func hideSeparators() {
        if let button = btnSeparate.button {
            button.image = nil
        }
        if !self.isCollapsed {
            self.btnSeparate.length = 1.0
        }
    }
    
    func expandCollapseIfNeeded() {
        if isToggle { return }
        isToggle = true
        self.isCollapsed ? self.expandMenubar() : self.collapseMenuBar()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.isToggle = false
        }
    }
    
    private func collapseMenuBar() {
        guard self.isBtnSeparateValidPosition && !self.isCollapsed else {
            autoCollapseIfNeeded()
            return
        }

        // 1. Set the collapsed length first (which forces layout and resets window properties)
        btnSeparate.length = self.btnHiddenCollapseLength

        // 2. Hide separator button, disable it, and set ignoresMouseEvents AFTER layout is forced
        if let button = btnSeparate.button {
            button.image = nil
            button.isEnabled = false
            button.isHidden = true
            button.window?.ignoresMouseEvents = true
        }
        btnSeparate.menu = nil

        if let button = btnExpandCollapse.button {
            button.image = Assets.expandImage
        }
        if Preferences.useFullStatusBarOnExpandEnabled {
            NSApp.setActivationPolicy(.accessory)
            NSApp.deactivate()
        }
        verifyHideMechanismIfNeeded()
    }
    
    private func expandMenubar() {
        guard self.isCollapsed else { return }
        
        // 1. Set the expanded length first
        btnSeparate.length = Preferences.areSeparatorsHidden ? 1.0 : btnHiddenLength
        
        // 2. Restore visibility, image, and clickability AFTER layout is forced
        if let button = btnSeparate.button {
            button.isHidden = false
            button.image = Preferences.areSeparatorsHidden ? nil : self.imgIconLine
            button.isEnabled = true
            button.window?.ignoresMouseEvents = false
        }
        btnSeparate.menu = self.getContextMenu()

        if let button = btnExpandCollapse.button {
            button.image = Assets.collapseImage
        }
        autoCollapseIfNeeded()
        
        if Preferences.useFullStatusBarOnExpandEnabled {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    private func autoCollapseIfNeeded() {
        guard Preferences.isAutoHide else { return }
        guard !isCollapsed else { return }
        startTimerToAutoHide()
    }

    private func verifyHideMechanismIfNeeded() {
        guard !hideMechanismChecked else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.isCollapsed else { return }
            guard let separatorButton = self.btnSeparate.button,
                  let window = separatorButton.window else { return }
            self.hideMechanismChecked = true
            let requested = self.btnHiddenCollapseLength
            let windowWidth = window.frame.width
            let buttonWidth = separatorButton.frame.width
            NSLog("HideMechanism: requested=\(requested) windowWidth=\(windowWidth) buttonWidth=\(buttonWidth) length=\(self.btnSeparate.length)")
        }
    }
    
    private func startTimerToAutoHide() {
        timer?.invalidate()
        self.timer = Timer.scheduledTimer(withTimeInterval: Preferences.numberOfSecondForAutoHide, repeats: false) { [weak self] _ in
            guard let self = self, Preferences.isAutoHide else { return }
            if self.isMouseInMenuBar || self.isPreferencesWindowVisible {
                self.startTimerToAutoHide()
            } else {
                self.collapseMenuBar()
            }
        }
    }
    
    private func getContextMenu() -> NSMenu {
        let menu = NSMenu()
        
        let prefItem = NSMenuItem(title: "Preferences...".localized, action: #selector(openPreferenceViewControllerIfNeeded), keyEquivalent: "P")
        prefItem.target = self
        menu.addItem(prefItem)
        
        let toggleAutoHideItem = NSMenuItem(title: "Toggle Auto Collapse".localized, action: #selector(toggleAutoHide), keyEquivalent: "t")
        toggleAutoHideItem.target = self
        toggleAutoHideItem.tag = 1
        NotificationCenter.default.addObserver(self, selector: #selector(updateAutoHide), name: .prefsChanged, object: nil)
        menu.addItem(toggleAutoHideItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit".localized, action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        return menu
    }
    
    private func updateAutoCollapseMenuTitle() {
        guard let toggleAutoHideItem = btnSeparate.menu?.item(withTag: 1) else { return }
        if Preferences.isAutoHide {
            toggleAutoHideItem.title = "Disable Auto Collapse".localized
        } else {
            toggleAutoHideItem.title = "Enable Auto Collapse".localized
        }
    }
    
    @objc func updateAutoHide() {
        updateAutoCollapseMenuTitle()
        autoCollapseIfNeeded()
        if Preferences.areSeparatorsHidden {
            hideSeparators()
        } else {
            showSeparators()
        }
    }
    
    @objc func openPreferenceViewControllerIfNeeded() {
        Util.showPrefWindow()
    }
    
    @objc func toggleAutoHide() {
        Preferences.isAutoHide.toggle()
    }
}
