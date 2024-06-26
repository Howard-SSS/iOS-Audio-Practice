//
//  ViewController.swift
//  iOS-Audio-Practice
//
//  Created by Howard-Zjun on 2024/03/24.
//

import UIKit

class ViewController: UIViewController {

    lazy var avplayerBtn: UIButton = {
        let avplayerBtn = UIButton(frame: .init(x: 0, y: 200, width: 100, height: 50))
        avplayerBtn.layer.borderColor = UIColor.gray.cgColor
        avplayerBtn.layer.borderWidth = 1
        avplayerBtn.setTitle("AVPlayer", for: .normal)
        avplayerBtn.setTitleColor(.black, for: .normal)
        avplayerBtn.addTarget(self, action: #selector(touchavplayerBtn), for: .touchUpInside)
        return avplayerBtn
    }()
    
    lazy var recordPlayerBtn: UIButton = {
        let recordPlayerBtn = UIButton(frame: .init(x: avplayerBtn.maxX + 10, y: 200, width: 200, height: 50))
        recordPlayerBtn.layer.borderColor = UIColor.gray.cgColor
        recordPlayerBtn.layer.borderWidth = 1
        recordPlayerBtn.setTitle("AVAudioRecorder/Player", for: .normal)
        recordPlayerBtn.setTitleColor(.black, for: .normal)
        recordPlayerBtn.addTarget(self, action: #selector(touchRecordPlayerBtn), for: .touchUpInside)
        return recordPlayerBtn
    }()
    
    lazy var engineBtn: UIButton = {
        let engineBtn = UIButton(frame: .init(x: recordPlayerBtn.maxX + 10, y: 200, width: 100, height: 50))
        engineBtn.layer.borderColor = UIColor.gray.cgColor
        engineBtn.layer.borderWidth = 1
        engineBtn.setTitle("engine", for: .normal)
        engineBtn.setTitleColor(.black, for: .normal)
        engineBtn.addTarget(self, action: #selector(touchEngineBtn), for: .touchUpInside)
        return engineBtn
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.addSubview(avplayerBtn)
        view.addSubview(recordPlayerBtn)
        view.addSubview(engineBtn)
    }

    @objc func touchavplayerBtn() {
        navigationController?.pushViewController(AVPlayerViewController(), animated: true)
    }
    
    @objc func touchRecordPlayerBtn() {
        navigationController?.pushViewController(AVAudioRecorderPlayerViewController(), animated: true)
    }
    
    @objc func touchEngineBtn() {
        navigationController?.pushViewController(AVAudioEngineViewController(), animated: true)
    }
}

