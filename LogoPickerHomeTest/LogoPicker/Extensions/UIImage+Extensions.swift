//
//  UIImage+Extensions.swift
//  LogoPickerHomeTest
//
//  Created by Aliaksandr Akimau on 11/2/23.
//

import Foundation
import UIKit

extension UIImage {
    
    func resizedTo(size: CGSize) -> UIImage? {
        let widthRatio = size.width / self.size.width
        let heightRatio = size.height / self.size.height
        var canvasSize = size
        if(widthRatio > heightRatio) {
            canvasSize = CGSize(width: self.size.width * heightRatio, height: self.size.height * heightRatio)
        } else if heightRatio > widthRatio {
            canvasSize = CGSize(width: self.size.width * widthRatio, height: self.size.height * widthRatio)
        }
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: canvasSize))
        UIGraphicsGetImageFromCurrentImageContext()
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    func croppedTo(rect: CGRect) -> UIImage? {
        let scaledRect = CGRect(x: rect.origin.x * self.scale,
                                y: rect.origin.y * self.scale,
                                width: rect.size.width * self.scale,
                                height: rect.size.height * self.scale);
        guard let imageRef: CGImage = self.cgImage?.cropping(to: scaledRect) else {
            return nil
        }
        let croppedImage: UIImage = UIImage(cgImage: imageRef, scale: self.scale, orientation: self.imageOrientation)
        return croppedImage
    }
    
}
