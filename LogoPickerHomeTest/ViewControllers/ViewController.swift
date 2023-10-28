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
    
    var logoStyle: LogoStyle = .solid(color: .systemMint)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        logoView.initials = "AS"
        logoView.shape = .roundedRect
        logoView.style = logoStyle
    }

    private func createPicker(sourceView: UIView) -> LogoPickerViewController? {
//        guard let avatarPickerVC = storyboard?.instantiateViewController(withIdentifier: "AvatarPickerViewController") as? LogoPickerViewController2 else {
//            return nil
//        }
        let avatarPickerVC = LogoPickerViewController()
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
        avatarPickerVC.style = logoView.style ?? .default
        self.present(avatarPickerVC, animated: true)
    }
    
    @IBAction func toggleLogoShapeButtonPressed(_ sender: Any) {
        logoView.shape = logoView.shape == .circle ? .roundedRect : .circle
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
