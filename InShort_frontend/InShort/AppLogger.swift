//
//  AppLogger.swift
//  InShort
//
//  Created by Marco Tedeschini on 21/06/25.
//


enum AppLogger {
    static func log(_ message: String) {
        #if DEBUG
        print("📘 [LOG] \(message)")
        #endif
    }

    static func error(_ message: String) {
        #if DEBUG
        print("❌ [ERROR] \(message)")
        #endif
    }
}
