//
//  ImagesCollectionViewCellViewModel.swift
//  LogoPickerHomeTest
//
//  Created by Aliaksandr Akimau on 10/31/23.
//

import Foundation

enum ImagesCollectionViewCellViewModel {
    case pickImageCell(onTapPick: () -> Void, onTapTakePhoto: () -> Void)
    case recentImageCell(imageUrl: URL)
}
