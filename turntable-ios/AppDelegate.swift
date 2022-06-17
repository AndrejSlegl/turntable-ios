//
//  AppDelegate.swift
//  turntable-ios
//
//  Created by User on 11/06/2022.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    private func configureDefaultSettings() {
        let settings = AppSettings.shared
        if settings.turntableHost == nil {
            settings.turntableHost = "192.168.1.172"
        }
        if settings.turntablePort <= 0 {
            settings.turntablePort = 840
        }
        if settings.turntableSteps <= 0 {
            settings.turntableSteps = 70
        }
        if settings.cameraZoom <= 1 {
            settings.cameraZoom = 1
        }
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        configureDefaultSettings()
        UIApplication.shared.isIdleTimerDisabled = true
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

