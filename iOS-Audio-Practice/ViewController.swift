//
//  ViewController.swift
//  iOS-Audio-Practice
//
//  Created by Howard-Zjun on 2024/03/24.
//

import UIKit

class ViewController: UIViewController {

    lazy var avplayerBtn: UIButton = {
        let avplayerBtn = UIButton(frame: .init(x: 0, y: 0, width: 100, height: 50))
        avplayerBtn.setTitle("AVPlayer", for: .normal)
        avplayerBtn.setTitleColor(.black, for: .normal)
        avplayerBtn.addTarget(self, action: #selector(touchavplayerBtn), for: .touchUpInside)
        return avplayerBtn
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(avplayerBtn)
    }

    @objc func touchavplayerBtn() {
        navigationController?.pushViewController(AVPlayerViewController(), animated: true)
    }
}

