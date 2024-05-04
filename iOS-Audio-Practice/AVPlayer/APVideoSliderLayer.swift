//
//  APVideoVerticalSliderLayer.swift
//  iOS-Audio-Practice
//
//  Created by Howard-Zjun on 2024/05/02.
//

import UIKit

class APVideoSliderLayer: CALayer {

    var value: Float
    
    var images: [UIImage]
    
    lazy var backgroundLayer: CALayer = {
        let backgroundLayer = CALayer()
        backgroundLayer.frame = bounds
        backgroundLayer.backgroundColor = UIColor(hexValue: 0x8A8A8A).cgColor
        return backgroundLayer
    }()
    
    lazy var imgLayer: CALayer = {
        let imgLayer = CALayer()
        imgLayer.frame = .init(x: 10, y: (frame.height - 30) * 0.5, width: 30, height: 30)
        return imgLayer
    }()
    
    lazy var slideLayer: CALayer = {
        let slideLayer = CALayer()
        slideLayer.frame = .init(x: imgLayer.frame.maxX + 10, y: (frame.height - 5) * 0.5, width: frame.width - imgLayer.frame.maxX - 10 - 20, height: 5)
        slideLayer.backgroundColor = UIColor.clear.cgColor
        slideLayer.cornerRadius = 2
        return slideLayer
    }()
    
    lazy var coverLayer: CALayer = {
        let coverLayer = CALayer()
        coverLayer.frame = .init(x: 0, y: 0, width: slideLayer.frame.width * CGFloat(value), height: slideLayer.frame.height)
        coverLayer.cornerRadius = 2
        coverLayer.backgroundColor = UIColor.white.cgColor
        return coverLayer
    }()
    
    override var frame: CGRect {
        didSet {
            backgroundLayer.frame = bounds
            imgLayer.frame = .init(x: 10, y: (frame.height - 50) * 0.5, width: 50, height: 50)
            slideLayer.frame = .init(x: imgLayer.frame.maxX + 10, y: (frame.height - 5) * 0.5, width: frame.width - imgLayer.frame.maxX - 10 - 20, height: 5)
            coverLayer.frame = .init(x: 0, y: 0, width: slideLayer.frame.width * CGFloat(value), height: slideLayer.frame.height)
        }
    }
    
    init(frame: CGRect, images: [UIImage], value: Float) {
        self.value = value
        var images = images
        if images.count == 0 {
            images = [.init(systemName: "speaker.wave.3")!]
        }
        self.images = images
        super.init()
        self.frame = frame
        imgLayer.contents = images[index(value: value)].cgImage
        addSublayer(backgroundLayer)
        addSublayer(imgLayer)
        addSublayer(slideLayer)
        slideLayer.addSublayer(coverLayer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateValue(_ value: Float) {
        self.value = value
        coverLayer.frame = .init(x: 0, y: 0, width: slideLayer.frame.width * CGFloat(value), height: slideLayer.frame.height)
        imgLayer.contents = images[index(value: value)].cgImage
        print("更新值: \(value)")
    }
    
    func index(value: Float) -> Int {
        let index = Int(floor(value / 1 * Float(images.count)))
        if index == images.count {
            return index - 1
        } else{
            return index
        }
            
    }
}
