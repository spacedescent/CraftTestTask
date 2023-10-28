//
//  SelectImageCollectionViewCell.swift
//  LogoPickerHomeTest
//
//  Created by Aliaksandr Akimau on 10/31/23.
//

import UIKit

class SelectImageCollectionViewCell: UICollectionViewCell {
    var onTap: (() -> Void)?
    
    private let button = UIButton(type: .custom)

    override init(frame: CGRect) {
        super.init(frame: frame)
        createUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createUI() {

        button.setImage(.init(systemName: "plus"), for: .normal)
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        button.imageEdgeInsets = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 6
        button.layer.borderColor = UIColor.gray.cgColor
        contentView.addSubview(button)
        button.addTarget(self, action: #selector(selectButtonPressed(_:)), for: .touchUpInside)
    }
    
    override func layoutSubviews() {
        button.frame = bounds.insetBy(dx: 10, dy: 10)
        super.layoutSubviews()
    }
    
    @IBAction func selectButtonPressed(_ sender: Any) {
        onTap?()
    }
}
