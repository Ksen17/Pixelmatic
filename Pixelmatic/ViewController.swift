//
//  ViewController.swift
//  Pixelmatic
//
//  Created by Ilia on 15/02/2018.
//  Copyright © 2018 Ilia Stukalov. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    @IBOutlet var backImage: UIView!
    @IBOutlet var slider: UISlider!
    @IBOutlet var imageView: UIImageView!
    
    @IBOutlet var segments: UISegmentedControl!
    
    var image: UIImage? = UIImage()
    
    var parts: [PartView] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            self.imageView.image = self.image?.pixellated(scale: Int(self.slider.value))
            for p in parts {
                p.removeFromSuperview()
            }
            parts = []
        } else {
            self.imageView.image = self.image
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if segments.selectedSegmentIndex == 0 {
            getImageFromLibrary()
            for p in parts {
                p.removeFromSuperview()
            }
            parts = []
        }else{
            addPart(touch: touches.first)
        }
    }
    
    func addPart(touch: UITouch?){
        let touchLocation = touch?.location(in: self.backImage)
        let bFrame = self.view.convert(backImage.frame, from: backImage.superview)
        
        // Check if the touch is inside the obstacle view
        if bFrame.contains(touchLocation!) {
            let point = CGPoint(x: (touch?.location(in: self.backImage))!.x - 30.0, y: (touch?.location(in: self.backImage))!.y - 30.0)
            let rect = CGRect(origin: point, size: CGSize(width: 60.0, height: 60.0))
            let img: UIImage = self.imageView.snapshotWithoutClippingBounds(usingRect: rect)!
            let part = PartView(frame: rect)
            part.originalImage = img
            part.image = part.originalImage.pixellated(scale: Int(self.slider.value))
            part.contentMode = .scaleToFill
            self.backImage.addSubview(part)
            self.parts.append(part)
        }
        
    }
    
    func getImageFromLibrary() {
        let controller = UIImagePickerController()
        controller.sourceType = .photoLibrary
        controller.delegate = self
        present(controller, animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        image = info[UIImagePickerControllerOriginalImage] as? UIImage
        imageView.image = self.image?.pixellated(scale: Int(self.slider.value))
        dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func rotate(_ sender: Any) {
        if self.image != nil {
            self.image = imageRotatedByDegrees(oldImage: self.image!, deg: 90.0)
            if segments.selectedSegmentIndex == 0 {
                self.imageView.image = self.image?.pixellated(scale: Int(self.slider.value))
            } else {
                self.imageView.image = self.image
            }
        }
    }
    
    func imageRotatedByDegrees(oldImage: UIImage, deg degrees: CGFloat) -> UIImage {
        //Calculate the size of the rotated view's containing box for our drawing space
        let rotatedViewBox: UIView = UIView(frame: CGRect(x: 0, y: 0, width: oldImage.size.width, height: oldImage.size.height))
        let t: CGAffineTransform = CGAffineTransform(rotationAngle: degrees * CGFloat.pi / 180)
        rotatedViewBox.transform = t
        let rotatedSize: CGSize = rotatedViewBox.frame.size
        //Create the bitmap context
        UIGraphicsBeginImageContext(rotatedSize)
        let bitmap: CGContext = UIGraphicsGetCurrentContext()!
        //Move the origin to the middle of the image so we will rotate and scale around the center.
        bitmap.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
        //Rotate the image context
        bitmap.rotate(by: (degrees * CGFloat.pi / 180))
        //Now, draw the rotated/scaled image into the context
        bitmap.scaleBy(x: 1.0, y: -1.0)
        bitmap.draw(oldImage.cgImage!, in: CGRect(x: -oldImage.size.width / 2, y: -oldImage.size.height / 2, width: oldImage.size.width, height: oldImage.size.height))
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
    
    @IBAction func valueChanged(_ sender: UISlider) {
        if segments.selectedSegmentIndex == 0 {
            self.imageView.image = self.image?.pixellated(scale: Int(self.slider.value))
        } else {
            for p in parts {
                p.image = p.originalImage.pixellated(scale: Int(self.slider.value))
            }
        }
    }
    
    @IBAction func share(_ sender: Any) {
        let img = imageWithView(inView: self.backImage)
        let activityViewController : UIActivityViewController = UIActivityViewController(
            activityItems: ["Created by Pixelmatic", img as Any], applicationActivities: nil)
        
//        // This lines is for the popover you need to show in iPad
//        activityViewController.popoverPresentationController?.sourceView = (sender as! UIButton)
//
//        // This line remove the arrow of the popover to show in iPad
//        activityViewController.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.any
//        activityViewController.popoverPresentationController?.sourceRect = CGRect(x: 150, y: 150, width: 0, height: 0)
        
        
        
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    func imageWithView(inView: UIView) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(inView.bounds.size, inView.isOpaque, 0.0)
        defer { UIGraphicsEndImageContext() }
        if let context = UIGraphicsGetCurrentContext() {
            inView.layer.render(in: context)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            return image
        }
        return nil
    }
}

extension UIImage {
    func pixellated(scale: Int = 8) -> UIImage? {
        guard let
            ciImage = UIKit.CIImage(image: self),
            let filter = CIFilter(name: "CIPixellate") else { return nil }
        filter.setValue(ciImage, forKey: "inputImage")
        filter.setValue(scale, forKey: "inputScale")
        guard let output = filter.outputImage else { return nil }
        return UIImage(ciImage: output)
    }
}

extension UIView {
    func snapshotWithoutClippingBounds(usingRect snapshotRect: CGRect) -> UIImage? {
        UIGraphicsBeginImageContext(snapshotRect.size)
        guard let currentContext = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return nil
        }
        currentContext.translateBy(x: -snapshotRect.origin.x, y: -snapshotRect.origin.y)
        layer.render(in: currentContext)
        guard let snap = UIGraphicsGetImageFromCurrentImageContext() else {
            UIGraphicsEndImageContext()
            return nil
        }
        UIGraphicsEndImageContext()
        return snap
    }
}



