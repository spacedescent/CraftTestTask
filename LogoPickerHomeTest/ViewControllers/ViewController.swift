//
//  ViewController.swift
//  LogoPickerHomeTest
//
//  Created by Aliaksandr Akimau on 10/28/23.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var logoView: LogoView!
    @IBOutlet weak var changeLogoButton: UIButton!
    
    private let defaultLogoStyle = LogoStyle.default(startColor: .systemBlue, endColor: .magenta)
    
    private var logoStyle: LogoStyle = .default(startColor: .systemBlue, endColor: .magenta)
    private var logoShape: LogoShape = .roundedRect {
        didSet {
            logoView.shape = logoShape
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        logoView.initials = "AS"
        logoView.shape = .roundedRect
        logoView.style = logoStyle
    }

    private func createPicker(sourceView: UIView) -> LogoPickerViewController? {
        let avatarPickerVC = LogoPickerViewController()
        avatarPickerVC.shape = logoShape
        avatarPickerVC.delegate = self
        avatarPickerVC.modalPresentationStyle = .popover
        guard let popover = avatarPickerVC.popoverPresentationController else { return nil }
        popover.delegate = self
        popover.sourceView = sourceView
        return avatarPickerVC
    }
    
    @IBAction func changeLogoButtonPressed(_ sender: Any) {
        guard let avatarPickerVC = createPicker(sourceView: changeLogoButton) else {
            return
        }
        avatarPickerVC.shape = logoView.shape
        avatarPickerVC.style = logoView.style ?? defaultLogoStyle
        self.present(avatarPickerVC, animated: true)
    }
    
    @IBAction func toggleLogoShapeButtonPressed(_ sender: Any) {
        logoShape = logoShape == .circle ? .roundedRect : .circle
    }
}

extension ViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}

extension ViewController: LogoPickerViewControllerDelegate {
    func pickerDidFinishPicking(_ picker: LogoPickerViewController) {
        picker.dismiss(animated: true)
    }
    
    func picker(_ picker: LogoPickerViewController, didPick result: LogoStyle) {
        logoView.style = result
    }
}
