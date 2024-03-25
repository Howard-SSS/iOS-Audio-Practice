//
//  AVPlayerViewController.swift
//  iOS-Audio-Practice
//
//  Created by Howard-Zjun on 2024/03/24.
//

import UIKit
import AVFoundation

class AVPlayerViewController: UIViewController {

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .init(x: 0, y: 0, width: view.width * 0.5, height: view.height * 0.5))
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: NSStringFromClass(UITableViewCell.self))
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()
    
    lazy var timeLab: UILabel = {
        let timeLab = UILabel(frame: .init(x: 0, y: slider.minY - 10 - 20, width: view.width, height: 20))
        timeLab.textColor = .black
        timeLab.text = "00:00/00:00"
        timeLab.textAlignment = .center
        return timeLab
    }()
    
    lazy var slider: UISlider = {
        let slider = UISlider(frame: .init(x: 20, y: startBtn.minY - 20 - 5, width: view.width - 40, height: 5))
        slider.minimumValue = 0
        slider.maximumValue = 0
        slider.backgroundColor = .gray
        slider.thumbTintColor = .white
        slider.tintColor = .black
        slider.addTarget(self, action: #selector(sliderValueChangeStart), for: .touchDown)
        slider.addTarget(self, action: #selector(sliderValueChange), for: .valueChanged)
        slider.addTarget(self, action: #selector(sliderValueChangeEnd), for: .touchUpInside)
        slider.addTarget(self, action: #selector(sliderValueChangeEnd), for: .touchUpOutside)
        return slider
    }()
    
    lazy var previousBtn: UIButton = {
        let perviousBtn = UIButton(frame: .init(x: startBtn.minX - 10 - 40, y: startBtn.minY + (startBtn.height - 40) * 0.5, width: 40, height: 40))
        perviousBtn.setImage(.init(systemName: "backward.end"), for: .normal)
        perviousBtn.tintColor = .black
        perviousBtn.addTarget(self, action: #selector(touchPerviousBtn), for: .touchUpInside)
        return perviousBtn
    }()
    
    lazy var startBtn: UIButton = {
        let startBtn = UIButton(frame: .init(x: (view.width - 50) * 0.5, y: view.height - 50, width: 50, height: 50))
        startBtn.setImage(.init(systemName: "play"), for: .normal)
        startBtn.setImage(.init(systemName: "pause"), for: .selected)
        startBtn.tintColor = .black
        startBtn.addTarget(self, action: #selector(touchStartBtn), for: .touchUpInside)
        return startBtn
    }()
    
    lazy var nextBtn: UIButton = {
        let nextBtn = UIButton(frame: .init(x: startBtn.maxX + 10, y: startBtn.minY + (startBtn.height - 40) * 0.5, width: 40, height: 40))
        nextBtn.setImage(.init(systemName: "forward.end"), for: .normal)
        nextBtn.tintColor = .black
        nextBtn.addTarget(self, action: #selector(touchNextBtn), for: .touchUpInside)
        return nextBtn
    }()
    
    lazy var repeatBtn: UIButton = {
        let repeatBtn = UIButton(frame: .init(x: nextBtn.maxX + 10, y: nextBtn.minY, width: 40, height: 40))
        repeatBtn.setImage(.init(systemName: "shuffle"), for: .normal)
        repeatBtn.setImage(.init(systemName: "repeat"), for: .selected)
        repeatBtn.tintColor = .black
        repeatBtn.addTarget(self, action: #selector(touchRepeatBtn), for: .touchUpInside)
        return repeatBtn
    }()
    
    var isDraging: Bool = false
    
    let items: [AudioItem] = [
        .init(name: "你留下的爱", url: "https://freetyst.nf.migu.cn/public/product9th/product46/2022/10/0518/2022%E5%B9%B410%E6%9C%8805%E6%97%A515%E7%82%B948%E5%88%86%E7%B4%A7%E6%80%A5%E5%86%85%E5%AE%B9%E5%87%86%E5%85%A5%E5%92%AA%E5%92%95%E9%9F%B3%E4%B9%90%E8%87%AA%E6%9C%89%E7%89%88%E6%9D%83426%E9%A6%96815479/%E6%A0%87%E6%B8%85%E9%AB%98%E6%B8%85/MP3_128_16_Stero/69905306550185055.mp3?channelid=02&msisdn=355d2569-0de0-4ec5-8052-0322c47ab20b&Tim=1710063316332&Key=84c21c52bb85289c"),
        .init(name: "2002年的第一场雪", url: "https://m704.music.126.net/20240324204035/5d38b208db3a1b54460c78eb7c49b497/jdymusic/obj/w5zDlMODwrDDiGjCn8Ky/1571482021/a00f/01e9/cd9b/f722b40049445473017865790ae9341d.mp3?_authSecret=0000018e70633a6301490aaba058e0e5"),
        .init(name: "零点", url: "https://m10.music.126.net/20240324195856/6dd72cd08680602c026118fdf8a11a17/ymusic/obj/w5zDlMODwrDDiGjCn8Ky/14056207461/ed26/8a12/6a4c/1bc10618e7f70f032ff3e67f09623dc5.mp3"),
        .init(name: "桃花朵朵开", url: "https://m704.music.126.net/20240324200836/fcf807d6f2ad7aa3997682ff22e0b0cf/jdymusic/obj/w5zDlMODwrDDiGjCn8Ky/1645061695/fb10/b74e/d113/65678dfca41f0333b08640ef636f7645.mp3?_authSecret=0000018e7045f3a304ff0aaba38a096d")
    ]
    
    var index: Int = NSNotFound
    
    var observationStatus: NSKeyValueObservation?
    
    var observationLoadedTimeRanges: NSKeyValueObservation?
    
    var timeObserver: Any?
    
    lazy var player: AVPlayer = {
        let player = AVPlayer()
        player.volume = 1
        return player
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.addSubview(tableView)
        view.addSubview(timeLab)
        view.addSubview(slider)
        view.addSubview(previousBtn)
        view.addSubview(startBtn)
        view.addSubview(nextBtn)
        view.addSubview(repeatBtn)
        _ = NotificationCenter.default.addObserver(forName: AVPlayerItem.didPlayToEndTimeNotification, object: player.currentItem, queue: nil) { notification in
            if self.repeatBtn.isSelected {
                self.player.seek(to: .init(value: 0, timescale: 1))
                self.player.play()
            } else {
                self.touchNextBtn()
            }
        }
    }
    
    deinit {
        observationStatus?.invalidate()
        observationLoadedTimeRanges?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
}

extension AVPlayerViewController {
    
    @objc func touchPerviousBtn() {
        if index == NSNotFound {
            return
        } else if index > 0 {
            let indexPath = IndexPath(row: index - 1, section: 0)
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .top)
            tableView(tableView, didSelectRowAt: indexPath)
        } else {
            let indexPath = IndexPath(row: items.count - 1, section: 0)
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .top)
            tableView(tableView, didSelectRowAt: indexPath)
        }
    }
    
    @objc func touchStartBtn() {
        if index == NSNotFound {
            return
        }
        startBtn.isSelected = !startBtn.isSelected
        if player.timeControlStatus == .playing {
            player.pause()
        } else if player.timeControlStatus == .paused {
            player.play()
        }
    }
    
    @objc func touchNextBtn() {
        if index == NSNotFound {
            return
        } else if index < items.count - 1 {
            let indexPath = IndexPath(row: index + 1, section: 0)
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .top)
            tableView(tableView, didSelectRowAt: indexPath)
        } else {
            let indexPath = IndexPath(row: 0, section: 0)
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .top)
            tableView(tableView, didSelectRowAt: indexPath)
        }
    }
    
    @objc func touchRepeatBtn() {
        repeatBtn.isSelected = !repeatBtn.isSelected
    }
    
    @objc func sliderValueChangeStart() {
        isDraging = true
    }
    
    @objc func sliderValueChange() {
        let value = slider.value
        let lastDuration = timeLab.text!.components(separatedBy: "/").last!
        timeLab.text = "\(timeToText(time: Float64(value)))/\(lastDuration)"
    }
    
    @objc func sliderValueChangeEnd() {
        if !isDraging {
            return
        }
        let value = slider.value
        player.seek(to: .init(value: CMTimeValue(value), timescale: 1))
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // 修复卡顿问题
            self.isDraging = false
        }
    }
}

extension AVPlayerViewController {
    
    struct AudioItem {
        let name: String
        let url: String
        init(name: String, url: String) {
            self.name = name
            self.url = url
        }
    }
}

extension AVPlayerViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(UITableViewCell.self), for: indexPath)
        var content = cell.defaultContentConfiguration()
        content.text = items[indexPath.row].name
        cell.contentConfiguration = content
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        observationStatus?.invalidate()
        observationLoadedTimeRanges?.invalidate()
        if let timeObserver = timeObserver {
            player.removeTimeObserver(timeObserver)
        }
        index = indexPath.row
        slider.isUserInteractionEnabled = false // 可能存在拖拽，临时终止
        guard let url = URL(string: items[indexPath.row].url) else {
            return
        }
        let playerItem = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: playerItem)
        observationStatus = player.currentItem?.observe(\.status, options: .new, changeHandler: { [unowned self] item, change in
            switch playerItem.status {
                case .failed:
                    print(player.error)
                    slider.maximumValue = 0
                    slider.value = 0
                    timeLab.text = "00:00/00:00"
                    break
                case .readyToPlay:
                    slider.maximumValue = Float(CMTimeGetSeconds(playerItem.duration))
                    slider.value = 0
                    self.player.play()
                    break
                case .unknown:
                    break
                @unknown default:
                    break
            }
        })
        observationLoadedTimeRanges = player.currentItem?.observe(\.loadedTimeRanges, options: .new, changeHandler: { [unowned self] item, change in
            if let newStatus = change.newValue, let timeRange = newStatus.first?.timeRangeValue {
                let totalLoadTime = CMTimeGetSeconds(timeRange.start) + CMTimeGetSeconds(timeRange.duration)
                let duration = CMTimeGetSeconds(player.currentItem!.duration)
                print("[AVPlayer] --- 加载进度:\(totalLoadTime / duration)")
            }
        })
        timeObserver = player.addPeriodicTimeObserver(forInterval: .init(value: 1, timescale: 1), queue: DispatchQueue.main) { [unowned self] time in
            if isDraging {
                // 拖拽期间不处理
                return
            }
            guard let playItem = player.currentItem, playItem.duration.timescale != 0 else {
                return
            }
            let current = CMTimeGetSeconds(time)
            let total = CMTimeGetSeconds(playItem.duration)
            timeLab.text = "\(timeToText(time: current))/\(timeToText(time: total))"
            slider.setValue(Float(current), animated: true)
        }
        startBtn.isSelected = true
        slider.isUserInteractionEnabled = true
    }
}

extension AVPlayerViewController {
    
    func timeToText(time: Float64) -> String {
        let time = Int(time)
        return String(format: "%02d:%02d", time / 60, time % 60)
    }
}
