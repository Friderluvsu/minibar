//
//  AppDelegate.swift
//  Minibar
//

import AppKit
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate {
    
    var statusBarController: StatusBarController!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSLog("Minibar: applicationDidFinishLaunching started")
        registerDefaultValues()
        setupAutoStartApp()
        openPreferencesIfNeeded()
        detectLTRLang()
        
        NSLog("Minibar: instantiating StatusBarController")
        statusBarController = StatusBarController()
        NSLog("Minibar: applicationDidFinishLaunching finished")
    }
    
    func openPreferencesIfNeeded() {
        if Preferences.isShowPreference {
            Util.showPrefWindow()
        }
    }
    
    func setupAutoStartApp() {
        removeLegacyLauncherLoginItem()
        Util.setUpAutoStart(isAutoStart: Preferences.isAutoStart)
    }

    private func removeLegacyLauncherLoginItem() {
        // Builds before the SMAppService migration registered a helper app in BTM;
        // macOS never garbage-collects that record (TN3111), so deauthorize it once.
        let migratedKey = "smAppServiceMigrated"
        guard !UserDefaults.standard.bool(forKey: migratedKey) else { return }
        SMLoginItemSetEnabled("com.dwarvesv.LauncherApplication" as CFString, false)
        UserDefaults.standard.set(true, forKey: migratedKey)
    }
    
    func registerDefaultValues() {
         UserDefaults.standard.register(defaults: [
            UserDefaults.Key.isAutoStart: false,
            UserDefaults.Key.isShowPreference: true,
            UserDefaults.Key.isAutoHide: true,
            UserDefaults.Key.numberOfSecondForAutoHide: 10.0,
            UserDefaults.Key.areSeparatorsHidden: true, // Default to true to hide the divider line
         ])
    }
    
    func detectLTRLang() {
        // Languages like Arabic uses right to left (RTL) writing direction,
        // so some behavior of the app needs to be changed in these cases
        
        Constant.isUsingLTRLanguage = (NSApplication.shared.userInterfaceLayoutDirection == .leftToRight)
    }
   
}

