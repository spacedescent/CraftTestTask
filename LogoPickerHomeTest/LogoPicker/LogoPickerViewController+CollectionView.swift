//
//  LogoPickerViewController+Layout.swift
//  LogoPickerHomeTest
//
//  Created by Aliaksandr Akimau on 11/1/23.
//

import UIKit

extension LogoPickerViewController: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numberOfItems(in: section)
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellViewModel = viewModel.cellViewModel(forItemAt: indexPath)
        switch cellViewModel {
        case .pickImageCell(onTapPick: let onTapPick, onTapTakePhoto: let onTapTakePhoto):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SelectImageCollectionViewCell", for: indexPath) as! SelectImageCollectionViewCell
            cell.onTapPick = onTapPick
            cell.onTapTakePhoto = onTapTakePhoto
            return cell
        case .recentImageCell(imageUrl: let imageUrl):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RecentImageCollectionViewCell", for: indexPath) as! RecentImageCollectionViewCell
            cell.imageUrl = imageUrl
            return cell
        }
    }
}

extension LogoPickerViewController: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.didSelectItem(at: indexPath)
    }
}
