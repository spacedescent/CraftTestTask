//
//  SpaceLayer.swift
//  LogoPickerHomeTest
//
//  Created by Aliaksandr Akimau on 11/1/23.
//

import UIKit

final class SpaceLayer: CALayer {
    var startColor: CGColor = UIColor.systemBlue.cgColor
    var endColor: CGColor = UIColor.magenta.cgColor
    var angle: CGFloat = 30 * CGFloat.pi / 180
    var stripesCount: Int = 4
    
    override func draw(in ctx: CGContext) {
        // scale to fit drawings into square diagonal after rotation
        let scale = 1 / max(abs(cos(angle)), abs(sin(angle)))
        let transform = CGAffineTransform(scaleX: scale, y: scale)
            .concatenating(CGAffineTransform(rotationAngle: angle))
        
        let width: CGFloat = bounds.width
        let height: CGFloat = bounds.height
        
        sublayers?.forEach { $0.removeFromSuperlayer() }
        
        // actually draw whole (stripesCount - 1) stripes + 2 partially visible stripes
        for i in 0...stripesCount {
            let layer = CAShapeLayer()
            
            let lineCenterVector = CGPoint(x: 0, y: height * CGFloat(i) / CGFloat(stripesCount) - height / 2)
                .applying(transform)
            let lineCenterPoint = CGPoint(x: lineCenterVector.x + width / 2, y: lineCenterVector.y + height / 2)
            let vector = CGPoint(x: width * scale, y: 0)
            let transformedVector = vector.applying(transform)
            
            let startX = lineCenterPoint.x - transformedVector.x / 2
            let endX = lineCenterPoint.x + transformedVector.x / 2
            let startY = lineCenterPoint.y - transformedVector.y / 2
            let endY = lineCenterPoint.y + transformedVector.y / 2
            
            let linePath = UIBezierPath()
            linePath.move(to: CGPoint(x: startX, y: startY))
            linePath.addLine(to: CGPoint(x: endX, y: endY))
            layer.path = linePath.cgPath
            layer.opacity = 1
            layer.lineWidth = ceil(height * scale / CGFloat(stripesCount))
            layer.fillColor = UIColor.clear.cgColor
            layer.strokeColor = blendColors(startColor: startColor, endColor: endColor, proportion: CGFloat(i) / CGFloat(stripesCount))
            
            addSublayer(layer)
        }
    }
    
    private func blendColors(startColor: CGColor, endColor: CGColor, proportion: CGFloat) -> CGColor {
        let startUiColor = UIColor(cgColor: startColor)
        let endUiColor = UIColor(cgColor: endColor)
        var r1: CGFloat = 0, b1: CGFloat = 0, g1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, b2: CGFloat = 0, g2: CGFloat = 0, a2: CGFloat = 0
        startUiColor.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        endUiColor.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        let blendedUiColor = UIColor(red: r1 *  (1.0 - proportion) + r2 * proportion,
                                     green: g1 *  (1.0 - proportion) + g2 * proportion,
                                     blue: b1 *  (1.0 - proportion) + b2 * proportion,
                                     alpha: a1 *  (1.0 - proportion) + a2 * proportion)
        return blendedUiColor.cgColor
    }
}
