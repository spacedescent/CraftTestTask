//
//  LogoPickerViewModel.swift
//  LogoPickerHomeTest
//
//  Created by Aliaksandr Akimau on 10/31/23.
//

import Foundation
import UIKit
import PhotosUI

protocol LogoPickerViewModel: AnyObject {
    var view: LogoPickerView? { get set }

    // Recent images collection view data source. May be extracted into a separate data source class id needed
    func numberOfItems(in section: Int) -> Int
    func cellViewModel(forItemAt indexPath: IndexPath) -> ImagesCollectionViewCellViewModel
    func didSelectItem(at indexPath: IndexPath)
}

fileprivate enum Constants {
    static let logoSize = CGSize(width: 512, height: 512)
}

final class LogoPickerViewModelImpl: LogoPickerViewModel {
    weak var view: LogoPickerView?
    
    private let recentImagesService: RecentImagesService
    
    // TODO: Get recentImagesService from view model's injection
    init(recentImagesService: RecentImagesService = DefaultRecentImagesService(imageUrlRepository: UrlUserDefaultsRepository(userDefaultsKey: "LogoPicker_recentImages"))) {
        self.recentImagesService = recentImagesService
    }
    
    // MARK: - Private methods
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    @MainActor private func notifyOnReadyImage(url: URL) async {
        recentImagesService.add(imageUrl: url.absoluteString)
        view?.notifyOnStyleChanged(.image(url: url))
        view?.notifyOnPickingFinished()
    }
    
    private func onPickImage() {
        Task(priority: .userInitiated) {
            let results = await view?.pickImage()
            guard let itemprovider = results?.first?.itemProvider else { return }
            guard let image = try? await loadImage(from: itemprovider) else { return }
            await processImage(image)
        }
    }
    
    private func onPickCameraPhoto() {
        Task(priority: .userInitiated) {
            guard let image = await view?.pickCameraPhoto() else { return }
            await processImage(image)
        }
    }
    
    private func processImage(_ image: UIImage) async {
        guard let cropRect = await view?.selectImageCropRegion(image: image) else { return }
        let croppedImage = image.croppedTo(rect: cropRect) ?? image
        let resizedImage = croppedImage.resizedTo(size: Constants.logoSize) ?? croppedImage
        let imageFileName = "\(NSUUID().uuidString.prefix(10)).jpg"
        do {
            guard let imageFileUrl = try await saveImage(resizedImage, fileName: imageFileName) else { return }
            await notifyOnReadyImage(url: imageFileUrl)
        }
        catch {
            // TODO: Handle image saving error if needed
        }
    }
    
    private func loadImage(from itemprovider: NSItemProvider) async throws -> UIImage? {
        try await withCheckedThrowingContinuation { continuation in
            guard itemprovider.canLoadObject(ofClass: UIImage.self) else {
                continuation.resume(returning: nil)
                return
            }
            _ = itemprovider.loadObject(ofClass: UIImage.self) { image, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let selectedImage = image as? UIImage
                continuation.resume(returning: selectedImage)
            }
        }
    }
    
    private func saveImage(_ image: UIImage, fileName: String) async throws -> URL? {
        let imageFileUrl = getDocumentsDirectory().appendingPathComponent(fileName)
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            return nil
        }
        try data.write(to: imageFileUrl)
        return imageFileUrl
    }
    
    // MARK: - Recents Collection View Datasource
    
    func numberOfItems(in section: Int) -> Int {
        return recentImagesService.recentImagesCount + 1
    }

    func cellViewModel(forItemAt indexPath: IndexPath) -> ImagesCollectionViewCellViewModel {
        if indexPath.item == 0 {
            return .pickImageCell(onTapPick: { [unowned self] in
                self.onPickImage()
            }, onTapTakePhoto: { [unowned self] in
                self.onPickCameraPhoto()
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
