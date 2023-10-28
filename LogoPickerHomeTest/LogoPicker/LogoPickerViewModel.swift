//
//  LogoPickerViewModel.swift
//  LogoPickerHomeTest
//
//  Created by Aliaksandr Akimau on 10/31/23.
//

import Foundation

protocol LogoPickerViewModel: AnyObject {
    var view: LogoPickerView? { get set }
    func onPickTemporaryImage(url: URL?, error: Error?)
    
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
            let copiedImageUrl = fileManager.temporaryDirectory.appendingPathComponent(newFileName)
            do {
                try? fileManager.removeItem(at: copiedImageUrl)
                try fileManager.copyItem(at: imageUrl, to: copiedImageUrl)
                recentImagesService.add(imageUrl: copiedImageUrl.absoluteString)
            }
            catch {
                // TODO: handle error if needed
            }
            DispatchQueue.main.async { [weak self] in
                self?.view?.notifyOnStyleChanged(.image(url: copiedImageUrl))
                self?.view?.notifyOnPickingFinished()
            }
        } else if let error = error {
            // TODO: add error handling - show notification/toast if something went wrong
        }
    }
    
    // MARK: - Recents Collection View Datasource
    
    func numberOfItems(in section: Int) -> Int {
        return recentImagesService.recentImagesCount + 1
    }

    func cellViewModel(forItemAt indexPath: IndexPath) -> ImagesCollectionViewCellViewModel {
        if indexPath.item == 0 {
            return .pickImageCell { [unowned self] in
                self.view?.openImagePicker()
            }
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
