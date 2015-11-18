//
//  ViewController.swift
//  ocr
//
//  Created by Trinh Tran on 11/16/15.
//  Copyright © 2015 Trinh Tran. All rights reserved.
//

import UIKit
import GPUImage
import CoreGraphics

class ViewController: UIViewController, UINavigationControllerDelegate {

    @IBOutlet weak var btScan: UIBarButtonItem!
    @IBOutlet weak var imageAvatar: UIImageView!
    

    @IBOutlet weak var processImage: UIImageView!
    @IBOutlet weak var lbProcessing: UILabel!

    @IBOutlet weak var tv: UITextView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.lbProcessing.text = ""
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func pressOnScan(sender: AnyObject) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .Camera
        imagePicker.cameraDevice = .Front
        
        let overlayView = UIView(frame: CGRect(x: 1024/2 - 600/2 , y: 768/2 - 310/2, width: 600, height: 310))
        overlayView.layer.borderColor = UIColor.redColor().CGColor
        overlayView.layer.borderWidth = 10
        overlayView.layer.cornerRadius = 4
        overlayView.backgroundColor = UIColor.clearColor()
        imagePicker.cameraOverlayView = overlayView
        
        self.lbProcessing.text = ""
        self.tv.text = ""
        
        self.presentViewController(imagePicker, animated: true, completion: nil)
    
    }
    
    func scaleImage(image: UIImage, maxDimension: CGFloat) -> UIImage {
        
        var scaledSize = CGSizeMake(maxDimension, maxDimension)
        var scaleFactor:CGFloat
        
        if image.size.width > image.size.height {
            scaleFactor = image.size.height / image.size.width
            scaledSize.width = maxDimension
            scaledSize.height = scaledSize.width * scaleFactor
        } else {
            scaleFactor = image.size.width / image.size.height
            scaledSize.height = maxDimension
            scaledSize.width = scaledSize.height * scaleFactor
        }
        
        UIGraphicsBeginImageContext(scaledSize)
        image.drawInRect(CGRectMake(0, 0, scaledSize.width, scaledSize.height))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage
    }
//    
    func processingImage(sourceImage: UIImage) -> UIImage{
        let stillImageFilter = GPUImageAdaptiveThresholdFilter()
        stillImageFilter.blurRadiusInPixels = 13
        let filteredImage = stillImageFilter.imageByFilteringImage(sourceImage)
        
        return filteredImage
    }
    
    func performImageRecognition(image: UIImage) {
        // 1
        let tesseract = G8Tesseract()
        tesseract.setVariablesFromDictionary(["tessedit_char_whitelist":"-:/0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"])

        // 2
        tesseract.language = "eng"
        
        // 3
        tesseract.engineMode = .TesseractCubeCombined
        
        // 4
        tesseract.pageSegmentationMode = .Auto
        
        // 5
        tesseract.maximumRecognitionTime = 60.0
        
        // 6
        tesseract.image = image.g8_blackAndWhite()
        
        
        tesseract.recognize()
        print(tesseract.characterBoxes)
        print(tesseract.characterChoices)
        print(tesseract.characterChoices)
        
        print(tesseract.recognizedText)
        self.lbProcessing.text = ""
        self.tv.text = tesseract.recognizedText;
        
        self.btScan.enabled = true
        
        print(tesseract.progress)
        
    }
    
    
    
}
extension ViewController: UIImagePickerControllerDelegate {
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        let selectedPhoto = info[UIImagePickerControllerOriginalImage] as! UIImage
        
        let imageCrop = cropImage(selectedPhoto)
        let rotatedPhoto = imageCrop.imageRotatedByDegrees(180, flip: false)
        let scaledImage = rotatedPhoto.imageScaledToSize(self.imageAvatar.frame.size, isOpaque: true)
        
        
        self.imageAvatar.image = rotatedPhoto
        self.processImage.image = nil
        
        self.btScan.enabled = false
        
        self.lbProcessing.text = "Processing ..."
        dismissViewControllerAnimated(true, completion: {
            let processImage = self.processingImage(scaledImage)
//            let openCVImage = OpenCVWrapper.processImageWithOpenCV(scaledImage)
            
            self.processImage.image = processImage
            
            self.performImageRecognition(processImage)
            
        })
    }

    func cropImage(screenshot: UIImage) -> UIImage {
        print(screenshot.size)
        let crop = CGRectMake(screenshot.size.width/2 - 700/2, screenshot.size.height/2 - 380/2, 700 , 380)
        
        let cgImage = CGImageCreateWithImageInRect(screenshot.CGImage, crop)
        let image: UIImage = UIImage(CGImage: cgImage!)
        return image
    }
}
extension UIImage {
    public func imageRotatedByDegrees(degrees: CGFloat, flip: Bool) -> UIImage {
        let radiansToDegrees: (CGFloat) -> CGFloat = {
            return $0 * (180.0 / CGFloat(M_PI))
        }
        let degreesToRadians: (CGFloat) -> CGFloat = {
            return $0 / 180.0 * CGFloat(M_PI)
        }
        
        // calculate the size of the rotated view's containing box for our drawing space
        let rotatedViewBox = UIView(frame: CGRect(origin: CGPointZero, size: size))
        let t = CGAffineTransformMakeRotation(degreesToRadians(degrees));
        rotatedViewBox.transform = t
        let rotatedSize = rotatedViewBox.frame.size
        
        // Create the bitmap context
        UIGraphicsBeginImageContext(rotatedSize)
        let bitmap = UIGraphicsGetCurrentContext()
        
        // Move the origin to the middle of the image so we will rotate and scale around the center.
        CGContextTranslateCTM(bitmap, rotatedSize.width / 2.0, rotatedSize.height / 2.0);
        
        //   // Rotate the image context
        CGContextRotateCTM(bitmap, degreesToRadians(degrees));
        
        // Now, draw the rotated/scaled image into the context
        var yFlip: CGFloat
        
        if(flip){
            yFlip = CGFloat(-1.0)
        } else {
            yFlip = CGFloat(1.0)
        }
        
        CGContextScaleCTM(bitmap, yFlip, -1.0)
        CGContextDrawImage(bitmap, CGRectMake(-size.width / 2, -size.height / 2, size.width, size.height), CGImage)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    // returns a scaled version of the image
    func imageScaledToSize(size : CGSize, isOpaque : Bool) -> UIImage{
        
        // begin a context of the desired size
        UIGraphicsBeginImageContextWithOptions(size, isOpaque, 0.0)
        
        // draw image in the rect with zero origin and size of the context
        let imageRect = CGRect(origin: CGPointZero, size: size)
        self.drawInRect(imageRect)
        
        // get the scaled image, close the context and return the image
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage
    }
}

