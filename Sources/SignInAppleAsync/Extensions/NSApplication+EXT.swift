//
//  NSApplication+EXT.swift
//  SignInAppleAsync
//
//  Created by Valentine Zubkov on 30.04.2025.
//

#if os(macOS)

import AppKit

extension NSApplication {
    static func topViewController() -> NSViewController? {
        let window = NSApplication.shared.windows.first { $0.isKeyWindow } ?? NSApplication.shared.windows.first
        return window?.contentViewController
    }
}

#endif
