//
//  LogoPickerViewModel.swift
//  LogoPickerHomeTest
//
//  Created by Aliaksandr Akimau on 10/31/23.
//

import Foundation
import UIKit

protocol LogoPickerViewModel: AnyObject {
    var view: LogoPickerView? { get set }
    func onPickTemporaryImage(url: URL?, error: Error?)
    func onPickCameraImage(image: UIImage)

    // Recent images collection view data source. May be extracted into a separate data source class id needed
    func numberOfItems(in section: Int) -> Int
    func cellViewModel(forItemAt indexPath: IndexPath) -> ImagesCollectionViewCellViewModel
    func didSelectItem(at indexPath: IndexPath)
}

final class LogoPickerViewModelImpl: LogoPickerViewModel {
    weak var view: LogoPickerView?
    
    private let recentImagesService: RecentImagesService
    
    // TODO: Get recentImagesService from view model's injection
    init(recentImagesService: RecentImagesService = DefaultRecentImagesService(imageUrlRepository: UrlUserDefaultsRepository(userDefaultsKey: "LogoPicker_recentImages"))) {
        self.recentImagesService = recentImagesService
    }
    
    func onPickTemporaryImage(url: URL?, error: Error?) {
        if let imageUrl = url {
            let fileManager = FileManager.default
            let newFileName = imageUrl.lastPathComponent
            let copiedImageUrl = getDocumentsDirectory().appendingPathComponent(newFileName)
            do {
                // We are already on a background queue
                try? fileManager.removeItem(at: copiedImageUrl)
                try fileManager.copyItem(at: imageUrl, to: copiedImageUrl)
            }
            catch {
                // TODO: handle error if needed
            }
            notifyOnReadyImage(url: copiedImageUrl)
        } else if let error = error {
            // TODO: add error handling - show notification/toast if something went wrong
        }
    }
    
    func onPickCameraImage(image: UIImage) {
        let imageFileName = "\(NSUUID().uuidString.prefix(10)).jpg"
        let imageFileUrl = getDocumentsDirectory().appendingPathComponent(imageFileName)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let data = image.jpegData(compressionQuality: 0.8) else { return }
            try? data.write(to: imageFileUrl)
            self?.notifyOnReadyImage(url: imageFileUrl)
        }
    }
    
    // MARK: - Private methods
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    private func notifyOnReadyImage(url: URL) {
        DispatchQueue.main.async { [weak self] in
            self?.recentImagesService.add(imageUrl: url.absoluteString)
            self?.view?.notifyOnStyleChanged(.image(url: url))
            self?.view?.notifyOnPickingFinished()
        }
    }
    
    // MARK: - Recents Collection View Datasource
    
    func numberOfItems(in section: Int) -> Int {
        return recentImagesService.recentImagesCount + 1
    }

    func cellViewModel(forItemAt indexPath: IndexPath) -> ImagesCollectionViewCellViewModel {
        if indexPath.item == 0 {
            return .pickImageCell(onTapPick: { [unowned self] in
                self.view?.openImagePicker()
            }, onTapTakePhoto: { [unowned self] in
                self.view?.openCameraPicker()
            })
        }
        let recentIndex = indexPath.item - 1
        guard let imagePath = recentImagesService.getImageUrl(at: recentIndex),
              let imageUrl = URL(string: imagePath) else {
            assertionFailure("Can't retrieve recent image URL by index: \(recentIndex)")
            return .recentImageCell(imageUrl:URL(string: "")!)
        }
        return .recentImageCell(imageUrl: imageUrl)
    }
    
    func didSelectItem(at indexPath: IndexPath) {
        guard indexPath.item != 0 else { return }
        let recentIndex = indexPath.item - 1
        guard let imagePath = recentImagesService.getImageUrl(at: recentIndex),
              let imageUrl = URL(string: imagePath) else {
            assertionFailure("Can't retrieve recent image URL by index: \(recentIndex)")
            return
        }
        recentImagesService.add(imageUrl: imagePath)
        view?.notifyOnStyleChanged(.image(url: imageUrl))
        view?.notifyOnPickingFinished()
    }
}
