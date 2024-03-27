//
//  AVAudioRecorderPlayerViewController.swift
//  iOS-Audio-Practice
//
//  Created by Howard-Zjun on 2024/03/26.
//

import UIKit
import AVFAudio
import AVFoundation

// MARK: - TableViewMoreInfoCellDelegate 协议
protocol TableViewMoreInfoCellDelegate: NSObjectProtocol {
    
    func playAudio(index: Int, begin: TimeInterval) -> Bool
    
    func pasueAudio(index: Int)
    
    func deleteAudio(index: Int)
}

class AVAudioRecorderPlayerViewController: UIViewController {

    var player: AVAudioPlayer?
    
    var recorder: AVAudioRecorder?
    
    var datas: [ItemModel] = []
    
    var canRecoderNext: Bool = true
    
    var durationTimer: Timer?
    
    var meters: [Int] = []
    
    var meterTimer: Timer?
    
    var dataPath: URL {
        var path: URL!
        if #available(iOS 16.0, *) {
            path = URL(filePath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last!)
        } else {
            path = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last!)
        }
        let ret = path.appendingPathComponent("record")
        var directory: ObjCBool = ObjCBool(false)
        if !FileManager.default.fileExists(atPath: ret.path, isDirectory: &directory) {
            do {
                try FileManager.default.createDirectory(at: ret, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("[record/play] --- 创建文件夹错误：\(error)")
            }
        }
        return ret
    }
    
    var meterAlertView: RecorderMeterAlertView?
    
    lazy var naviView: UIView = {
        let naviView = UIView(frame: .init(x: 0, y: 0, width: view.width, height: 200))
        naviView.backgroundColor = .clear
        naviView.isUserInteractionEnabled = true
        let underLine = UIView(frame: .init(x: 0, y: naviView.height - 1, width: naviView.width, height: 1))
        underLine.backgroundColor = .gray
        naviView.addSubview(underLine)
        return naviView
    }()
    
    lazy var backBtn: UIButton = {
        let backBtn = UIButton(type: .close)
        backBtn.frame = .init(x: 10, y: 60, width: 40, height: 40)
        backBtn.addTarget(self, action: #selector(touchBackBtn), for: .touchUpInside)
        backBtn.tintColor = .blue
        return backBtn
    }()
    
    lazy var editBtn: UIButton = {
        let text = "编辑"
        let btnWidth = (text as NSString).size(withAttributes: [.font : UIFont.systemFont(ofSize: 14)]).width + 20
        let editBtn = UIButton(frame: .init(x: naviView.width - 10 - btnWidth, y: 60, width: btnWidth, height: 40))
        editBtn.setTitle(text, for: .normal)
        editBtn.setTitle("取消", for: .selected)
        editBtn.setTitleColor(.blue, for: .normal)
        editBtn.addTarget(self, action: #selector(touchEditBtn), for: .touchUpInside)
        return editBtn
    }()
    
    lazy var titleLab: UILabel = {
        let titleLab = UILabel(frame: .init(x: 20, y: backBtn.maxY + 20, width: naviView.width - 40, height: 50))
        titleLab.text = "所有录音"
        titleLab.font = .systemFont(ofSize: 23)
        titleLab.textColor = .black
        titleLab.textAlignment = .left
        return titleLab
    }()
    
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .init(x: 0, y: naviView.maxY, width: view.width, height: recordControlView.minY - naviView.maxY))
        tableView.backgroundColor = .clear
        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsMultipleSelection = false
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.register(TableViewMoreInfoCell.self, forCellReuseIdentifier: NSStringFromClass(TableViewMoreInfoCell.self))
        tableView.register(TableViewNormalInfoCell.self, forCellReuseIdentifier: NSStringFromClass(TableViewNormalInfoCell.self))
        tableView.contentInset = .zero
        return tableView
    }()
    
    lazy var recordControlView: UIView = {
        let recordControlView = UIView(frame: .init(x: 0, y: view.height - 150, width: view.width, height: 150))
        recordControlView.backgroundColor = .lightGray
        return recordControlView
    }()
    
    lazy var recordBtn: UIButton = {
        let recordBtn = UIButton(frame: .init(x: (recordControlView.width - 50) * 0.5, y: 70, width: 50, height: 50))
        recordBtn.layer.cornerRadius = 100 * 0.5
        let config = UIImage.SymbolConfiguration(scale: .large)
        recordBtn.setImage(.init(systemName: "record.circle", withConfiguration: config), for: .normal)
        recordBtn.setImage(.init(systemName: "stop.fill", withConfiguration: config), for: .selected)
        recordBtn.tintColor = .red
        recordBtn.addTarget(self, action: #selector(touchRecordBtn), for: .touchUpInside)
        return recordBtn
    }()
    
    lazy var mutableDeleteView: UIView = {
        let mutableDeleteView = UIView(frame: .init(x: 0, y: view.height, width: view.width, height: 50))
        return mutableDeleteView
    }()
    
    lazy var mutableDeleteBtn: UIButton = {
        let mutableDeleteBtn = UIButton(frame: .init(x: mutableDeleteView.width - 10 - 30, y: 0, width: 30, height: 30))
        let config = UIImage.SymbolConfiguration(scale: .large)
        mutableDeleteBtn.setImage(.init(systemName: "trash", withConfiguration: config), for: .normal)
        mutableDeleteBtn.addTarget(self, action: #selector(touchMutableDeleteBtn), for: .touchUpInside)
        return mutableDeleteBtn
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.addSubview(naviView)
        naviView.addSubview(backBtn)
        naviView.addSubview(editBtn)
        naviView.addSubview(titleLab)
        view.addSubview(tableView)
        view.addSubview(mutableDeleteView)
        mutableDeleteView.addSubview(mutableDeleteBtn)
        view.addSubview(recordControlView)
        recordControlView.addSubview(recordBtn)
        
        reloadData()
    }

    func setRecordCategory() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record)
            try session.setActive(true)
        } catch {
            print(error)
        }
    }
    
    func setPlayCategory() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback)
            try session.setActive(true)
        } catch {
            print(error)
        }
    }
    
    func reloadData() {
        do {
            var datas: [ItemModel] = []
            for fileName in try FileManager.default.contentsOfDirectory(atPath: dataPath.path) {
                let fileUrl = dataPath.appendingPathComponent(fileName)
                let attribute = try FileManager.default.attributesOfItem(atPath: fileUrl.path)
                
                let title = fileUrl.deletingPathExtension().lastPathComponent
                let keepTime = attribute[.creationDate] as! Date
                let asset = AVURLAsset(url: fileUrl, options: [AVURLAssetPreferPreciseDurationAndTimingKey : true])
                let model = ItemModel(title: title, keepTime: keepTime, duration: CMTimeGetSeconds(asset.duration), dataPath: fileUrl)
                datas.append(model)
            }
            datas.sort { item1, item2 in
                item1.keepTime.compare(item2.keepTime) == .orderedDescending
            }
            self.datas = datas
            tableView.reloadData()
        } catch {
            print("[record/play] --- 载入数据错误：\(error)")
        }
    }
    
    func resetRecorder() -> Bool {
        recorder?.stop()
        recorder = nil
        do {
            recorder = try AVAudioRecorder(url: newFileName(), settings: [
                AVFormatIDKey : kAudioFormatMPEG4AAC,
                AVSampleRateKey : 44100.0,
                AVNumberOfChannelsKey : 2,
                AVEncoderAudioQualityKey : NSNumber(value: AVAudioQuality.medium.rawValue)
            ])
            recorder?.delegate = self
            recorder?.isMeteringEnabled = true
        } catch {
            print("[record/play] --- 录音初始化错误：\(error)")
            return false
        }
        recorder?.prepareToRecord()
        setRecordCategory()
        return true
    }
    
    func resetPlayer(index: Int) -> Bool {
        player?.stop()
        player = nil
        
        do {
            let model = datas[index]
            player = try AVAudioPlayer(contentsOf: model.dataPath)
            player?.delegate = self
            player?.volume = 1
        } catch {
            print("[record/play] --- 播放初始化错误：\(error)")
            return false
        }
        player?.prepareToPlay()
        setPlayCategory()
        return true
    }
    
    func newFileName() -> URL {
        do {
            var maxNum = 0
            for fileName in try FileManager.default.contentsOfDirectory(atPath: dataPath.path) {
                var url = URL(string: "\(dataPath)/\(fileName)")!
                url.deletePathExtension()
                let lastPath = url.lastPathComponent
                let num = Int(lastPath.components(separatedBy: "-")[1])!
                if num > maxNum {
                    maxNum = num
                }
            }
            return dataPath.appendingPathComponent("record-\(maxNum + 1).aac")
        } catch {
            print("[record/play] --- 获取新文件名错误：\(error)")
            return dataPath.appendingPathComponent("record-0.aac")
        }
    }
    
    func startPlayerProgressKVO() {
        durationTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { timer in
            guard let player = self.player else {
                return
            }
            NotificationCenter.default.post(name: TableViewMoreInfoCell.updateProgressNotificationInfo, object: nil, userInfo: [
                "progress" : Float(player.currentTime)
            ])
        })
    }
    
    func endPlayerProgressKVO() {
        durationTimer?.invalidate()
        durationTimer = nil
    }
    
    func startGetMeter() {
        meters = []
        let meterAlertView = RecorderMeterAlertView(frame: .init(x: 0, y: naviView.maxY, width: view.width, height: 250))
        view.addSubview(meterAlertView)
        self.meterAlertView = meterAlertView
        let meterTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) {timer in
            guard timer.isValid, let recorder = self.recorder else {
                return
            }
            recorder.updateMeters()
            let meter = recorder.averagePower(forChannel: 1)
            self.meters.append(Int(meter + 160))
            self.meterAlertView?.updateMeter(meters: self.meters)
        }
        RunLoop.current.add(meterTimer, forMode: .common)
        self.meterTimer = meterTimer
    }
    
    func endGetMeter() {
        meterTimer?.invalidate()
        meterTimer = nil
        meterAlertView?.removeFromSuperview()
        meterAlertView = nil
    }
}

// MARK: - 模型
extension AVAudioRecorderPlayerViewController {

    class ItemModel: NSObject {
        
        var title: String
        
        var keepTime: Date
        
        var duration: TimeInterval
        
        var dataPath: URL
        
        var isOpen: Bool = false
        
        var isSelectedDuringEditing: Bool = false
        
        init(title: String, keepTime: Date, duration: TimeInterval, dataPath: URL) {
            self.title = title
            self.keepTime = keepTime
            self.duration = duration
            self.dataPath = dataPath
        }
    }
}

// MARK: - 事件
extension AVAudioRecorderPlayerViewController {
    
    @objc func touchBackBtn() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc func touchEditBtn() {
        if editBtn.isSelected {
            tableView.setEditing(false, animated: true)
            UIView.animate(withDuration: 0.3) {
                self.recordControlView.frame.origin = .init(x: 0, y: self.view.height - self.recordControlView.height)
                self.mutableDeleteView.frame.origin = .init(x: 0, y: self.view.height)
            }
        } else {
            tableView.setEditing(true, animated: true)
            UIView.animate(withDuration: 0.3) {
                self.recordControlView.frame.origin = .init(x: 0, y: self.view.height)
                self.mutableDeleteView.frame.origin = .init(x: 0, y: self.view.height - self.mutableDeleteView.height)
            }
        }
        editBtn.isSelected = !editBtn.isSelected
    }
    
    @objc func touchRecordBtn() {
        if recordBtn.isSelected { // 录制中 -> 暂停
            recorder?.stop()
            canRecoderNext = false
            recordBtn.isSelected = false
            endGetMeter()
        } else { // 暂停 -> 录制中
            if !canRecoderNext {
                return
            }
            if resetRecorder() == false {
                return
            }
            recorder?.record()
            recordBtn.isSelected = true
            startGetMeter()
        }
    }
    
    @objc func touchMutableDeleteBtn() {
        for indexPath in tableView.indexPathsForSelectedRows ?? [] {
            let model = datas[indexPath.row]
            do {
                try FileManager.default.removeItem(at: model.dataPath)
            } catch {
                print("[record/play] --- 批量删除\(model.title)错误：\(error)")
            }
        }
        reloadData()
    }
}

// MARK: - AVAudioPlayerDelegate 实现
extension AVAudioRecorderPlayerViewController: AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("[record/play] --- 完成播放，flag:\(flag)")
        endPlayerProgressKVO()
        NotificationCenter.default.post(name: TableViewMoreInfoCell.updateProgressNotificationInfo, object: nil, userInfo: [
            "progress" : Float(player.duration + 1)
        ])
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if let error = error {
            print("[record/play] --- 解码错误:\(error)")
        }
    }
}

// MARK: - AVAudioRecorderDelegate 实现
extension AVAudioRecorderPlayerViewController: AVAudioRecorderDelegate {
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        print("[record/play] --- 完成录音:\(flag)")
        canRecoderNext = true
        reloadData()
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            print("[record/play] --- 编码错误:\(error)")
        }
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension AVAudioRecorderPlayerViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        datas.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = datas[indexPath.row]
        if tableView.isEditing {
            let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(TableViewNormalInfoCell.self), for: indexPath) as! TableViewNormalInfoCell
            cell.updateContent(model: model)
            return cell
        } else {
            if model.isOpen {
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(TableViewMoreInfoCell.self), for: indexPath) as! TableViewMoreInfoCell
                cell.updateContent(model: model)
                cell.delegate = self
                cell.index = indexPath.row
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(TableViewNormalInfoCell.self), for: indexPath) as! TableViewNormalInfoCell
                cell.updateContent(model: model)
                return cell
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            datas[indexPath.row].isSelectedDuringEditing = !datas[indexPath.row].isSelectedDuringEditing
//            tableView.reloadRows(at: [indexPath], with: .none)
        } else {
            player?.stop()
            endPlayerProgressKVO()
            
            var lastSelect: Int?
            for index in 0..<datas.count {
                if datas[index].isOpen {
                    lastSelect = index
                    break
                }
            }
            datas[indexPath.row].isOpen = true
            if let lastSelect = lastSelect {
                datas[lastSelect].isOpen = false
                tableView.reloadRows(at: [indexPath, .init(row: lastSelect, section: 0)], with: .none)
            } else {
                tableView.reloadRows(at: [indexPath], with: .none)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let model = datas[indexPath.row]
        if model.isOpen {
            return 200
        } else {
            return 75
        }
    }
}

// MARK: - TableViewMoreInfoCellDelegate 实现
extension AVAudioRecorderPlayerViewController: TableViewMoreInfoCellDelegate {
    
    func playAudio(index: Int, begin: TimeInterval) -> Bool {
        if resetPlayer(index: index) == false {
            return false
        }
        
        startPlayerProgressKVO()
        player?.play(atTime: player!.deviceCurrentTime + begin)
        return true
    }
    
    func pasueAudio(index: Int) {
        endPlayerProgressKVO()
        player?.pause()
    }
    
    func deleteAudio(index: Int) {
        if player?.isPlaying ?? false {
            player?.stop()
            player = nil
        }
        let path = datas[index].dataPath
        do {
            try FileManager.default.removeItem(at: path)
            datas.remove(at: index)
            tableView.reloadData()
        } catch {
            print("[record/play] --- 删除单元失败：\(error)")
        }
    }
}

// MARK: - 单元类
extension AVAudioRecorderPlayerViewController {
    
    class TableViewNormalInfoCell: UITableViewCell {
        
        lazy var titleLab: UILabel = {
            let titleLab = UILabel(frame: .init(x: 20, y: 10, width: contentView.width * 3 / 5, height: 30))
            titleLab.textColor = .black
            titleLab.font = .systemFont(ofSize: 15)
            titleLab.textAlignment = .left
            return titleLab
        }()
        
        lazy var keepLab: UILabel = {
            let keepLab = UILabel(frame: .init(x: 20, y: titleLab.maxY + 10, width: 100, height: 30))
            keepLab.textColor = .gray
            keepLab.font = .systemFont(ofSize: 15)
            keepLab.textAlignment = .left
            return keepLab
        }()
        
        lazy var durationLab: UILabel = {
            let durationLab = UILabel(frame: .init(x: contentView.width - 20 - 100, y: titleLab.maxY + 10, width: 100, height: 30))
            durationLab.textColor = .gray
            durationLab.font = .systemFont(ofSize: 15)
            durationLab.textAlignment = .right
            return durationLab
        }()
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            configUI()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            titleLab.frame = .init(x: 20, y: 10, width: contentView.width * 3 / 5, height: 30)
            keepLab.frame = .init(x: 20, y: titleLab.maxY + 10, width: 100, height: 30)
            durationLab.frame = .init(x: contentView.width - 20 - 100, y: titleLab.maxY + 10, width: 100, height: 30)
        }
        
        func configUI() {
            contentView.addSubview(titleLab)
            contentView.addSubview(keepLab)
            contentView.addSubview(durationLab)
        }
        
        func updateContent(model: AVAudioRecorderPlayerViewController.ItemModel) {
            titleLab.text = model.title
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            keepLab.text = formatter.string(from: model.keepTime)
            durationLab.text = "\(Int(model.duration) / 60):\(Int(model.duration) % 60)"
        }
    }
    
    class TableViewMoreInfoCell: TableViewNormalInfoCell {
        
        weak var delegate: TableViewMoreInfoCellDelegate?
        
        var index: Int!
        
        static let updateProgressNotificationInfo: Notification.Name = .init(NSStringFromClass(TableViewMoreInfoCell.self))
        
        lazy var slider: UISlider = {
            let slider = UISlider(frame: .init(x: 20, y: keepLab.maxY + 40, width: contentView.width - 40, height: 10))
            slider.minimumTrackTintColor = .darkGray
            slider.thumbTintColor = .darkGray
            slider.maximumTrackTintColor = .gray
            return slider
        }()
        
        lazy var playBtn: UIButton = {
            let playBtn = UIButton(frame: .init(x: (contentView.width - 40) * 0.5, y: slider.maxY + 20, width: 40, height: 40))
            let config = UIImage.SymbolConfiguration(scale: .large)
            playBtn.setImage(.init(systemName: "play.fill", withConfiguration: config), for: .normal)
            playBtn.setImage(.init(systemName: "pause.fill", withConfiguration: config), for: .selected)
            playBtn.tintColor = .black
            playBtn.addTarget(self, action: #selector(touchPlayBtn), for: .touchUpInside)
            return playBtn
        }()
        
        lazy var deleteBtn: UIButton = {
            let deleteBtn = UIButton(frame: .init(x: contentView.width - 20 - 40, y: playBtn.minY + (playBtn.height - 40) * 0.5, width: 40, height: 40))
            let config = UIImage.SymbolConfiguration(scale: .large)
            deleteBtn.setImage(.init(systemName: "trash", withConfiguration: config), for: .normal)
            deleteBtn.tintColor = .blue
            deleteBtn.addTarget(self, action: #selector(touchDeleteBtn), for: .touchUpInside)
            return deleteBtn
        }()
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            configUI()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            slider.frame = .init(x: 20, y: keepLab.maxY + 40, width: contentView.width - 40, height: 10)
            playBtn.frame = .init(x: (contentView.width - 40) * 0.5, y: slider.maxY + 20, width: 40, height: 40)
            deleteBtn.frame = .init(x: contentView.width - 20 - 40, y: playBtn.minY + (playBtn.height - 40) * 0.5, width: 40, height: 40)
        }
        
        override func configUI() {
            super.configUI()
            contentView.addSubview(slider)
            contentView.addSubview(playBtn)
            contentView.addSubview(deleteBtn)
        }
        
        override func updateContent(model: AVAudioRecorderPlayerViewController.ItemModel) {
            super.updateContent(model: model)
            NotificationCenter.default.removeObserver(self)
            playBtn.isSelected = false
            slider.maximumValue = Float(model.duration)
            slider.value = 0
        }
        
        @objc func touchPlayBtn() {
            if playBtn.isSelected {
                delegate?.pasueAudio(index: index)
                playBtn.isSelected = false
            } else {
                if delegate?.playAudio(index: index, begin: TimeInterval(slider.value)) ?? false {
                    playBtn.isSelected = true
                    NotificationCenter.default.addObserver(self, selector: #selector(updateProgress(_:)), name: TableViewMoreInfoCell.updateProgressNotificationInfo, object: nil)
                }
            }
        }
        
        @objc func touchDeleteBtn() {
            delegate?.deleteAudio(index: index)
        }
        
        @objc func updateProgress(_ info: Notification) {
            let progress = info.userInfo?["progress"] as! Float
            print("[record/play] --- progress:\(progress)")
            slider.value = progress
            if progress > slider.maximumValue {
                playBtn.isSelected = false
            }
        }
    }
}
