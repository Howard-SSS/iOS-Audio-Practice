//
//  AppDelegate.swift
//  iOS-Audio-Practice
//
//  Created by Howard-Zjun on 2024/03/24.
//

import UIKit
import AVFAudio

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // 告诉app支持后台播放
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback)
            try session.setActive(true)
        } catch {
        }
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        let navi = UINavigationController(rootViewController: ViewController())
        navi.navigationBar.isHidden = true
        window.rootViewController = navi
        window.makeKeyAndVisible()
        self.window = window
        return true
        
    }
}

