//
//  APPlayerVideo.swift
//  iOS-Audio-Practice
//
//  Created by Howard-Zjun on 2024/04/28.
//

import UIKit
import AVFoundation
import MediaPlayer

protocol APPlayerViewDelegate: NSObject {
    
    func apPlayer(playerView: APPlayerView, stateDidChange state: APPlayerState)
    func apPlayer(playerView: APPlayerView, playTimeDidChange currentTime: CMTime, durationTime: CMTime)
    func apPlayer(playerView: APPlayerView, isPlaying: Bool)
    func apPlayer(playerView: APPlayerView, orientDidChange isFullScreen: Bool)
    func apPlayer(playerView: APPlayerView, backAction isFullScreen: Bool)
    func apPlayer(playerView: APPlayerView, systemVolumeDidChange currentVolume: CGFloat)
    func apPlayer(playerView: APPlayerView, systemBrightnessDidChange currentBrightness: CGFloat)
}

open class APPlayerView: UIView {
    
    // MARK: - 响应
    weak var delegate: APPlayerViewDelegate?
    
    var stateDidChange: ((_ state: APPlayerState) -> Void)?
    
    var playTimeDidChange: ((_ currentTime: CMTime, _ duration :CMTime) -> Void)?
    
    var isPlayingStateChange: ((_ isPlaying: Bool) -> Void)?
    
    var orientDicChange: ((_ isFullScreen: Bool) -> Void)?
    
    var backAction: ((_ isFullScreen: Bool) -> Void)?
    
    var systemVolumeDidChange: ((_ systemVolume: CGFloat) -> Void)?
    
    var systemBrightnessDidChange: ((_ systemBrightness: CGFloat) -> Void)?
    
    // MARK: - 属性
    var model: APPlayerModel?

    var isFullScreen: Bool = false
    
    // MARK: - 手势处理
    var gestureState: GestureState = .none
    
    var gestureStartValue: (value: CGFloat, point: CGPoint)?
    
    // MARK: - view
    lazy var handleView: UIView = {
        let handleView = UIView(frame: bounds)
        handleView.backgroundColor = .clear
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(videoGestureHandle(_:)))
        gesture.minimumPressDuration = 0.2
        handleView.addGestureRecognizer(gesture)
        return handleView
    }()
    
    lazy var brightnessLayer: APVideoSliderLayer = {
        let imgNames = ["sun.min", "sun.max"]
        let imgs = imgNames.map({ UIImage(systemName: $0)!.withTintColor(.black, renderingMode: .alwaysTemplate)})
        let brightnessLayer = APVideoSliderLayer(frame: .init(x: (handleView.width - 200) * 0.5, y: (handleView.height - 50) * 0.5, width: 200, height: 50), images: imgs, value: 0)
        brightnessLayer.isHidden = true
        return brightnessLayer
    }()
    
    lazy var volumeLayer: APVideoSliderLayer = {
        let imgNames = ["speaker", "speaker.wave.1", "speaker.wave.1", "speaker.wave.2", "speaker.wave.3"]
        let imgs = imgNames.map({ UIImage.init(systemName: $0)!.withTintColor(.black, renderingMode: .alwaysTemplate)})
        let volumeLayer = APVideoSliderLayer(frame: .init(x: (handleView.width - 200) * 0.5, y: (handleView.height - 50) * 0.5, width: 200, height: 50), images: imgs, value: 0)
        volumeLayer.isHidden = true
        return volumeLayer
    }()
    
    lazy var topHandleView: UIView = {
        let topHandleView = UIView(frame: .init(x: 0, y: 0, width: width, height: 50))
        topHandleView.backgroundColor = .init(hexValue: 0xFFFFFF, a: 0.2)
        return topHandleView
    }()
    
    lazy var backBtn: UIButton = {
        let backBtn = UIButton(frame: .init(x: 10, y: (topHandleView.height - 30) * 0.5, width: 30, height: 30))
        backBtn.setImage(.init(systemName: "chevron.backward"), for: .normal)
        backBtn.addTarget(self, action: #selector(touchBackBtn), for: .touchUpInside)
        return backBtn
    }()
    
    lazy var videoNameLab: UILabel = {
        let videoNameLab = UILabel(frame: .init(x: backBtn.maxX, y: 0, width: 200, height: topHandleView.height))
        videoNameLab.font = .systemFont(ofSize: 10)
        videoNameLab.textColor = .white
        videoNameLab.textAlignment = .left
        videoNameLab.lineBreakMode = .byTruncatingTail
        return videoNameLab
    }()
    
    lazy var middleHandleView: UIView = {
        let middleHandleView = UIView(frame: .init(x: 0, y: topHandleView.maxY, width: width, height: bottomHandleView.minY - topHandleView.maxY))
        middleHandleView.backgroundColor = .clear
        return middleHandleView
    }()
    
    lazy var bottomHandleView: UIView = {
        let bottomHandleView = UIView(frame: .init(x: 0, y: height - 50, width: width, height: 50))
        bottomHandleView.backgroundColor = .init(hexValue: 0xFFFFFF, a: 0.2)
        return bottomHandleView
    }()
    
    lazy var playBtn: UIButton = {
        let playBtn = UIButton(frame: .init(x: 10, y: (bottomHandleView.height - 50) * 0.5, width: 50, height: 50))
        playBtn.setImage(.init(systemName: "pause"), for: .normal)
        playBtn.setImage(.init(systemName: "play"), for: .selected)
        playBtn.addTarget(self, action: #selector(touchPlayBtn), for: .touchUpInside)
        return playBtn
    }()
    
    lazy var playTimeHintLab: UILabel = {
        let playTimeHintLab = UILabel(frame: .init(x: playBtn.maxX + 10, y: 0, width: 50, height: bottomHandleView.height))
        playTimeHintLab.font = .systemFont(ofSize: 15)
        playTimeHintLab.textColor = .white
        playTimeHintLab.textAlignment = .right
        playTimeHintLab.text = "00:00"
        return playTimeHintLab
    }()
    
    lazy var slider: UISlider = {
        let slider = UISlider(frame: .init(x: playTimeHintLab.maxX + 10, y: (bottomHandleView.height - 30) * 0.5, width: unplayTimeHintLab.minX - playTimeHintLab.maxX - 10, height: 30))
        slider.addTarget(self, action: #selector(valueChangeBySlider), for: .valueChanged)
        return slider
    }()
    
    lazy var unplayTimeHintLab: UILabel = {
        let unplayTimeHintLab = UILabel(frame: .init(x: zoomBtn.minX - 10 - 50, y: 0, width: 50, height: bottomHandleView.height))
        unplayTimeHintLab.font = .systemFont(ofSize: 15)
        unplayTimeHintLab.textColor = .white
        unplayTimeHintLab.textAlignment = .left
        unplayTimeHintLab.text = "00:00"
        return unplayTimeHintLab
    }()
    
    lazy var zoomBtn: UIButton = {
        let zoomBtn = UIButton(frame: .init(x: bottomHandleView.width - 10 - 30, y: (bottomHandleView.height - 30) * 0.5, width: 30, height: 30))
        zoomBtn.setImage(.init(systemName: "pip.enter"), for: .normal)
        zoomBtn.setImage(.init(systemName: "pip.exit"), for: .selected)
        zoomBtn.addTarget(self, action: #selector(touchZoomBtn), for: .touchUpInside)
        return zoomBtn
    }()
    
    // MARK: - life
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        configUI()
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configUI() {
        layer.masksToBounds = true
        addSubview(handleView)
        layer.insertSublayer(brightnessLayer, below: nil)
        layer.insertSublayer(volumeLayer, below: nil)
        
        addSubview(topHandleView)
        topHandleView.addSubview(backBtn)
        topHandleView.addSubview(videoNameLab)
        
        addSubview(middleHandleView)
        
        addSubview(bottomHandleView)
        bottomHandleView.addSubview(playBtn)
        bottomHandleView.addSubview(playTimeHintLab)
        bottomHandleView.addSubview(slider)
        bottomHandleView.addSubview(unplayTimeHintLab)
        bottomHandleView.addSubview(zoomBtn)
    }
    
    // MARK: - target
    @objc func touchBackBtn() {
        delegate?.apPlayer(playerView: self, backAction: isFullScreen)
        backAction?(isFullScreen)
    }
    
    @objc func touchPlayBtn() {
        playBtn.isSelected.toggle()
        if playBtn.isSelected { // 暂停
            model?.pause()
        } else { // 播放
            model?.play()
        }
        
        weak var weakSelf = self
        guard let self = weakSelf else {
            return
        }
        if playBtn.isSelected {
            delegate?.apPlayer(playerView: self, isPlaying: false)
            isPlayingStateChange?(false)
        } else {
            
            delegate?.apPlayer(playerView: self, isPlaying: true)
            isPlayingStateChange?(true)
        }
    }
    
    @objc func touchZoomBtn() {
        isFullScreen.toggle()
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate, let windowScene = appDelegate.window?.screen as? UIWindowScene else {
            return
        }
        
        weak var weakSelf = self
        guard let self = weakSelf else {
            return
        }
        if isFullScreen {
            delegate?.apPlayer(playerView: self, orientDidChange: true)
            orientDicChange?(true)
        } else {
            delegate?.apPlayer(playerView: self, orientDidChange: false)
            orientDicChange?(false)
        }
    }
    
    // MARK: - 展开手势识别
    @objc func showControlHandle(_ gesture: UITapGestureRecognizer) {
        controlHandle(isHidden: NSNumber(value: false))
    }
    
    @objc func controlHandle(isHidden: NSNumber) {
        UIView.animate(withDuration: 1) {
            if isHidden.boolValue {
                self.topHandleView.alpha = 0
                self.middleHandleView.alpha = 0
                self.bottomHandleView.alpha = 0
            } else {
                self.topHandleView.alpha = 1
                self.middleHandleView.alpha =  1
                self.bottomHandleView.alpha = 1
            }
        } completion: { _ in
            if !isHidden.boolValue {
                self.resetHiddenControlTimer()
            }
        }
    }
    
    // MARK: - 视频开启/暂停手势识别
    @objc func doubleClickHandle(_ gesture: UITapGestureRecognizer) {
        touchPlayBtn()
    }
    
    // MARK: - 手势识别，系统音量、系统亮度、倍速
    @objc func videoGestureHandle(_ gesture: UILongPressGestureRecognizer) {
        let state = gesture.state
        if state == .began {
            // 延迟0.1s触发，手势状态仍是none，作为变速手势处理
            perform(#selector(rateHandle), with: NSNumber(value: true), afterDelay: 0.1)
            let startPoint = gesture.location(in: handleView)
            gestureStartValue = (0, startPoint)
        } else if state == .changed {
            if gestureState == .rate {
                return
            } else if gestureState == .none {
                guard let model = model, let gestureStartValue = gestureStartValue else {
                    return
                }
                if gestureStartValue.point.x < (handleView.width - 100) * 0.5 {
                    self.gestureStartValue = (model.bridgeBrightness, gestureStartValue.point)
                    gestureState = .brightness
                    brightnessLayer.isHidden = false
                } else if gestureStartValue.point.x > (handleView.width + 100) * 0.5 {
                    self.gestureStartValue = (model.bridgeVolume, gestureStartValue.point)
                    gestureState = .volume
                    volumeLayer.isHidden = false
                }
            }
            
            let newPoint = gesture.location(in: handleView)
            if gestureState == .volume {
                volumeHandle(newPoint: newPoint)
            } else if gestureState == .brightness {
                brightnessHandle(newPoint: newPoint)
            }
        } else if state == .ended || state == .failed {
            if gestureState == .rate {
                rateHandle(isSpeedUp: .init(value: false))
            } else if gestureState == .volume {
                endVolumeHandle()
            } else if gestureState == .brightness {
                endBrightnessHandle()
            }
        }
    }
    
    @objc func rateHandle(isSpeedUp: NSNumber) {
        if isSpeedUp.boolValue {
            if gestureState == .none {
                gestureState = .rate
            } else {
                return
            }
            model?.rate = 2
            print("调整倍速：2")
        } else {
            model?.rate = 1
            print("调整倍速：1")
        }
    }
    
    @objc func brightnessHandle(newPoint: CGPoint) {
        print("调整亮度")
        guard let gestureStartValue = gestureStartValue, let model = model else {
            return
        }
        let offsetY = newPoint.y - gestureStartValue.point.y
        let offsetBrightness = offsetY / (handleView.height * 0.5)
        let value = model.controlBrightnessValue(CGFloat(gestureStartValue.value) - offsetBrightness)
        self.model?.bridgeBrightness = value
        
        brightnessLayer.updateValue(Float(value))
    }
    
    func endBrightnessHandle() {
        gestureStartValue = nil
        gestureState = .none
        brightnessLayer.isHidden = true
    }
    
    @objc func volumeHandle(newPoint: CGPoint) {
        print("调整音量")
        guard let gestureStartValue = gestureStartValue, let model = model else {
            return
        }
        let offsetY = newPoint.y - gestureStartValue.point.y
        let offsetVolume = Float(offsetY / (handleView.height * 0.5))
        let value = model.controlVolumeValue(gestureStartValue.value - CGFloat(offsetVolume))
        self.model?.bridgeVolume = value
        
        volumeLayer.updateValue(Float(value))
    }
    
    func endVolumeHandle() {
        gestureStartValue = nil
        gestureState = .none
        volumeLayer.isHidden = true
    }
    
    // MARK: - 进度条手动变更
    @objc func valueChangeBySlider() {
        model?.update(playedTime: .init(value: CMTimeValue(slider.value), timescale: 1))
    }
    
    // MARK: - 配置数据
    func setVideo(resource: APVideoResource) {
        let model = APPlayerModel(resource: resource)
        model.delegate = self
        let playerLayer = model.playerLayer
        playerLayer.frame = bounds
        layer.insertSublayer(playerLayer, at: 0)
        self.model?.delegate = nil
        self.model = model
        resetHiddenControlTimer()
    }
    
    func configTopView(model: APPlayerModel) {
        videoNameLab.text = model.name
    }
    
    func configMiddleView() {
        let showControlGesture = UITapGestureRecognizer(target: self, action: #selector(showControlHandle(_:)))
        addGestureRecognizer(showControlGesture)
        let doubleClickGesture = UITapGestureRecognizer(target: self, action: #selector(doubleClickHandle(_:)))
        doubleClickGesture.numberOfTapsRequired = 2
        addGestureRecognizer(doubleClickGesture)
    }
    
    func configBottomView(model: APPlayerModel) {
        slider.minimumValue = 0
        slider.maximumValue = Float(CMTimeGetSeconds(model.duration))
        slider.value = 0
        print("影片时长：\(model.duration)")
    }
    
    func resetHiddenControlTimer() {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        perform(#selector(controlHandle(isHidden:)), with: NSNumber(value: true), afterDelay: 2)
    }
    
    func formatText(time: CMTime) -> String {
        var second = Int(floor(CMTimeGetSeconds(time)))
        let hours = second / 3600
        second %= 3600
        let minutes = second / 60
        second %= 60
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, second)
        } else if minutes > 0 {
            return String(format: "%02d:%02d", minutes, second)
        } else {
            return String(format: "00:%02d", second)
        }
    }
}

extension APPlayerView {
    
    enum GestureState {
        case volume
        case brightness
        case rate
        case none
    }
}

extension APPlayerView: APPlayerModelDelegate {
    
    func apPlayer(playerModel: APPlayerModel, stateDidChange state: APPlayerState, error: (any Error)?) {
        if playerModel != model {
            return
        }
        
        switch state {
        case .unknown:
            break
        case .readyToPlay:
            configTopView(model: playerModel)
            configMiddleView()
            configBottomView(model: playerModel)
            model?.play()
        case .playToEnd:
            break
        case .error:
            if let error = error {
                NSObject.formatPrint(text: error.localizedDescription)
            }
        }
        
        weak var weakSelf = self
        guard let self = weakSelf else {
            return
        }
        delegate?.apPlayer(playerView: self, stateDidChange: state)
        stateDidChange?(state)
    }
    
    func apPlayer(playerModel: APPlayerModel, playTimeDidChange currentTime: CMTime, durationTime: CMTime) {
        if playerModel != model {
            return
        }
        
        playTimeHintLab.text = formatText(time: currentTime)
        
        let unplayTime = durationTime - currentTime
        unplayTimeHintLab.text = formatText(time: unplayTime)
        
        slider.value = Float(CMTimeGetSeconds(currentTime))
        
        print("进度条：\(slider.value)")
        
        delegate?.apPlayer(playerView: self, playTimeDidChange: currentTime, durationTime: durationTime)
        playTimeDidChange?(currentTime, durationTime)
    }
    
    
    func apPlayer(playerModel: APPlayerModel, systemVolumeDidChange currentVolume: CGFloat) {
        weak var weakSelf = self
        guard let self = weakSelf else {
            return
        }
        
        delegate?.apPlayer(playerView: self, systemVolumeDidChange: currentVolume)
        systemVolumeDidChange?(currentVolume)
    }
    
    func apPlayer(playerModel: APPlayerModel, systemBrightnessDidChange currentBrightness: CGFloat) {
        weak var weakSelf = self
        guard let self = weakSelf else {
            return
        }
        
        delegate?.apPlayer(playerView: self, systemBrightnessDidChange: currentBrightness)
        systemBrightnessDidChange?(currentBrightness)
    }
}
