//
//  RecentImagesService.swift
//  LogoPickerHomeTest
//
//  Created by Aliaksandr Akimau on 10/30/23.
//

import Foundation

protocol RecentImagesService {
    var recentImagesCount: Int { get }
    func getImageUrl(at index: Int) -> String?
    func add(imageUrl: String)
}

final class DefaultRecentImagesService: RecentImagesService {
    let imageUrlRepository: UrlRepository
    let maxRecentsCount: Int
    
    init(imageUrlRepository: UrlRepository,
         maxRecentsCount: Int = 10) {
        self.imageUrlRepository = imageUrlRepository
        self.maxRecentsCount = maxRecentsCount
    }
    
    var recentImagesCount: Int {
        imageUrlRepository.urlsCount
    }
    
    func getImageUrl(at index: Int) -> String? {
        imageUrlRepository.getUrl(at: index)
    }
    
    func add(imageUrl: String) {
        imageUrlRepository.remove(url: imageUrl)
        imageUrlRepository.add(url: imageUrl, at: 0)
        if imageUrlRepository.urlsCount > maxRecentsCount {
            let imageUrls = imageUrlRepository.getUrls()
            imageUrlRepository.save(urls: Array(imageUrls.prefix(maxRecentsCount)))
        }
    }
}
