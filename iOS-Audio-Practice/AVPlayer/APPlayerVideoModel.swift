//
//  APPlayerVideoModel.swift
//  iOS-Audio-Practice
//
//  Created by Howard-Zjun on 2024/04/28.
//

import UIKit
import AVFoundation
import AVFAudio
import MediaPlayer

class APPlayerVideoModel: NSObject {

    private let name: String
    
    private let url: URL
    
    let playerItem: AVPlayerItem
    
    private let player: AVPlayer
    
    let playerLayer: AVPlayerLayer
        
    var slider: UISlider?
    
    var screen: UIScreen? {
        didSet {
            brightnessObservation?.invalidate()
            if screen != nil {
                weak var weakSelf = self
                brightnessObservation = observe(\.screen!.brightness, options: .new) { observing, change in
                    weakSelf?.systemBrightnessDidChange()
                }
            }
        }
    }
    
    static let defaultBrightness: CGFloat = 0.5
    
    static let defaultVolume: Float = 0.3
    
    var timeControlStatus: AVPlayer.TimeControlStatus {
        player.timeControlStatus
    }
    
    var duration: CMTime {
        set {
            player.seek(to: newValue, toleranceBefore: .zero, toleranceAfter: .zero)
        }
        get {
            playerItem.duration
        }
    }
    
    // MARK: - 观察者对象
    private var brightnessObservation: NSKeyValueObservation?
    
    private var statusObservation: NSKeyValueObservation?

    private var scheduleObservation: Any?
    
    // MARK: - 可以被观察属性
    @objc dynamic var playedTime: CMTime = .zero
    
    @objc dynamic var brightness: CGFloat
    
    @objc dynamic var volume: Float
    
    // MARK: - 计算属性
    var rate: Float {
        set {
            if player.rate == newValue {
                return
            }
            player.rate = newValue
            print("rate: \(newValue)")
        }
        get {
            player.rate
        }
    }
    
    var videoGravity: AVLayerVideoGravity {
        set {
            if playerLayer.videoGravity == newValue {
                return
            }
            playerLayer.videoGravity = newValue
            print("videoGravity: \(newValue)")
        }
        get {
            playerLayer.videoGravity
        }
    }
    
    // MARK: - life
    init(resource: APVideoResource, volumeView: MPVolumeView) {
        name = resource.name
        url = resource.url
        playerItem = .init(url: url)
        player = .init(playerItem: playerItem)
        playerLayer = .init(player: player)
        playerLayer.videoGravity = .resizeAspect
        
        for subView in volumeView.subviews {
            if subView.self.description == "MPVolumeSlider" {
                slider = subView as? UISlider
            }
        }
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        self.screen = appDelegate.window?.windowScene?.screen
        
        self.brightness = screen?.brightness ?? APPlayerVideoModel.defaultBrightness
        volume = AVAudioSession.sharedInstance().outputVolume
        volume = slider?.value ?? APPlayerVideoModel.defaultVolume
        super.init()
        // 添加观察者
        weak var weakSelf = self
        statusObservation = playerItem.observe(\.status, options: .new) { item, change in
            print("[\(NSStringFromClass(Self.self))]: \(item.status)")
            switch item.status {
            case .unknown:
                break
            case .readyToPlay:
                break
            case .failed:
                break
            @unknown default:
                break
            }
        }
        NotificationCenter.default.addObserver(self, selector: #selector(systemVolumeDidChange(_:)), name: .init("AVSystemController_SystemVolumeDidChangeNotification"), object: nil)
        scheduleObservation = player.addPeriodicTimeObserver(forInterval: .init(value: 1, timescale: 1), queue: .main, using: { time in
            guard let duration = weakSelf?.duration, duration != .zero else {
                return
            }
            weakSelf?.playedTime = time
        })
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        brightnessObservation?.invalidate()
        statusObservation?.invalidate()
        if let scheduleObservation = scheduleObservation {
            player.removeTimeObserver(scheduleObservation)
        }
    }
    
    func play() {
        player.play()
    }
    
    func pause() {
        player.pause()
    }
    
    // MARK: - target
    @objc func systemVolumeDidChange(_ info: Notification) {
        if let volume = info.userInfo?["AVSystemController_SystemVolumeDidChangeNotification"] as? Float {
            self.volume = volume
        }
    }
    
    @objc func systemBrightnessDidChange() {
        if let brightness = screen?.brightness {
            self.brightness = brightness
        }
    }
    
    func setVolume(_ volume: Float) {
        let volume = controlVolumeValue(volume)
        self.volume = volume
        updateSystemVolume(volume)
    }
    
    func setBrightness(_ brightness: CGFloat) {
        let brightness = controlBrightnessValue(brightness)
        self.brightness = brightness
        updateSystemBrightness(brightness)
    }
    
    private func updateSystemVolume(_ volume: Float) {
        slider?.value = volume
    }
    
    private func updateSystemBrightness(_ brightness: CGFloat) {
        screen?.brightness = brightness
    }
    
    func controlVolumeValue(_ volume: Float) -> Float {
        var volume = volume
        if volume < 0 {
            volume = 0
        } else if volume > 1 {
            volume = 1
        }
        return volume
    }
    
    func controlBrightnessValue(_ brightness: CGFloat) -> CGFloat {
        var brightness = brightness
        if brightness < 0 {
            brightness = 0
        } else if brightness > 1 {
            brightness = 1
        }
        return brightness
    }
}
