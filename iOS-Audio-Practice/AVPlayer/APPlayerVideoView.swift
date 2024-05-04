//
//  APPlayerVideo.swift
//  iOS-Audio-Practice
//
//  Created by Howard-Zjun on 2024/04/28.
//

import UIKit
import AVFoundation
import MediaPlayer

open class APPlayerVideoView: UIView {
    
    var model: APPlayerVideoModel?
    
    var gestureState: GestureState = .none(startPoint: .zero)
    
    var startGestureValue: (value: Float, point: CGPoint)?
    
    var statusObservation: NSKeyValueObservation?
    
    var timeObservation: NSKeyValueObservation?
    
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
        let slider = UISlider(frame: .init(x: playTimeHintLab.maxX + 10, y: (bottomHandleView.height - 30) * 0.5, width: willPlayTimeHintLab.minX - playTimeHintLab.maxX - 10, height: 30))
        slider.addTarget(self, action: #selector(valueChangeBySlider), for: .valueChanged)
        return slider
    }()
    
    lazy var willPlayTimeHintLab: UILabel = {
        let willPlayTimeHintLab = UILabel(frame: .init(x: zoomBtn.minX - 10 - 50, y: 0, width: 50, height: bottomHandleView.height))
        willPlayTimeHintLab.font = .systemFont(ofSize: 15)
        willPlayTimeHintLab.textColor = .white
        willPlayTimeHintLab.textAlignment = .left
        willPlayTimeHintLab.text = "00:00"
        return willPlayTimeHintLab
    }()
    
    lazy var zoomBtn: UIButton = {
        let zoomBtn = UIButton(frame: .init(x: bottomHandleView.width - 10 - 30, y: (bottomHandleView.height - 30) * 0.5, width: 30, height: 30))
        zoomBtn.setImage(.init(systemName: "pip.enter"), for: .normal)
        zoomBtn.setImage(.init(systemName: "pip.exit"), for: .selected)
        zoomBtn.addTarget(self, action: #selector(touchZoomBtn), for: .touchUpInside)
        return zoomBtn
    }()
    
    lazy var sysVolumeView: MPVolumeView = {
        let sysVolumeView = MPVolumeView(frame: .init(x: width, y: height, width: 100, height: 20))
        sysVolumeView.showsVolumeSlider = false
        return sysVolumeView
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
    
    deinit {
        statusObservation?.invalidate()
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
        bottomHandleView.addSubview(willPlayTimeHintLab)
        bottomHandleView.addSubview(zoomBtn)
        
        addSubview(sysVolumeView)
    }
    
    // MARK: - target
    @objc func touchBackBtn() {
        
    }
    
    @objc func touchPlayBtn() {
        playBtn.isSelected.toggle()
        if playBtn.isSelected { // 暂停
            model?.pause()
        } else { // 播放
            model?.play()
        }
    }
    
    @objc func touchZoomBtn() {
        
    }
    
    @objc func showControlHandle(_ gesture: UITapGestureRecognizer) {
        controlHandle(isHidden: NSNumber(value: false))
    }
    
    @objc func doubleClickHandle(_ gesture: UITapGestureRecognizer) {
        guard let model = model else {
            return
        }
        if model.timeControlStatus == .playing {
            model.pause()
            playBtn.isSelected = true
        } else if model.timeControlStatus == .paused {
            model.play()
            playBtn.isSelected = false
        } else if model.timeControlStatus == .waitingToPlayAtSpecifiedRate {
            
        }
    }
    
    @objc func videoGestureHandle(_ gesture: UILongPressGestureRecognizer) {
        let state = gesture.state
        if state == .began {
            perform(#selector(rateHandle), with: nil, afterDelay: 0.2)
            let startPoint = gesture.location(in: handleView)
            gestureState = .none(startPoint: startPoint)
        } else if state == .changed {
            switch gestureState {
            case .rate:
                break
            case let .none(startPoint: startPoint):
                guard let model = model else {
                    return
                }
                if startPoint.x < (handleView.width - 100) * 0.5 {
                    startGestureValue = (Float(model.brightness), startPoint)
                    gestureState = .brightness(brightness: model.brightness, startPoint: startPoint)
                    brightnessLayer.isHidden = false
                } else if startPoint.x > (handleView.width + 100) * 0.5 {
                    startGestureValue = (model.volume, startPoint)
                    gestureState = .volume(volume: model.volume, startPoint: startPoint)
                    volumeLayer.isHidden = false
                }
            @unknown default:
                break
            }
            switch gestureState {
            case .brightness(brightness: _, startPoint: _):
                luminanceHandle(gesture)
            case .volume(volume: _, startPoint: _):
                volumeHandle(gesture)
            @unknown default:
                break
            }
        } else if state == .ended || state == .failed {
            print(gestureState)
            switch gestureState {
            case .rate:
                rateHandle()
            @unknown default:
                break
            }
            gestureState = .none(startPoint: .zero)
            startGestureValue = nil
            brightnessLayer.isHidden = true
            volumeLayer.isHidden = true
        }
    }
    
    @objc func rateHandle() {
        switch gestureState {
        case .none(startPoint: _):
            gestureState = .rate
            model?.rate = 2
            print("调整倍速：2")
        case .rate:
            model?.rate = 1
            print("调整倍速：1")
        @unknown default:
            break
        }
    }
    
    @objc func luminanceHandle(_ gesture: UILongPressGestureRecognizer) {
        print("调整亮度")
        let state = gesture.state
        if state == .began {

        } else if state == .changed {
            guard let startGestureValue = startGestureValue, let model = model else {
                return
            }
            let newPoint = gesture.location(in: handleView)
            let offsetY = newPoint.y - startGestureValue.point.y
            let offsetBrightness = offsetY / (handleView.height * 0.5)
            let value = model.controlBrightnessValue(CGFloat(startGestureValue.value) - offsetBrightness)
            self.model?.setBrightness(value)
            
            brightnessLayer.updateValue(Float(value))
        } else if state == .ended || state == .failed {
        }
    }
    
    @objc func volumeHandle(_ gesture: UILongPressGestureRecognizer) {
        print("调整音量")
        let state = gesture.state
        if state == .began {

        } else if state == .changed {
            guard let startGestureValue = startGestureValue, let model = model else {
                return
            }
            let newPoint = gesture.location(in: handleView)
            let offsetY = newPoint.y - startGestureValue.point.y
            let offsetVolume = Float(offsetY / (handleView.height * 0.5))
            let value = model.controlVolumeValue(startGestureValue.value - offsetVolume)
            self.model?.setVolume(value)
            
            volumeLayer.updateValue(value)
        } else if state == .ended || state == .failed {
        }
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
    
    @objc func valueChangeBySlider() {
        model?.duration = .init(value: CMTimeValue(slider.value), timescale: 1)
    }
    
    // MARK: -
    func setVideo(resource: APVideoResource) {
        statusObservation?.invalidate()
        timeObservation?.invalidate()
        
        let model = APPlayerVideoModel(resource: resource, volumeView: sysVolumeView)
        let playerLayer = model.playerLayer
        playerLayer.frame = bounds
        layer.insertSublayer(playerLayer, at: 0)
        self.model = model
        weak var weakSelf = self
        statusObservation = model.playerItem.observe(\.status, options: .new) { item, change in
            switch item.status {
            case .unknown:
                break
            case .readyToPlay:
                weakSelf?.configMiddleView()
                weakSelf?.configBottomView(model: model)
                weakSelf?.model?.play()
            case .failed:
                if let error = weakSelf?.model?.playerItem.error {
                    print("[\(NSStringFromClass(Self.self))]: \(error)")
                }
            @unknown default:
                break
            }
        }
        resetHiddenControlTimer()
    }
    
    func configMiddleView() {
        let showControlGesture = UITapGestureRecognizer(target: self, action: #selector(showControlHandle(_:)))
        addGestureRecognizer(showControlGesture)
        let doubleClickGesture = UITapGestureRecognizer(target: self, action: #selector(doubleClickHandle(_:)))
        doubleClickGesture.numberOfTapsRequired = 2
        addGestureRecognizer(doubleClickGesture)
    }
    
    func configBottomView(model: APPlayerVideoModel) {
        slider.minimumValue = 0
        slider.maximumValue = Float(CMTimeGetSeconds(model.duration))
        slider.value = 0
        print("影片时长：\(model.duration)")
        weak var weakSelf = self
        timeObservation = model.observe(\.playedTime, options: .new) { model, change in
            guard model.duration != .zero else {
                return
            }
            let playedTime = model.playedTime
            if let text = weakSelf?.formatText(time: playedTime) {
                weakSelf?.playTimeHintLab.text = text
            }
            let willPlayTime = model.duration - playedTime
            if let text = weakSelf?.formatText(time: willPlayTime) {
                weakSelf?.willPlayTimeHintLab.text = text
            }
            weakSelf?.slider.value = Float(CMTimeGetSeconds(playedTime))
            if let value = weakSelf?.slider.value {
                print("进度条：\(value)")
            }
        }
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

extension APPlayerVideoView {
    
    enum GestureState {
        case volume(volume: Float, startPoint: CGPoint)
        case brightness(brightness: CGFloat, startPoint: CGPoint)
        case rate
        case none(startPoint: CGPoint)
    }
}
