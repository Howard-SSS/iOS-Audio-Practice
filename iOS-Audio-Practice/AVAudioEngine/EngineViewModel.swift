//
//  EngineViewModel.swift
//  iOS-Audio-Practice
//
//  Created by Howard-Zjun on 2024/03/28.
//

import UIKit
import AVFoundation

class EngineViewModel: NSObject {

    @objc dynamic var playerProgress: Double = 0
    
    @objc dynamic var playerTime: PlayerTime = .zero
    
    @objc dynamic var isPlaying = false
    
    var typeValue: Int = 0
    
    let typeSegmentValue: [AVAudioUnit]
    
    @objc dynamic var playbackRateIndex: Int = 1 {
        didSet {
            updateForRateSelection()
        }
    }
    
    let allPlaybackRates: [PlaybackModel] = [
        .init(value: 0.5, label: "0.5x"),
        .init(value: 1, label: "1x"),
        .init(value: 1.25, label: "1.25x"),
        .init(value: 2, label: "2x")
    ]
    
    @objc dynamic var playbackPitchIndex: Int = 3 {
        didSet {
            updateForPitchSelection()
        }
    }
    let allplaybackPitches: [PlaybackModel] = [
        .init(value: -1.5, label: "-3/2"),
        .init(value: -1, label: "-1"),
        .init(value: -0.5, label: "-1/2"),
        .init(value: 0, label: "0"),
        .init(value: 0.5, label: "+1/2"),
        .init(value: 1, label: "+1"),
        .init(value: 1.5, label: "+3/2")
    ]
    
    @objc dynamic var playbackOverlapValue: Int = 8 {
        didSet {
            updateForOverlapSelection()
        }
    }
    
    let overlapMinValue: Int = 3
    
    let overlapMaxValue: Int = 32
    
    @objc dynamic var wetDryMixIndex: Int = 4 {
        didSet {
            updateForWetDryMixSelection()
        }
    }
    
    let allWetDryMixs: [PlaybackModel] = [
        .init(value: 0, label: "0%"),
        .init(value: 25, label: "25%"),
        .init(value: 50, label: "50%"),
        .init(value: 75, label: "75%"),
        .init(value: 100, label: "100%")
    ]
    
    @objc dynamic var globalGainValue: Int = 0 {
        didSet {
            updateForGlobalGainSelection()
        }
    }
    
    let globalGainMinValue: Int = -96
    
    let globalGainMaxValue: Int = 24
    
    @objc dynamic var varispeedRateIndex: Int = 2 {
        willSet {
            updateForVarispeedRateSelection()
        }
    }
    
    let allVarispeedRates: [PlaybackModel] = [
        .init(value: 0.25, label: "0.25"),
        .init(value: 0.5, label: "0.5"),
        .init(value: 1, label: "1"),
        .init(value: 2, label: "2"),
        .init(value: 3, label: "3"),
        .init(value: 4, label: "4")
    ]
    
    // MARK: - private properties
    private var displayLink: CADisplayLink?
    private var needScheduleFile: Bool = true
    
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    // 变声单元：语速、基音偏移、音频片段重叠
    private let timeEffect = AVAudioUnitTimePitch()
    // 混响单元：干湿效果
    private let reverbEffect = AVAudioUnitReverb()
    // 速度单元
    private let varispeedEffect =  AVAudioUnitVarispeed()
    // 音量单元
    private let volumeEffect = AVAudioUnitEQ()
    
    private var audioFile: AVAudioFile?
    // 采样率
    private var audioSampleRate: Double = 0
    // 播放时长
    private var audioLengthSeconds: Double = 0
    // 样本长度
    private var audioLengthSamples: AVAudioFramePosition = 0

    private var currentPosition: AVAudioFramePosition = 0
    private var seekFrame: AVAudioFramePosition = 0
    private var currentFrame: AVAudioFramePosition {
        guard let lastRenderTime = player.lastRenderTime, let playerTime = player.playerTime(forNodeTime: lastRenderTime) else {
            return 0
        }
        return playerTime.sampleTime
    }
    
    // MARK: - public
    override init() {
        typeSegmentValue = [timeEffect, reverbEffect, varispeedEffect, volumeEffect]
        super.init()
        setupAudio()
        setupDisplayLink()
    }
    
    func playOrPause() {
        isPlaying.toggle()
        
        if player.isPlaying {
            displayLink?.isPaused = true
            disconnectVolumeTap()
            player.pause()
        } else {
            displayLink?.isPaused = false
            connectVolumeTap()
            if needScheduleFile {
                scheduleAudioFile()
            }
            player.play()
        }
    }
    
    func skip(forward: Bool) {
        let timeToSeek: Double
        if forward {
            timeToSeek = 10
        } else {
            timeToSeek = -10
        }
        seek(time: timeToSeek)
    }
    
    // MARK: - private
    private func setupAudio() {
        guard let fileUrl = Bundle.main.url(forResource: "Intro", withExtension: "mp3") else {
            return
        }
        do {
            let file = try AVAudioFile(forReading: fileUrl)
            let format = file.processingFormat
            
            audioFile = file
            audioLengthSamples = file.length
            audioSampleRate = format.sampleRate
            audioLengthSeconds = Double(audioLengthSamples) / audioSampleRate
            
            engine.attach(player)
            engine.attach(timeEffect)
            engine.attach(reverbEffect)
            engine.attach(varispeedEffect)
            engine.attach(volumeEffect)
            engine.connect(player, to: reverbEffect, format: format)
            engine.connect(reverbEffect, to: timeEffect, format: format)
            engine.connect(timeEffect, to: varispeedEffect, format: format)
            engine.connect(varispeedEffect, to: volumeEffect, format: format)
            engine.connect(volumeEffect, to: engine.mainMixerNode, format: format)
            reverbEffect.loadFactoryPreset(.largeChamber)
            engine.prepare()
            
            try engine.start()
            
            scheduleAudioFile()
        } catch {
            print("\(error)")
        }
    }
    
    private func scheduleAudioFile() {
        guard let file = audioFile else {
            return
        }
        needScheduleFile = false
        player.scheduleFile(file, at: nil) { [unowned self] in
            print("[engine] --- 调度文件完成")
            needScheduleFile = true
        }
    }
    
    private func setupDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateDisplay))
        displayLink?.add(to: .current, forMode: .default)
        displayLink?.isPaused = true
    }
    
    private func updateForRateSelection() {
        let selectedRate = allPlaybackRates[playbackRateIndex]
        timeEffect.rate = Float(selectedRate.value)
    }
    
    private func updateForOverlapSelection() {
        timeEffect.overlap = Float(playbackOverlapValue)
    }
    
    private func updateForPitchSelection() {
        let selectedPitch = allplaybackPitches[playbackPitchIndex]
        timeEffect.pitch = Float(1200 * selectedPitch.value)
    }
    
    private func updateForWetDryMixSelection() {
        let selectedWetDryMix = allWetDryMixs[wetDryMixIndex]
        reverbEffect.wetDryMix = Float(selectedWetDryMix.value) / 100.0
    }
    
    private func updateForGlobalGainSelection() {
        volumeEffect.globalGain = Float(globalGainValue)
    }
    
    private func updateForVarispeedRateSelection() {
        let selectedRate = allVarispeedRates[varispeedRateIndex]
        varispeedEffect.rate = Float(selectedRate.value)
    }
    
    private func connectVolumeTap() {
        let format = engine.mainMixerNode.outputFormat(forBus: 0)
        
        engine.mainMixerNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            
        }
    }
    
    private func disconnectVolumeTap() {
        engine.mainMixerNode.removeTap(onBus: 0)
    }
    
    @objc private func updateDisplay() {
        currentPosition = currentFrame + seekFrame
        currentPosition = max(currentPosition, 0)
        currentPosition = min(currentPosition, audioLengthSamples)
        
        if currentPosition >= audioLengthSamples {
            player.stop()
            displayLink?.isPaused = true
            
            seekFrame = 0
            currentPosition = 0
            
            isPlaying = false
            disconnectVolumeTap()
        }
        
        playerProgress = Double(currentPosition) / Double(audioLengthSamples)
        let time = Double(currentPosition) / audioSampleRate
        playerTime = .init(elapsedTime: time, remainingTime: audioLengthSeconds - time)
    }
    
    private func seek(time: Double) {
        guard let audioFile = audioFile else {
            return
        }
        let offet = AVAudioFramePosition(time * audioSampleRate)
        seekFrame = currentPosition + offet
        seekFrame = min(seekFrame, audioLengthSamples)
        seekFrame = max(seekFrame, 0)
        currentPosition = seekFrame
        
        let wasPlaying = player.isPlaying
        player.stop()
        
        if currentPosition <= audioLengthSamples {
            needScheduleFile = false
            let numberFrames: AVAudioFrameCount
            if audioLengthSamples == seekFrame {
                numberFrames = 1
            } else {
                numberFrames = AVAudioFrameCount(audioLengthSamples - seekFrame)
            }
            /*
             * 音频文件
             * 开始播放起始帧位置
             * 要播放的帧数
             */
            player.scheduleSegment(audioFile, startingFrame: seekFrame, frameCount: numberFrames, at: nil) { [unowned self] in
                needScheduleFile = true
            }
            updateDisplay()
            if wasPlaying {
                player.play()
            }
        }
    }
}
