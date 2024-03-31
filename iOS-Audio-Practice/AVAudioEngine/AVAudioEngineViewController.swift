//
//  AVAudioEngineViewController.swift
//  iOS-Audio-Practice
//
//  Created by Howard-Zjun on 2024/03/27.
//

import UIKit
import AVFAudio

class AVAudioEngineViewController: UIViewController {
    
    var viewModel = EngineViewModel()
    
    var sliderKVO: NSKeyValueObservation?
    
    var playBtnKVO: NSKeyValueObservation?
    
    lazy var imgView: UIImageView = {
        let imgView = UIImageView(frame: .init(x: 15, y: 90, width: view.width - 30, height: 150))
        imgView.backgroundColor = .gray
        return imgView
    }()
    
    lazy var controlView: UIView = {
        let controlView = UIView(frame: .init(x: 15, y: imgView.maxY + 20, width: view.width - 30, height: view.height - imgView.maxY - 20 - 20))
        controlView.backgroundColor = .clear
        return controlView
    }()
    
    lazy var slider: UISlider = {
        let slider = UISlider(frame: .init(x: 0, y: 0, width: controlView.width, height: 10))
        slider.minimumTrackTintColor = .init(hexValue: 0x016736)
        slider.maximumTrackTintColor = .init(hexValue: 0xC3C3C3)
        slider.thumbTintColor = .clear
        slider.isUserInteractionEnabled = false
        sliderKVO = viewModel.observe(\.playerProgress, options: .new) { _, change in
            guard let newValue = change.newValue else {
                return
            }
            slider.value = Float(newValue)
        }
        return slider
    }()
    
    lazy var playBtn: UIButton = {
        let playBtn = UIButton(frame: .init(x: (controlView.width - 43) * 0.5, y: slider.maxY + 50, width: 40, height: 40))
        playBtn.setImage(.playImg, for: .normal)
        playBtn.setImage(.pausImge, for: .selected)
        playBtn.tintColor = .black
        playBtn.addTarget(self, action: #selector(touchPlayBtn), for: .touchUpInside)
        playBtnKVO = viewModel.observe(\.isPlaying, options: .new, changeHandler: { _, change in
            guard let newValue = change.newValue else {
                return
            }
            playBtn.isSelected = newValue
        })
        return playBtn
    }()
    
    lazy var backwardBtn: UIButton = {
        let backwardBtn = UIButton(frame: .init(x: (playBtn.minX - 40) * 0.5, y: slider.maxY + 50, width: 40, height: 40))
        backwardBtn.setImage(.backwardImg, for: .normal)
        backwardBtn.addTarget(self, action: #selector(touchBackwardBtn), for: .touchUpInside)
        backwardBtn.tintColor = .black
        return backwardBtn
    }()
    
    lazy var forwardBtn: UIButton = {
        let forwardBtn = UIButton(frame: .init(x: playBtn.maxX + (controlView.width - playBtn.maxX - 40) * 0.5, y: slider.maxY + 50, width: 40, height: 40))
        forwardBtn.setImage(.forwardImg, for: .normal)
        forwardBtn.addTarget(self, action: #selector(touchForwardBtn), for: .touchUpInside)
        forwardBtn.tintColor = .black
        return forwardBtn
    }()
    
    lazy var typeSegmentControl: UISegmentedControl = {
        let typeSegmentControl = UISegmentedControl(items: viewModel.typeSegmentValue.map({ unit in
            NSStringFromClass(unit.classForCoder)
        }))
        typeSegmentControl.frame = .init(x: 0, y: playBtn.maxY + 20, width: controlView.width, height: 30)
        typeSegmentControl.addTarget(self, action: #selector(typeSegmentChange), for: .valueChanged)
        typeSegmentControl.selectedSegmentIndex = viewModel.typeValue
        return typeSegmentControl
    }()
    
    lazy var timePitchView: UIView = {
        let timepitchView = UIView(frame: .init(x: 0, y: typeSegmentControl.maxY + 20, width: controlView.width, height: controlView.height - typeSegmentControl.maxY - 20))
        timepitchView.backgroundColor = .clear
        return timepitchView
    }()
    
    lazy var rateSegment: UISegmentedControl = {
        let rateSegment = UISegmentedControl(items: viewModel.allPlaybackRates.map({$0.label}))
        rateSegment.frame = .init(x: 0, y: 0, width: timePitchView.width, height: 30)
        rateSegment.addTarget(self, action: #selector(rateSegmentChange), for: .valueChanged)
        rateSegment.tintColor = .black
        rateSegment.selectedSegmentIndex = viewModel.playbackRateIndex
        return rateSegment
    }()
    
    lazy var pitchSegment: UISegmentedControl = {
        let pitchSegment = UISegmentedControl(items: viewModel.allplaybackPitches.map({$0.label}))
        pitchSegment.frame = .init(x: 0, y: rateSegment.maxY + 50, width: timePitchView.width, height: 30)
        pitchSegment.addTarget(self, action: #selector(pitchSegmentChange), for: .valueChanged)
        pitchSegment.tintColor = .black
        pitchSegment.selectedSegmentIndex = viewModel.playbackPitchIndex
        return pitchSegment
    }()
    
    lazy var overlapSlider: UISlider = {
        let overlapSlider = UISlider(frame: .init(x: 0, y: pitchSegment.maxY + 50, width: timePitchView.width, height: 10))
        overlapSlider.minimumValue = Float(viewModel.overlapMinValue)
        overlapSlider.maximumValue = Float(viewModel.overlapMaxValue)
        overlapSlider.value = Float(viewModel.playbackOverlapValue)
        overlapSlider.minimumTrackTintColor = .black
        overlapSlider.maximumTrackTintColor = .init(hexValue: 0xC3C3C3)
        overlapSlider.thumbTintColor = .init(hexValue: 0xC3C3C3)
        overlapSlider.addTarget(self, action: #selector(overlapSliderChange), for: .valueChanged)
        return overlapSlider
    }()
    
    lazy var overlapHintLab: UILabel = {
        let overlapHintLab = UILabel(frame: .init(x: 0, y: overlapSlider.minY - 20, width: 30, height: 20))
        overlapHintLab.text = "\(viewModel.playbackOverlapValue)"
        overlapHintLab.textColor = .black
        overlapHintLab.textAlignment = .left
        return overlapHintLab
    }()
    
    lazy var reverbView: UIView = {
        let reverbView = UIView(frame: .init(x: 0, y: timePitchView.minY, width: controlView.width, height: controlView.height - timePitchView.minY))
        reverbView.backgroundColor = .clear
        return reverbView
    }()
    
    lazy var wetDryMixSegment: UISegmentedControl = {
        let wetDryMixSegment = UISegmentedControl(items: viewModel.allWetDryMixs.map({$0.label}))
        wetDryMixSegment.frame = .init(x: 0, y: 0, width: reverbView.width, height: 30)
        wetDryMixSegment.addTarget(self, action: #selector(wetDryMixChange), for: .valueChanged)
        wetDryMixSegment.tintColor = .black
        wetDryMixSegment.selectedSegmentIndex = viewModel.wetDryMixIndex
        return wetDryMixSegment
    }()
    
    lazy var EQView: UIView = {
        let volumeView = UIView(frame: .init(x: 0, y: timePitchView.minY, width: controlView.width, height: controlView.height - timePitchView.minY))
        volumeView.backgroundColor = .clear
        return volumeView
    }()
    
    lazy var globalGainSlider: UISlider = {
        let globalGainSlider = UISlider(frame: .init(x: 0, y: 0, width: EQView.width, height: 30))
        globalGainSlider.minimumValue = Float(viewModel.globalGainMinValue)
        globalGainSlider.maximumValue = Float(viewModel.globalGainMaxValue)
        globalGainSlider.value = Float(viewModel.globalGainValue)
        globalGainSlider.minimumTrackTintColor = .black
        globalGainSlider.maximumTrackTintColor = .init(hexValue: 0xC3C3C3)
        globalGainSlider.thumbTintColor = .init(hexValue: 0xC3C3C3)
        globalGainSlider.addTarget(self, action: #selector(globalGainSliderChange), for: .valueChanged)
        return globalGainSlider
    }()
    
    lazy var globalGainHintLab: UILabel = {
        let globalGainHintLab = UILabel(frame: .init(x: 0, y: globalGainSlider.minY - 20, width: 30, height: 20))
        globalGainHintLab.text = "\(viewModel.globalGainValue)"
        globalGainHintLab.textColor = .black
        globalGainHintLab.textAlignment = .left
        return globalGainHintLab
    }()
    
    lazy var varispeedView: UIView = {
        let varispeedView = UIView(frame: .init(x: 0, y: timePitchView.minY, width: controlView.width, height: controlView.height - timePitchView.minY))
        varispeedView.backgroundColor = .clear
        return varispeedView
    }()
    
    lazy var varispeedRateSegment: UISegmentedControl = {
        let varispeedRateSegment = UISegmentedControl(items: viewModel.allVarispeedRates.map({$0.label}))
        varispeedRateSegment.frame = .init(x: 0, y: 0, width: varispeedView.width, height: 30)
        varispeedRateSegment.addTarget(self, action: #selector(varispeedRateChange), for: .valueChanged)
        varispeedRateSegment.tintColor = .black
        varispeedRateSegment.selectedSegmentIndex = viewModel.varispeedRateIndex
        return varispeedRateSegment
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(imgView)
        view.addSubview(controlView)
        controlView.addSubview(slider)
        controlView.addSubview(playBtn)
        controlView.addSubview(forwardBtn)
        controlView.addSubview(backwardBtn)
        controlView.addSubview(typeSegmentControl)
        
        for (index, unit) in viewModel.typeSegmentValue.enumerated() {
            if unit.isKind(of: AVAudioUnitTimePitch.self) {
                timePitchView.tag = index
                controlView.addSubview(timePitchView)
                timePitchView.addSubview(rateSegment)
                timePitchView.addSubview(pitchSegment)
                timePitchView.addSubview(overlapSlider)
                timePitchView.addSubview(overlapHintLab)
            } else if unit.isKind(of: AVAudioUnitReverb.self) {
                reverbView.tag = index
                controlView.addSubview(reverbView)
                reverbView.addSubview(wetDryMixSegment)
            } else if unit.isKind(of: AVAudioUnitEQ.self) {
                EQView.tag = index
                controlView.addSubview(EQView)
                EQView.addSubview(globalGainSlider)
                EQView.addSubview(globalGainHintLab)
            } else if unit.isKind(of: AVAudioUnitVarispeed.self) {
                varispeedView.tag = index
                controlView.addSubview(varispeedView)
                varispeedView.addSubview(varispeedRateSegment)
            }
        }
        
        typeSegmentChange()
    }
    
    deinit {
        sliderKVO?.invalidate()
        sliderKVO = nil
        playBtnKVO?.invalidate()
        playBtnKVO = nil
    }
    
    @objc func touchPlayBtn() {
        viewModel.playOrPause()
    }
    
    @objc func touchForwardBtn() {
        viewModel.skip(forward: true)
    }
    
    @objc func touchBackwardBtn() {
        viewModel.skip(forward: false)
    }
    
    @objc func typeSegmentChange() {
        viewModel.typeValue = typeSegmentControl.selectedSegmentIndex
        timePitchView.isHidden = timePitchView.tag != viewModel.typeValue
        reverbView.isHidden = reverbView.tag != viewModel.typeValue
        EQView.isHidden = EQView.tag != viewModel.typeValue
        varispeedView.isHidden = varispeedView.tag != viewModel.typeValue
    }
    
    @objc func rateSegmentChange() {
        viewModel.playbackRateIndex = rateSegment.selectedSegmentIndex
    }
    
    @objc func pitchSegmentChange() {
        viewModel.playbackPitchIndex = pitchSegment.selectedSegmentIndex
    }
    
    @objc func overlapSliderChange() {
        viewModel.playbackOverlapValue = Int(overlapSlider.value)
        updateOverlapHint()
    }
    
    func updateOverlapHint() {
        overlapHintLab.text = "\(Int(overlapSlider.value))"
    }
    
    @objc func wetDryMixChange() {
        viewModel.wetDryMixIndex = wetDryMixSegment.selectedSegmentIndex
    }
    
    @objc func globalGainSliderChange() {
        viewModel.globalGainValue = Int(globalGainSlider.value)
        updateGlobalGainHint()
    }
    
    func updateGlobalGainHint() {
        globalGainHintLab.text = "\(Int(globalGainSlider.value))"
    }
    
    @objc func varispeedRateChange() {
        viewModel.varispeedRateIndex = varispeedRateSegment.selectedSegmentIndex
    }
}
