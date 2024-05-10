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

enum APPlayerState {
    case unknown
    case readyToPlay
    case playToEnd
    case error
}

protocol APPlayerModelDelegate: NSObject {
    
    func apPlayer(playerModel: APPlayerModel, stateDidChange state: APPlayerState, error: Error?)
    func apPlayer(playerModel: APPlayerModel, playTimeDidChange currentTime: CMTime, durationTime: CMTime)
    func apPlayer(playerModel: APPlayerModel, systemVolumeDidChange currentVolume: CGFloat)
    func apPlayer(playerModel: APPlayerModel, systemBrightnessDidChange currentBrightness: CGFloat)
}

class APPlayerModel: NSObject {
    
    // MARK: - 响应
    weak var delegate: APPlayerModelDelegate?
    
    var stateDidChange: ((APPlayerState, Error?) -> Void)?
    
    var playTimeDidChange: ((CMTime, CMTime) -> Void)?
    
    var systemVolumeDidChange: ((CGFloat) -> Void)?
    
    var systemBrightnessDidChange: ((CGFloat) -> Void)?
                                   
    // MARK: - 属性
    let name: String
    
    let url: URL
    
    let playerItem: AVPlayerItem
    
    let player: AVPlayer
    
    let playerLayer: AVPlayerLayer
        
    // 控制系统音量
    var volumeSlider: UISlider?
    
    // 控制屏幕亮度
    var screen: UIScreen? {
        didSet {
            brightnessObservation?.invalidate()
            if screen != nil {
                weak var weakSelf = self
                brightnessObservation = observe(\.screen!.brightness, options: .new) { observing, change in
                    weakSelf?.systemBrightnessDidChangeHandle()
                }
            }
        }
    }
    
    var timeControlStatus: AVPlayer.TimeControlStatus {
        player.timeControlStatus
    }
    
    var duration: CMTime {
        playerItem.duration
    }
    
    private var playedTime: CMTime = .zero
    
    private var brightness: CGFloat
    
    private var volume: CGFloat
    
    // MARK: - 观察者对象
    /// 系统亮度观察
    private var brightnessObservation: NSKeyValueObservation?
    
    /// 播放状态观察
    private var statusObservation: NSKeyValueObservation?

    /// 播放进度观察
    private var scheduleObservation: Any?
    
    // MARK: - 计算属性
    var bridgeBrightness: CGFloat {
        set {
            let brightness = controlBrightnessValue(newValue)
            self.brightness = brightness
            screen?.brightness = brightness
        }
        get {
            brightness
        }
    }
    
    var bridgeVolume: CGFloat {
        set {
            let volume = controlVolumeValue(newValue)
            self.volume = volume
            volumeSlider?.value = Float(volume)
        }
        get {
            volume
        }
    }
    
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
    init(resource: APVideoResource) {
        name = resource.name
        url = resource.url
        playerItem = .init(url: url)
        player = .init(playerItem: playerItem)
        playerLayer = .init(player: player)
        playerLayer.videoGravity = .resizeAspect
        
        let volumeView = MPVolumeView()
        for view in volumeView.subviews {
            if let slider = view as? UISlider {
                volumeSlider = slider
            }
        }
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        self.screen = appDelegate.window?.windowScene?.screen
        
        if let systemBrightness = screen?.brightness {
            brightness = systemBrightness
        } else {
            brightness = APPlayerModel.defaultBrightness
        }
        
        if let systemVolume = volumeSlider?.value {
            volume = CGFloat(systemVolume)
        } else {
            volume = APPlayerModel.defaultVolume
        }
        
        super.init()
        
        // 添加播放状态观察者
        statusObservation = playerItem.observe(\.status, options: .new) { [weak self] item, change in
            APPlayerModel.formatPrint(text: "\(item.status)")
            
            guard let self = self else {
                return
            }
            
            switch item.status {
            case .unknown:
                delegate?.apPlayer(playerModel: self, stateDidChange: .unknown, error: nil)
                stateDidChange?(.unknown, nil)
            case .readyToPlay:
                delegate?.apPlayer(playerModel: self, stateDidChange: .readyToPlay, error: nil)
                stateDidChange?(.readyToPlay, nil)
            case .failed:
                delegate?.apPlayer(playerModel: self, stateDidChange: .error, error: item.error)
                stateDidChange?(.error, item.error)
            @unknown default:
                break
            }
        }
        
        // 添加系统音量观察者
        NotificationCenter.default.addObserver(self, selector: #selector(systemVolumeDidChangeHandle(_:)), name: .init("AVSystemController_SystemVolumeDidChangeNotification"), object: nil)
        
        // 添加播放进度观察者
        scheduleObservation = player.addPeriodicTimeObserver(forInterval: .init(value: 1, timescale: 1), queue: .main, using: { [weak self] time in
            guard let self = self, duration != .zero else {
                return
            }
            
            playedTime = time
            
            delegate?.apPlayer(playerModel: self, playTimeDidChange: time, durationTime: duration)
            playTimeDidChange?(time, duration)
            
            if time >= duration {
                delegate?.apPlayer(playerModel: self, stateDidChange: .playToEnd, error: nil)
                stateDidChange?(.playToEnd, nil)
            }
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
    
    func update(playedTime: CMTime) {
        player.seek(to: playedTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    // MARK: - target
    @objc func systemVolumeDidChangeHandle(_ info: Notification) {
        if let volume = info.userInfo?["AVSystemController_SystemVolumeDidChangeNotification"] as? CGFloat {
            self.volume = volume
            
            weak var weakSelf = self
            guard let self = weakSelf else {
                return
            }
            delegate?.apPlayer(playerModel: self, systemVolumeDidChange: volume)
            systemVolumeDidChange?(volume)
        }
    }
    
    @objc func systemBrightnessDidChangeHandle() {
        if let brightness = screen?.brightness {
            self.brightness = brightness
            
            weak var weakSelf = self
            guard let self = weakSelf else {
                return
            }
            delegate?.apPlayer(playerModel: self, systemBrightnessDidChange: brightness)
            systemBrightnessDidChange?(brightness)
        }
    }
    
    // MARK: - 参数大小限制
    // 音量大小范围限制
    func controlVolumeValue(_ volume: CGFloat) -> CGFloat {
        var volume = volume
        if volume < 0 {
            volume = 0
        } else if volume > 1 {
            volume = 1
        }
        return volume
    }
    
    // 亮度大小范围限制
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

extension APPlayerModel {
    
    static let defaultBrightness: CGFloat = 0.5
    
    static let defaultVolume: CGFloat = 0.3
}
