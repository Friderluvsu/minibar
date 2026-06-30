//
//  PreferencesView.swift
//  Minibar
//

import SwiftUI

struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        view.wantsLayer = true
        view.layer?.cornerRadius = 16
        view.layer?.masksToBounds = true
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.wantsLayer = true
        nsView.layer?.cornerRadius = 16
        nsView.layer?.masksToBounds = true
    }
}

struct PreferencesView: View {
    @AppStorage("isAutoStart") var isAutoStart: Bool = false
    @AppStorage("isAutoHide") var isAutoHide: Bool = true
    @AppStorage("numberOfSecondForAutoHide") var autoHideDelay: Double = 10.0
    @AppStorage("hoverToExpand") var hoverToExpand: Bool = false
    @AppStorage("areSeparatorsHidden") var areSeparatorsHidden: Bool = true
    @AppStorage("useFullStatusBarOnExpandEnabled") var useFullStatus: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(localizedString("app_settings").uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
                    .tracking(0.5)
                    .padding(.leading, 56) // Align to the right of traffic lights
                Spacer()
                Text("v1.11")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(.horizontal, 16)
            .padding(.top, 26) // Align vertically with traffic lights when ignoring safe area
            .padding(.bottom, 12)
            
            // Content
            VStack(alignment: .leading, spacing: 14) {
                
                // SYSTEM
                VStack(alignment: .leading, spacing: 4) {
                    Text(localizedString("system_settings").uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white.opacity(0.3))
                        .padding(.leading, 4)
                    
                    VStack(spacing: 0) {
                        toggleRow(isOn: $isAutoStart, title: localizedString("start_at_login"), sub: localizedString("start_at_login_desc"))
                            .onChange(of: isAutoStart) { newValue in
                                Util.setUpAutoStart(isAutoStart: newValue)
                                NotificationCenter.default.post(name: .prefsChanged, object: nil)
                            }
                    }
                    .background(Color.white.opacity(0.02))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )
                }
                
                // BEHAVIOR
                VStack(alignment: .leading, spacing: 4) {
                    Text(localizedString("behavior_settings").uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white.opacity(0.3))
                        .padding(.leading, 4)
                    
                    VStack(spacing: 0) {
                        toggleRow(isOn: $isAutoHide, title: localizedString("auto_hide"), sub: localizedString("auto_hide_desc"))
                            .onChange(of: isAutoHide) { _ in
                                NotificationCenter.default.post(name: .prefsChanged, object: nil)
                            }
                        
                        if isAutoHide {
                            Divider()
                                .background(Color.white.opacity(0.04))
                            sliderRow()
                        }
                        
                        Divider()
                            .background(Color.white.opacity(0.04))
                        
                        toggleRow(isOn: $hoverToExpand, title: localizedString("hover_to_expand"), sub: localizedString("hover_to_expand_desc"))
                            .onChange(of: hoverToExpand) { _ in
                                NotificationCenter.default.post(name: .prefsChanged, object: nil)
                            }
                    }
                    .background(Color.white.opacity(0.02))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )
                }
                
                // APPEARANCE
                VStack(alignment: .leading, spacing: 4) {
                    Text(localizedString("appearance_settings").uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white.opacity(0.3))
                        .padding(.leading, 4)
                    
                    VStack(spacing: 0) {
                        toggleRow(isOn: $areSeparatorsHidden, title: localizedString("hide_separator"), sub: localizedString("hide_separator_desc"))
                            .onChange(of: areSeparatorsHidden) { _ in
                                NotificationCenter.default.post(name: .prefsChanged, object: nil)
                            }
                    }
                    .background(Color.white.opacity(0.02))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 16)
            
            Spacer(minLength: 0)
            
            // Footer
            VStack(spacing: 10) {
                Divider()
                    .background(Color.white.opacity(0.06))
                
                HStack {
                    Text(localizedString("description"))
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.3))
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Button(action: {
                        NSApplication.shared.terminate(nil)
                    }) {
                        Text(localizedString("quit").uppercased())
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.white.opacity(0.04), lineWidth: 1)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
        .frame(width: 350, height: 400)
        .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow))
        .preferredColorScheme(.dark)
        .ignoresSafeArea()
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    @ViewBuilder
    private func toggleRow(isOn: Binding<Bool>, title: String, sub: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                Text(sub)
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.4))
            }
            Spacer()
            Toggle("", isOn: isOn)
                .toggleStyle(SwitchToggleStyle(tint: .white))
                .labelsHidden()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
    }
    
    @ViewBuilder
    private func sliderRow() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(localizedString("auto_hide_delay"))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
                Spacer()
                Text("\(Int(autoHideDelay)) \(localizedString("seconds"))")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Slider(value: $autoHideDelay, in: 3...60, step: 1)
                .accentColor(.white)
                .onChange(of: autoHideDelay) { _ in
                    NotificationCenter.default.post(name: .prefsChanged, object: nil)
                }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
    }
    
    private func localizedString(_ key: String) -> String {
        let isRussian = Locale.current.language.languageCode?.identifier == "ru" || Locale.preferredLanguages.first?.hasPrefix("ru") == true
        let dict: [String: [String: String]] = [
            "app_settings": [
                "en": "Minibar Settings",
                "ru": "Настройки Minibar"
            ],
            "system_settings": [
                "en": "System",
                "ru": "Система"
            ],
            "behavior_settings": [
                "en": "Behavior",
                "ru": "Поведение"
            ],
            "appearance_settings": [
                "en": "Appearance",
                "ru": "Внешний вид"
            ],
            "start_at_login": [
                "en": "Start at login",
                "ru": "Запуск при старте"
            ],
            "start_at_login_desc": [
                "en": "Launch Minibar when starting macOS.",
                "ru": "Запускать Minibar при входе в macOS."
            ],
            "auto_hide": [
                "en": "Auto-collapse",
                "ru": "Авто-скрытие"
            ],
            "auto_hide_desc": [
                "en": "Automatically collapse hidden menu bar items.",
                "ru": "Автоматически сворачивать скрытые иконки."
            ],
            "auto_hide_delay": [
                "en": "Delay duration",
                "ru": "Время задержки"
            ],
            "seconds": [
                "en": "sec.",
                "ru": "сек."
            ],
            "hover_to_expand": [
                "en": "Hover to expand",
                "ru": "Раскрытие наведением"
            ],
            "hover_to_expand_desc": [
                "en": "Expand items when hovering mouse over status bar.",
                "ru": "Раскрывать иконки при наведении курсора."
            ],
            "hide_separator": [
                "en": "Hide separator",
                "ru": "Скрывать разделитель"
            ],
            "hide_separator_desc": [
                "en": "Hide vertical line, show toggle arrow only.",
                "ru": "Убрать вертикальную линию, оставить только стрелку."
            ],
            "description": [
                "en": "A minimalist menu bar utility.",
                "ru": "Минималистичная утилита для строки меню."
            ],
            "quit": [
                "en": "Quit",
                "ru": "Выйти"
            ]
        ]
        return dict[key]?[isRussian ? "ru" : "en"] ?? key
    }
}
