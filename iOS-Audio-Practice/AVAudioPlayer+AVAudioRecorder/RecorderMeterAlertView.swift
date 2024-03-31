//
//  RecorderMeterAlertView.swift
//  iOS-Audio-Practice
//
//  Created by Howard-Zjun on 2024/03/27.
//

import UIKit

class RecorderMeterAlertView: UIView {

    var meters: [Int] = []
    
    let keep: Int = 4
    
    var heightRange: CGFloat = 0.75
    
    let lowerPower: Int = 110
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .init(h: 0, s: 0, b: 80)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateMeter(meters: [Int]) {
        self.meters = meters
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        let needDrawGroup = Int(width) / keep
        var minX: CGFloat = 0
        var beginIndex: Int = 0
        if meters.count - needDrawGroup > 0 {
            beginIndex = meters.count - needDrawGroup - 1
            minX = 0
        } else {
            beginIndex = 0
            minX = CGFloat((needDrawGroup - meters.count) * keep)
        }
        let centerY: CGFloat = height * 0.5
        
        let context = UIGraphicsGetCurrentContext()
        context?.setStrokeColor(UIColor.red.cgColor)
        for index in beginIndex..<meters.count {
            // 测试发现，不发出声音功率数值也有110，所以设定110为最低
            var meter = meters[index] - lowerPower
            if meter < 0 {
                meter = 0
            }
            let halfMeter = ((height * heightRange) * (CGFloat(meter) / 60) + 4) * 0.5
            context?.move(to: .init(x: minX, y: centerY))
            context?.addLine(to: .init(x: minX, y: centerY - halfMeter))
            
            context?.move(to: .init(x: minX, y: centerY))
            context?.addLine(to: .init(x: minX, y: centerY + halfMeter))
            
            minX += CGFloat(keep)
        }
        context?.strokePath()

        context?.setStrokeColor(UIColor.black.cgColor)
        context?.move(to: .init(x: width * 0.5, y: centerY))
        context?.addLine(to: .init(x: width * 0.5, y: 0))
        context?.move(to: .init(x: width * 0.5, y: centerY))
        context?.addLine(to: .init(x: width * 0.5, y: height))
        context?.strokePath()
    }
}
