//
//  ImageResizeViewController.swift
//  LogoPickerHomeTest
//
//  Created by Aliaksandr Akimau on 11/2/23.
//

import UIKit

class ImageResizeViewController: UIViewController {
    var onCancel: (() -> Void)?
    var onDone: ((CGRect) -> Void)?
    var originalImage: UIImage?
    var maskShape: LogoShape = .circle
    
    @IBOutlet weak var squareView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var zoomSlider: UISlider!
    @IBOutlet var panRecognizer: UIPanGestureRecognizer!
    @IBOutlet var pinchRecognizer: UIPinchGestureRecognizer!
    
    private var cropRect: CGRect = .zero

    private var maskLayer: CropMaskLayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.isUserInteractionEnabled = true
        imageView.image = originalImage
        pinchRecognizer.addTarget(self, action: #selector(pinchHandler))
        panRecognizer.addTarget(self, action: #selector(panHandler))
        
#if targetEnvironment(macCatalyst)
        pinchRecognizer.isEnabled = false
#else
        zoomSlider.isHidden = true
#endif

        let maskLayer = CropMaskLayer()
        maskLayer.maskShape = maskShape
        squareView.layer.addSublayer(maskLayer)
        self.maskLayer = maskLayer
        maskLayer.setNeedsDisplay()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let originalImage = originalImage {
            let imageSize = originalImage.size
            let squareViewMinSide = min(squareView.bounds.width, squareView.bounds.height)
            let aspectFitPointScale = squareViewMinSide / max(imageSize.width, imageSize.height)
            let unscaledImageVibislePointSize = CGSize(width: imageSize.width * aspectFitPointScale, height: imageSize.height * aspectFitPointScale)
            let cropLayerSide = min(unscaledImageVibislePointSize.width, unscaledImageVibislePointSize.height)
            if maskLayer?.logoSize != cropLayerSide {
                maskLayer?.logoSize = cropLayerSide
            }
        }
        maskLayer?.frame = squareView.bounds
        maskLayer?.setNeedsDisplay()
    }
    
    @IBAction func cancelButtonDidPress(_ sender: Any) {
        onCancel?()
    }
    
    @IBAction func doneButtonDidPress(_ sender: Any) {
        guard let originalImage = originalImage else { return }
        let scale = imageView.transform.a
        let translationX = imageView.transform.tx
        let translationY = imageView.transform.ty
        let imageSize = originalImage.size

        let squareViewMinSide = min(squareView.bounds.width, squareView.bounds.height)
        let aspectFitPointScale = squareViewMinSide / max(imageSize.width, imageSize.height)
        let unscaledImageVibislePointSize = CGSize(width: imageSize.width * aspectFitPointScale, height: imageSize.height * aspectFitPointScale)
        let cropLayerSide = min(unscaledImageVibislePointSize.width, unscaledImageVibislePointSize.height)

        let cropRectSideInImageCoordinates = cropLayerSide / (aspectFitPointScale * scale)
        
        let cropRectCenterInImageViewCoordinates = CGPoint(x: -translationX / scale,
                                                           y: -translationY / scale)
        
        let cropRectCenterInImageCoordinates = CGPoint(x: cropRectCenterInImageViewCoordinates.x / aspectFitPointScale,
                                                       y: cropRectCenterInImageViewCoordinates.y / aspectFitPointScale)
        let cropRectInImageCoordinates = CGRect(x: imageSize.width / 2 + cropRectCenterInImageCoordinates.x - cropRectSideInImageCoordinates / 2,
                                      y: imageSize.height / 2 + cropRectCenterInImageCoordinates.y - cropRectSideInImageCoordinates / 2,
                                      width: cropRectSideInImageCoordinates,
                                      height: cropRectSideInImageCoordinates)
        
        onDone?(cropRectInImageCoordinates)
    }
    
   
    
    private func resetLayoutIfOutOfBounds() {
        var newTrasform: CGAffineTransform?
        let currentScale = imageView.transform.a
        if currentScale < 1 {
            newTrasform = imageView.transform.scaledBy(x: 1 / currentScale, y: 1 / currentScale)
        }
        // TODO: implement the same for translation. Now skipping because a lot of calculations & debug needed.
        UIView.animate(withDuration: 0.3) {
            if let newTrasform = newTrasform {
                self.imageView.transform = newTrasform
            }
        }
    }
    
    @IBAction func zoomSliderValueChanged(_ sender: UISlider) {
        let currentScale = imageView.transform.a
        let newScale = CGFloat(sender.value)
        let scaleFactor = newScale / currentScale
        imageView.transform = imageView.transform.scaledBy(x: scaleFactor, y: scaleFactor)
    }
    
    @objc func pinchHandler(gestureRecognizer : UIPinchGestureRecognizer) {
        switch gestureRecognizer.state {
        case .changed:
            imageView.transform = imageView.transform.scaledBy(x: gestureRecognizer.scale, y: gestureRecognizer.scale)
            gestureRecognizer.scale = 1
            zoomSlider.value = Float(max(min(10, imageView.transform.a), 1))
        case .ended, .cancelled, .failed:
            resetLayoutIfOutOfBounds()
        default: break
        }
    }
    
    @objc func panHandler(gestureRecognizer : UIPanGestureRecognizer) {
        switch gestureRecognizer.state {
        case .changed:
            let translation = gestureRecognizer.translation(in: self.imageView)
            imageView.transform = imageView.transform.translatedBy(x: translation.x, y: translation.y)
            gestureRecognizer.setTranslation(CGPoint.zero, in: self.imageView)
        case .ended, .cancelled, .failed:
            resetLayoutIfOutOfBounds()
        default: break
        }
    }
}


extension ImageResizeViewController: UIGestureRecognizerDelegate {
    @objc func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
