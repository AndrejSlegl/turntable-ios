//
//  AppSettings.swift
//  turntable-ios
//
//  Created by User on 15/06/2022.
//

import Foundation

class AppSettings {
    static let shared = AppSettings()
    
    private let userDefaults = UserDefaults.standard
    
    var turntableHost: String? {
        get { userDefaults.string(forKey: "turntableHost") }
        set { userDefaults.set(newValue, forKey: "turntableHost") }
    }
    
    var turntablePort: Int {
        get { userDefaults.integer(forKey: "turntablePort") }
        set { userDefaults.set(newValue, forKey: "turntablePort") }
    }
    
    var turntableSteps: Int {
        get { userDefaults.integer(forKey: "turntableSteps") }
        set { userDefaults.set(newValue, forKey: "turntableSteps") }
    }
    
    var cameraZoom: Float {
        get { userDefaults.float(forKey: "cameraZoom") }
        set { userDefaults.set(newValue, forKey: "cameraZoom") }
    }
}
