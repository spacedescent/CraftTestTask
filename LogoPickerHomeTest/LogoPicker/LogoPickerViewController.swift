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
    func selectImageCropRegion(image: UIImage) async -> CGRect?
    func notifyOnStyleChanged(_ style: LogoStyle)
    func notifyOnPickingFinished()
}

fileprivate struct ColorDefaults {
    static let defaultStart = UIColor.systemBlue
    static let defaultEnd = UIColor.magenta
    static let background = UIColor.systemMint
    static let gradientStart = UIColor.systemBlue
    static let gradientEnd = UIColor.systemGreen
}

public final class LogoPickerViewController: UIViewController, LogoPickerView {
    public var shape: LogoShape = .roundedRect
    public var style: LogoStyle = .default(startColor: .black, endColor: .white)
    
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
    private lazy var defaultStartColorWell = createColorWell()
    private lazy var defaultEndColorWell = createColorWell()
    private lazy var gradientStartColorWell = createColorWell()
    private lazy var gradientEndColorWell = createColorWell()
    
    private lazy var backgroundColorLabel = createLabel(title: NSLocalizedString("Background Color", comment: ""), fontSize: 13)
    private lazy var defaultStartColorLabel = createLabel(title: NSLocalizedString("Start Color", comment: ""), fontSize: 13)
    private lazy var defaultEndColorLabel = createLabel(title: NSLocalizedString("End Color", comment: ""), fontSize: 13)
    private lazy var gradientStartColorLabel = createLabel(title: NSLocalizedString("Start Color", comment: ""), fontSize: 13)
    private lazy var gradientEndColorLabel = createLabel(title: NSLocalizedString("End Color", comment: ""), fontSize: 13)
    
    private lazy var defaultSection: UIView = {
        let view = UIView()
        view.addSubview(self.defaultStartColorLabel)
        view.addSubview(self.defaultEndColorLabel)
        view.addSubview(self.defaultStartColorWell)
        view.addSubview(self.defaultEndColorWell)
        return view
    }()
    
    private lazy var solidSection: UIView = {
        let view = UIView()
        view.addSubview(self.backgroundColorLabel)
        view.addSubview(self.backgroundColorWell)
        return view
    }()
    
    private lazy var gradientSection: UIView = {
        let view = UIView()
        view.addSubview(self.gradientStartColorLabel)
        view.addSubview(self.gradientEndColorLabel)
        view.addSubview(self.gradientStartColorWell)
        view.addSubview(self.gradientEndColorWell)
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
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        imagePickerContinuation?.resume(returning: [])
        imagePickerContinuation = nil
        cameraPickerContinuation?.resume(returning: nil)
        cameraPickerContinuation = nil
    }
    
    // MARK: - LogoPickerView methods
    
    @MainActor
    func pickImage() async -> [PHPickerResult] {
        await withCheckedContinuation { continuation in
            // release last continuation if previously presenteed image picker was dismissed without calling delegate method: by swiping down the popover or tapping outside
            imagePickerContinuation?.resume(returning: [])
            imagePickerContinuation = continuation
            
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
            // release last continuation if previously presenteed camera picker was dismissed without calling delegate method: by swiping down the popover or tapping outside
            cameraPickerContinuation?.resume(returning: nil)
            cameraPickerContinuation = continuation
            let cameraPickerVC = UIImagePickerController()
            cameraPickerVC.sourceType = .camera
            cameraPickerVC.delegate = self
            present(cameraPickerVC, animated: true)
        }
    }
    
    @MainActor
    func selectImageCropRegion(image: UIImage) async -> CGRect? {
        await withCheckedContinuation { continuation in
            let imageCropVC = ImageResizeViewController(nibName: String(describing: ImageResizeViewController.self), bundle: nil)
            imageCropVC.modalPresentationStyle = .fullScreen
            imageCropVC.isModalInPresentation = true
            imageCropVC.onCancel = { [unowned self] in
                continuation.resume(returning: nil)
                self.dismiss(animated: true)
            }
            imageCropVC.onDone = { [unowned self] rect in
                continuation.resume(returning: rect)
                self.dismiss(animated: true)
            }
            imageCropVC.originalImage = image
            imageCropVC.maskShape = shape
            present(imageCropVC, animated: true)
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
        view.addSubview(defaultSection)
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
        
        gradientStartColorLabel.sizeToFit()
        gradientEndColorLabel.sizeToFit()
        
        let sectionSpacing: CGFloat = 8
        let secondColorWellSectionHeight = max(gradientEndColorLabel.bounds.height, colorWellSize.height)
        let gradientSectionFrame = CGRect(x: contentRegion.minX,
                                          y: tabBarFrame.maxY + innerPadding,
                                          width: contentRegion.width,
                                          height: firstColorWellSectionHeight + sectionSpacing + secondColorWellSectionHeight)
        gradientSection.frame = gradientSectionFrame
        gradientStartColorLabel.frame.origin.x = 0
        gradientStartColorLabel.center.y = colorWellSize.height / 2
        gradientStartColorWell.frame.origin.x = solidSectionFrame.width - colorWellSize.width
        gradientStartColorWell.center.y = colorWellSize.height / 2
        gradientStartColorWell.frame.size = colorWellSize
        gradientEndColorLabel.frame.origin.x = 0
        gradientEndColorLabel.center.y = firstColorWellSectionHeight + sectionSpacing + colorWellSize.height / 2
        gradientEndColorWell.frame.origin.x = solidSectionFrame.width - colorWellSize.width
        gradientEndColorWell.center.y = firstColorWellSectionHeight + sectionSpacing + colorWellSize.height / 2
        gradientEndColorWell.frame.size = colorWellSize
        
        // No need to calculate "Default" section separately, because it's identical to Gradient section
        defaultSection.frame = gradientSection.frame
        defaultStartColorLabel.frame = gradientStartColorLabel.frame
        defaultStartColorWell.frame = gradientStartColorWell.frame
        defaultEndColorLabel.frame = gradientEndColorLabel.frame
        defaultEndColorWell.frame = gradientEndColorWell.frame
    }
    
    private func setupStylesUI() {
        if case let .gradient(startColor, endColor) = style {
            defaultStartColorWell.selectedColor = startColor
            defaultEndColorWell.selectedColor = endColor
        } else {
            defaultStartColorWell.selectedColor = ColorDefaults.defaultStart
            defaultEndColorWell.selectedColor = ColorDefaults.defaultEnd
        }
        
        if case let .solid(color) = style {
            backgroundColorWell.selectedColor = color
        } else {
            backgroundColorWell.selectedColor = ColorDefaults.background
        }

        if case let .gradient(startColor, endColor) = style {
            gradientStartColorWell.selectedColor = startColor
            gradientEndColorWell.selectedColor = endColor
        } else {
            gradientStartColorWell.selectedColor = ColorDefaults.gradientStart
            gradientEndColorWell.selectedColor = ColorDefaults.gradientEnd
        }

        if let itemToSelect = tabBar.items?.first(where: { $0.tag == style.tabBarSelection.tag }) {
            tabBar.selectedItem = itemToSelect
        }
    }
    
    private func updateSections() {
        guard let selectedItem = tabBar.selectedItem,
              let selectedSection = LogoTabbarSelection(rawValue: selectedItem.tag) else { return }
        defaultSection.isHidden = selectedSection != .default
        solidSection.isHidden = selectedSection != .solid
        gradientSection.isHidden = selectedSection != .gradient
        imageSection.isHidden = selectedSection != .image
    }
    
    @objc func colorWellChanged(_ sender: UIColorWell) {
        switch sender {
        case defaultStartColorWell, defaultEndColorWell:
            guard let startColor = defaultStartColorWell.selectedColor,
                  let endColor = defaultEndColorWell.selectedColor else {
                return
            }
            delegate?.picker(self, didPick: .default(startColor: startColor, endColor: endColor))
        case backgroundColorWell:
            guard let solidColor = sender.selectedColor else { return }
            delegate?.picker(self, didPick: .solid(color: solidColor))
        case gradientStartColorWell, gradientEndColorWell:
            guard let startColor = gradientStartColorWell.selectedColor,
                  let endColor = gradientEndColorWell.selectedColor else {
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
            let startColor = defaultStartColorWell.selectedColor ?? .clear
            let endColor = defaultEndColorWell.selectedColor ?? .clear
            notifyOnStyleChanged(.default(startColor: startColor, endColor: endColor))
        case .solid:
            let solidColor = backgroundColorWell.selectedColor ?? .clear
            notifyOnStyleChanged(.solid(color: solidColor))
        case .gradient:
            let startColor = gradientStartColorWell.selectedColor ?? .clear
            let endColor = gradientEndColorWell.selectedColor ?? .clear
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
        let image = info[.originalImage] as? UIImage
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
