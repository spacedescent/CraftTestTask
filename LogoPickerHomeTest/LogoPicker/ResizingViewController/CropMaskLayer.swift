//
//  CropMaskLayer.swift
//  LogoPickerHomeTest
//
//  Created by Aliaksandr Akimau  on 11/3/23.
//

import UIKit

final class CropMaskLayer: CALayer {
    var maskShape: LogoShape = .circle
    var logoSize: CGFloat? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    private struct Layout {
        static let cornerRadiusToLogoSizeRatio: CGFloat = 1 / 6
    }
    
    override func draw(in ctx: CGContext) {
        sublayers?.forEach { $0.removeFromSuperlayer() }

        let width = bounds.width
        let height = bounds.height
        let minSide = min(width, height)

        let square = CGRect(x: (width - minSide) / 2, y: (height - minSide) / 2, width: minSide, height: minSide)
        
        let rectLayer = CAShapeLayer()
        let rectPath = UIBezierPath(rect: bounds)
        rectLayer.opacity = 0.6
        rectLayer.fillColor = UIColor.black.cgColor
        
        let circleSize = logoSize ?? minSide
        let circle = CGRect(x: (width - circleSize) / 2, y: (height - circleSize) / 2, width: circleSize, height: circleSize)
        
        let circlePath = maskShape == .circle ? UIBezierPath(ovalIn: circle) : UIBezierPath(roundedRect: circle, cornerRadius: circleSize * Layout.cornerRadiusToLogoSizeRatio)
        
        rectPath.append(circlePath.reversing())
        rectLayer.path = rectPath.cgPath

        addSublayer(rectLayer)
    }
}
