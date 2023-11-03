//
//  LogoStyle.swift
//  LogoPickerHomeTest
//
//  Created by Aliaksandr Akimau on 10/31/23.
//

import Foundation
import UIKit

public enum LogoShape {
    case roundedRect
    case circle
}

// MARK: - UI style representation

public enum LogoStyle {
    case `default`(startColor: UIColor, endColor: UIColor)
    case solid(color: UIColor)
    case gradient(startColor: UIColor, endColor: UIColor)
    case image(url: URL)
}

// MARK: - Storage/Network style representation for crossplatform usage

public struct ColorDto: Codable {
    // 8 bits per each color & alpha
    let rgba: UInt32
}

public enum LogoStyleDto: Codable {
    case `default`(startColor: ColorDto, endColor: ColorDto)
    case solid(color: ColorDto)
    case gradient(startColor: ColorDto, endColor: ColorDto)
    case image(url: String)
}

// TODO: implement ColorDto <-> UIColor & LogoStyleDto <-> LogoStyle conversions
