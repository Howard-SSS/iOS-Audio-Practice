//
//  PlaybackModel.swift
//  iOS-Audio-Practice
//
//  Created by Howard-Zjun on 2024/03/28.
//

import Foundation

struct PlaybackModel: Identifiable {
    
    let value: Double
    
    let label: String
    
    var id: String {
        return "\(label)-\(value)"
    }
}
