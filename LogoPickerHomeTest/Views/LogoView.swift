//
//  LogoView.swift
//  LogoPickerHomeTest
//
//  Created by Aliaksandr Akimau on 10/28/23.
//

import UIKit
import Kingfisher

final class LogoView: UIView {
    private struct Layout {
        static let cornerRadiusToLogoSizeRatio: CGFloat = 1 / 6
    }
    
    @IBOutlet weak var initialsLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!

    var initials: String? {
        didSet {
            initialsLabel.text = initials
        }
    }
    var style: LogoStyle? {
        didSet {
            updateLogoStyle()
        }
    }
    var shape: LogoShape = .circle {
        didSet {
            setNeedsLayout()
        }
    }
    
    private let maskLayer = CAShapeLayer()
    private var backgroundLayer: CALayer?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layoutLayers()
    }
    
    // MARK: - Private methods
    
    private func setupView() {
        layer.borderWidth = 1 / UIScreen.main.scale
        layer.borderColor = UIColor.gray.cgColor
        layer.masksToBounds = true
        updateLogoStyle()
    }
    
    private func updateLogoStyle() {
        if let style = style {
            switch style {
            case .default:
                imageView.image = nil
                backgroundColor = .clear
                backgroundLayer?.removeFromSuperlayer()
                let spaceLayer = SpaceLayer()
                layer.insertSublayer(spaceLayer, at: 0)
                backgroundLayer = spaceLayer
                spaceLayer.setNeedsDisplay()
                setNeedsLayout()
            case .solid(color: let color):
                imageView.image = nil
                backgroundLayer?.removeFromSuperlayer()
                backgroundColor = color
            case .gradient(startColor: let startColor, endColor: let endColor):
                imageView.image = nil
                backgroundColor = .clear
                backgroundLayer?.removeFromSuperlayer()
                let gradient = CAGradientLayer()
                gradient.colors = [startColor.cgColor, endColor.cgColor]
                gradient.startPoint = CGPoint(x: 0.5, y: 0.0)
                gradient.endPoint = CGPoint(x: 0.5, y: 1.0)
                layer.insertSublayer(gradient, at: 0)
                backgroundLayer = gradient
                setNeedsLayout()
            case .image(url: let imageUrl):
                backgroundColor = .clear
                backgroundLayer?.removeFromSuperlayer()
                imageView.kf.setImage(with: imageUrl)
            }
        }
    }
    
    private func layoutLayers() {
        backgroundLayer?.frame = bounds
        switch shape {
        case .roundedRect:
            layer.cornerRadius = bounds.width * Layout.cornerRadiusToLogoSizeRatio
        case .circle:
            layer.cornerRadius = bounds.width / 2
        }
    }
}
