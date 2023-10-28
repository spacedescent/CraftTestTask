//
//  UrlRepository.swift
//  LogoPickerHomeTest
//
//  Created by Aliaksandr Akimau on 10/30/23.
//

import Foundation

protocol UrlRepository {
    var urlsCount: Int { get }
    func getUrls() -> [String]
    func getUrl(at index: Int) -> String?
    func save(urls: [String])
    func add(url: String, at index: Int)
    func remove(url: String)
}

final class UrlUserDefaultsRepository: UrlRepository {
    private let userDefaults: UserDefaults
    private let userDefaultsKey: String

    init(userDefaults: UserDefaults = .standard,
        userDefaultsKey: String) {
        self.userDefaults = userDefaults
        self.userDefaultsKey = userDefaultsKey
    }
    
    var urlsCount: Int {
        getUrls().count
    }
    
    func getUrls() -> [String] {
        userDefaults.array(forKey: userDefaultsKey) as? [String] ?? []
    }
    
    func getUrl(at index: Int) -> String? {
        let urls = getUrls()
        guard index >= 0, index < urls.count else { return nil }
        return urls[index]
    }
    
    func save(urls: [String]) {
        userDefaults.set(urls, forKey: userDefaultsKey)
    }
    
    func add(url: String, at index: Int) {
        var urls = getUrls()
        urls.insert(url, at: index)
        userDefaults.set(urls, forKey: userDefaultsKey)
    }
    
    func remove(url: String) {
        var urls = getUrls()
        urls.removeAll(where: { $0 == url })
        userDefaults.set(urls, forKey: userDefaultsKey)
    }
}
