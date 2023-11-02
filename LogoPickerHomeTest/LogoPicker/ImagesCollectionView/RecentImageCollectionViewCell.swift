//
//  RecentImageCollectionViewCell.swift
//  LogoPickerHomeTest
//
//  Created by Aliaksandr Akimau on 10/31/23.
//

import UIKit
import Kingfisher

class RecentImageCollectionViewCell: UICollectionViewCell {
    private let imageView = UIImageView()
    
    var imageUrl: URL? {
        didSet {
            updateImage()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        createUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createUI() {
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = contentView.bounds
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.kf.cancelDownloadTask()
        imageView.image = nil
    }
    
    private func updateImage() {
        guard let imageUrl = imageUrl else {
            imageView.kf.cancelDownloadTask()
            imageView.image = nil
            return
        }
        imageView.kf.setImage(with: imageUrl)
    }
}
