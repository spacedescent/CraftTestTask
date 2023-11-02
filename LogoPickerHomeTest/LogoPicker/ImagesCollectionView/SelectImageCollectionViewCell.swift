//
//  SelectImageCollectionViewCell.swift
//  LogoPickerHomeTest
//
//  Created by Aliaksandr Akimau on 10/31/23.
//

import UIKit

class SelectImageCollectionViewCell: UICollectionViewCell {
    var onTapPick: (() -> Void)?
    var onTapTakePhoto: (() -> Void)?

    private lazy var galleryButton = createButton()
    private lazy var cameraButton = createButton()

    override init(frame: CGRect) {
        super.init(frame: frame)
        createUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createButton() -> UIButton {
        let button = UIButton(type: .custom)
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        button.imageView?.contentMode = .scaleAspectFit
        button.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 6
        button.layer.borderColor = UIColor.gray.cgColor
        return button
    }
    
    private func createUI() {
        galleryButton.setImage(.init(systemName: "plus"), for: .normal)
        contentView.addSubview(galleryButton)
        galleryButton.addTarget(self, action: #selector(selectButtonPressed(_:)), for: .touchUpInside)
        
        cameraButton.setImage(.init(systemName: "camera"), for: .normal)
        contentView.addSubview(cameraButton)
        cameraButton.addTarget(self, action: #selector(cameraButtonPressed(_:)), for: .touchUpInside)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let contentRect = contentView.bounds
        let (upperHalfRect, lowerHalfRect) = contentRect.divided(atDistance: contentRect.height / 2, from: .minYEdge)
        let cameraButtonFrame = upperHalfRect.divided(atDistance: upperHalfRect.width / 2, from: .minXEdge).slice.insetBy(dx: 5, dy: 5)
        let galleryButtonFrame = lowerHalfRect.divided(atDistance: lowerHalfRect.width / 2, from: .minXEdge).remainder.insetBy(dx: 5, dy: 5)
        cameraButton.frame = cameraButtonFrame
        galleryButton.frame = galleryButtonFrame
    }
    
    @objc func selectButtonPressed(_ sender: Any) {
        onTapPick?()
    }
    
    @objc func cameraButtonPressed(_ sender: Any) {
        onTapTakePhoto?()
    }
}
