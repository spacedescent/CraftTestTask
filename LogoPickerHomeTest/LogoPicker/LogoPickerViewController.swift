//
//  LogoPickerViewController.swift
//  LogoPickerHomeTest
//
//  Created by Aliaksandr Akimau on 10/29/23.
//

import UIKit
import PhotosUI

public protocol LogoPickerViewControllerDelegate {
    func picker(_ picker: LogoPickerViewController, didPick result: LogoStyle)
    func pickerDidFinishPicking(_ picker: LogoPickerViewController)
}

protocol LogoPickerView: AnyObject {
    func pickImage() async -> [PHPickerResult]
    func pickCameraPhoto() async -> UIImage?
    func notifyOnStyleChanged(_ style: LogoStyle)
    func notifyOnPickingFinished()
}

fileprivate struct ColorDefaults {
    static let background = UIColor.systemMint
    static let start = UIColor.systemBlue
    static let end = UIColor.systemGreen
}

public final class LogoPickerViewController: UIViewController, LogoPickerView {
    public var shape: LogoShape = .roundedRect
    public var style: LogoStyle = .default
    
    public var delegate: LogoPickerViewControllerDelegate?
    
    let viewModel: LogoPickerViewModel = LogoPickerViewModelImpl()
    
    private var imagePickerContinuation: CheckedContinuation<[PHPickerResult], Never>?
    private var cameraPickerContinuation: CheckedContinuation<UIImage?, Never>?

    // MARK: - UI Elements
    
    private func createLabel(title: String, fontSize: CGFloat) -> UILabel {
        let label = UILabel()
        label.font = .systemFont(ofSize: fontSize)
        label.text = title
        return label
    }
    
    private lazy var headerLabel = createLabel(title: NSLocalizedString("Logo Style", comment: ""), fontSize: 14)
    
    private lazy var tabBar: UITabBar = {
        let tabBar = UITabBar()
        tabBar.isTranslucent = false
        tabBar.clipsToBounds = true
        tabBar.layer.masksToBounds = true
        tabBar.layer.cornerRadius = 6
        tabBar.items = [
            UITabBarItem(title: LogoTabbarSelection.default.title, image: UIImage(systemName: "nosign"), tag: LogoTabbarSelection.default.tag),
            UITabBarItem(title: LogoTabbarSelection.solid.title, image: UIImage(systemName: "diamond.fill"), tag: LogoTabbarSelection.solid.tag),
            UITabBarItem(title: LogoTabbarSelection.gradient.title, image: UIImage(systemName: "diamond.bottomhalf.filled"), tag: LogoTabbarSelection.gradient.tag),
            UITabBarItem(title: LogoTabbarSelection.image.title, image: UIImage(systemName: "photo"), tag: LogoTabbarSelection.image.tag)
            ]
        tabBar.delegate = self
        return tabBar
    }()
    
    // MARK: - Color Picking Sections
    
    private func createColorWell() -> UIColorWell {
        let colorWell = UIColorWell()
        colorWell.supportsAlpha = false
        colorWell.addTarget(self, action: #selector(colorWellChanged(_:)), for: .valueChanged)
        return colorWell
    }
    
    private lazy var backgroundColorWell = createColorWell()
    private lazy var startColorWell = createColorWell()
    private lazy var endColorWell = createColorWell()
    
    private lazy var backgroundColorLabel = createLabel(title: NSLocalizedString("Background Color", comment: ""), fontSize: 13)
    private lazy var startColorLabel = createLabel(title: NSLocalizedString("Start Color", comment: ""), fontSize: 13)
    private lazy var endColorLabel = createLabel(title: NSLocalizedString("End Color", comment: ""), fontSize: 13)
    
    private lazy var solidSection: UIView = {
        let view = UIView()
        view.addSubview(self.backgroundColorLabel)
        view.addSubview(self.backgroundColorWell)
        return view
    }()
    
    private lazy var gradientSection: UIView = {
        let view = UIView()
        view.addSubview(self.startColorLabel)
        view.addSubview(self.endColorLabel)
        view.addSubview(self.startColorWell)
        view.addSubview(self.endColorWell)
        return view
    }()
    
    // MARK: - Images Section
    
    private lazy var imagesCollectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .vertical
        flowLayout.itemSize = .init(width: 128, height: 128)
        let imagesCollectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        imagesCollectionView.delegate = self
        imagesCollectionView.dataSource = self
        imagesCollectionView.delaysContentTouches = false
        imagesCollectionView.layer.cornerRadius = 6
        imagesCollectionView.register(SelectImageCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: SelectImageCollectionViewCell.self))
        imagesCollectionView.register(RecentImageCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: RecentImageCollectionViewCell.self))
        return imagesCollectionView
    }()
    
    private lazy var imageSection: UIView = {
        let view = UIView()
        view.addSubview(self.imagesCollectionView)
        return view
    }()

    // MARK: - View Controller cycle
    
    public override func loadView() {
        super.loadView()
        createUI()
        setupStylesUI()
        updateSections()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.view = self
    }
    
    public override func viewDidLayoutSubviews() {
        layoutSubviews()
        super.viewDidLayoutSubviews()
    }
    
    // MARK: - LogoPickerView methods
    
    @MainActor
    func pickImage() async -> [PHPickerResult] {
        await withCheckedContinuation { continuation in
            self.imagePickerContinuation = continuation
            
            var configuration = PHPickerConfiguration()
            configuration.selectionLimit = 1
            configuration.filter = .images
            let pickerVC = PHPickerViewController(configuration: configuration)
            pickerVC.delegate = self
            present(pickerVC, animated: true)
        }
    }
    
    @MainActor
    func pickCameraPhoto() async -> UIImage? {
        await withCheckedContinuation { continuation in
            self.cameraPickerContinuation = continuation
            
            let cameraPickerVC = UIImagePickerController()
            cameraPickerVC.sourceType = .camera
            cameraPickerVC.allowsEditing = true
            cameraPickerVC.delegate = self
            present(cameraPickerVC, animated: true)
        }
    }
    
    func notifyOnStyleChanged(_ style: LogoStyle) {
        delegate?.picker(self, didPick: style)
    }
    
    func notifyOnPickingFinished() {
        delegate?.pickerDidFinishPicking(self)
    }
    
    // MARK: - Private methods
    
    private func createUI() {
        view.backgroundColor = .systemGray6
        view.addSubview(headerLabel)
        view.addSubview(tabBar)
        view.addSubview(solidSection)
        view.addSubview(gradientSection)
        view.addSubview(imageSection)
    }
    
    private func layoutSubviews() {
        let padding: CGFloat = 20
        let innerPadding: CGFloat = 10
        let safeContentRegion = view.bounds.inset(by: view.safeAreaInsets)
        let contentRegion = safeContentRegion.insetBy(dx: padding, dy: padding)

        headerLabel.sizeToFit()
        
        let headerLabelFrame = CGRect(origin: CGPoint(x: contentRegion.midX - headerLabel.bounds.width / 2,
                                                      y: contentRegion.minY - innerPadding ),
                                      size: headerLabel.bounds.size)
        headerLabel.frame = headerLabelFrame
        
        let tabBarHeight = tabBar.intrinsicContentSize.height
        let tabBarFrame = CGRect(x: contentRegion.minX,
                                 y: headerLabelFrame.maxY + innerPadding,
                                 width: contentRegion.width,
                                 height: tabBarHeight)
        tabBar.frame = tabBarFrame
        
        let imagesSectionFrame = CGRect(x: contentRegion.minX,
                                        y: tabBarFrame.maxY + innerPadding,
                                        width: contentRegion.width,
                                        height: contentRegion.maxY - (tabBarFrame.maxY + innerPadding))
        imageSection.frame = imagesSectionFrame
        imagesCollectionView.frame = imageSection.bounds
        
        let colorWellSize = backgroundColorWell.intrinsicContentSize
        backgroundColorLabel.sizeToFit()
        let firstColorWellSectionHeight = max(backgroundColorLabel.bounds.height, colorWellSize.height)
        let solidSectionFrame = CGRect(x: contentRegion.minX,
                                       y: tabBarFrame.maxY + innerPadding,
                                       width: contentRegion.width,
                                       height: firstColorWellSectionHeight)
        solidSection.frame = solidSectionFrame
        backgroundColorLabel.frame.origin.x = 0
        backgroundColorLabel.center.y = colorWellSize.height / 2
        backgroundColorWell.frame.origin.x = solidSectionFrame.width - colorWellSize.width
        backgroundColorWell.center.y = colorWellSize.height / 2
        backgroundColorWell.frame.size = colorWellSize
        
        startColorLabel.sizeToFit()
        endColorLabel.sizeToFit()
        
        let sectionSpacing: CGFloat = 8
        let secondColorWellSectionHeight = max(endColorLabel.bounds.height, colorWellSize.height)
        let gradientSectionFrame = CGRect(x: contentRegion.minX,
                                          y: tabBarFrame.maxY + innerPadding,
                                          width: contentRegion.width,
                                          height: firstColorWellSectionHeight + sectionSpacing + secondColorWellSectionHeight)
        gradientSection.frame = gradientSectionFrame
        startColorLabel.frame.origin.x = 0
        startColorLabel.center.y = colorWellSize.height / 2
        startColorWell.frame.origin.x = solidSectionFrame.width - colorWellSize.width
        startColorWell.center.y = colorWellSize.height / 2
        startColorWell.frame.size = colorWellSize
        endColorLabel.frame.origin.x = 0
        endColorLabel.center.y = firstColorWellSectionHeight + sectionSpacing + colorWellSize.height / 2
        endColorWell.frame.origin.x = solidSectionFrame.width - colorWellSize.width
        endColorWell.center.y = firstColorWellSectionHeight + sectionSpacing + colorWellSize.height / 2
        endColorWell.frame.size = colorWellSize
    }
    
    private func setupStylesUI() {
        if case let .solid(color) = style {
            backgroundColorWell.selectedColor = color
        } else {
            backgroundColorWell.selectedColor = ColorDefaults.background
        }

        if case let .gradient(startColor, endColor) = style {
            startColorWell.selectedColor = startColor
            endColorWell.selectedColor = endColor
        } else {
            startColorWell.selectedColor = ColorDefaults.start
            endColorWell.selectedColor = ColorDefaults.end
        }

        if let itemToSelect = tabBar.items?.first(where: { $0.tag == style.tabBarSelection.tag }) {
            tabBar.selectedItem = itemToSelect
        }
    }
    
    private func updateSections() {
        guard let selectedItem = tabBar.selectedItem,
              let selectedSection = LogoTabbarSelection(rawValue: selectedItem.tag) else { return }
        solidSection.isHidden = selectedSection != .solid
        gradientSection.isHidden = selectedSection != .gradient
        imageSection.isHidden = selectedSection != .image
    }
    
    @objc func colorWellChanged(_ sender: UIColorWell) {
        switch sender {
        case backgroundColorWell:
            guard let solidColor = sender.selectedColor else { return }
            delegate?.picker(self, didPick: .solid(color: solidColor))
        case startColorWell, endColorWell:
            guard let startColor = startColorWell.selectedColor,
                  let endColor = endColorWell.selectedColor else {
                return
            }
            delegate?.picker(self, didPick: .gradient(startColor: startColor, endColor: endColor))
        default:
            break
        }
    }
}

extension LogoPickerViewController: UITabBarDelegate {
    public func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        updateSections()
        
        guard let selectedItem = tabBar.selectedItem,
              let selectedSection = LogoTabbarSelection(rawValue: selectedItem.tag) else { return }
        
        switch selectedSection {
        case .default:
            notifyOnStyleChanged(.default)
        case .solid:
            let solidColor = backgroundColorWell.selectedColor ?? .clear
            notifyOnStyleChanged(.solid(color: solidColor))
        case .gradient:
            let startColor = startColorWell.selectedColor ?? .clear
            let endColor = endColorWell.selectedColor ?? .clear
            notifyOnStyleChanged(.gradient(startColor: startColor, endColor: endColor))
        case .image:
            break
        }
    }
}

// MARK: - Image picker delegates

extension LogoPickerViewController: PHPickerViewControllerDelegate {
    public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        imagePickerContinuation?.resume(returning: results)
        imagePickerContinuation = nil
    }
}

extension LogoPickerViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        let image = info[.editedImage] as? UIImage
        cameraPickerContinuation?.resume(returning: image)
        cameraPickerContinuation = nil
    }
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        cameraPickerContinuation?.resume(returning: nil)
        cameraPickerContinuation = nil
    }
}

fileprivate enum LogoTabbarSelection: Int {
    case `default` = 0
    case solid
    case gradient
    case image
    
    var title: String {
        switch self {
        case .default:
            return NSLocalizedString("Default", comment: "")
        case .solid:
            return NSLocalizedString("Solid", comment: "")
        case .gradient:
            return NSLocalizedString("Gradient", comment: "")
        case .image:
            return NSLocalizedString("Image", comment: "")
        }
    }
    
    var tag: Int { rawValue }
}

fileprivate extension LogoStyle {
    var tabBarSelection: LogoTabbarSelection {
        switch self {
        case .default:
            return .default
        case .solid:
            return .solid
        case .gradient:
            return .gradient
        case .image:
            return .image
        }
    }
}
