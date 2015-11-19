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
import Alamofire
import AFNetworking
import MBProgressHUD

class ViewController: UIViewController, UINavigationControllerDelegate {

    @IBOutlet weak var btScan: UIBarButtonItem!
    @IBOutlet weak var imageAvatar: UIImageView!
    
    @IBOutlet weak var recognizedView: UITextView!
    @IBOutlet weak var recognizedView2: UITextView!
    
    @IBOutlet weak var tvServer: UITextView!
    @IBOutlet weak var processImageView: UIImageView!
    @IBOutlet weak var tv: UITextView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
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
        
        self.tv.text = ""
        self.tvServer.text = ""
        
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
        
        
        //1. Gray image
        let grayImage = GPUImageGrayscaleFilter()
        let outputGrayImage = grayImage.imageByFilteringImage(sourceImage) as UIImage
        
        self.processImageView.image = outputGrayImage
        
        //2. Threshold filter
        let _stillImageFilter = GPUImageAdaptiveThresholdFilter()
        _stillImageFilter.blurRadiusInPixels = 13
        let filteredImage = _stillImageFilter.imageByFilteringImage(outputGrayImage) as UIImage
        
        //3. Blur
//        let stillImageSource = GPUImagePicture(image: filteredImage)
//        let blurFilter = GPUImageExposureFilter()
//        blurFilter.exposure = 5
//        
//        stillImageSource.addTarget(blurFilter)
//        blurFilter.useNextFrameForImageCapture()
//        stillImageSource.processImage()
//       let outputImage =  blurFilter.imageFromCurrentFramebufferWithOrientation(UIImageOrientation.Up)
        
//        let unSharpen = GPUImageUnsharpMaskFilter()
//        stillImageSource.addTarget(unSharpen)
//        unSharpen.useNextFrameForImageCapture()
//        stillImageSource.processImage()
//        
//        let outputUnSharpen = unSharpen.imageByFilteringImage(filteredImage) as UIImage
        
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
        tesseract.image = image.g8_grayScale()
        
        
        tesseract.recognize()
        print(tesseract.recognizedText)
        MBProgressHUD.hideHUDForView(self.recognizedView, animated: true)
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
        self.processImageView.image = nil
        
        self.btScan.enabled = false
        
        
        let hud : MBProgressHUD = MBProgressHUD.showHUDAddedTo(recognizedView, animated: true)
        let hud1 : MBProgressHUD = MBProgressHUD.showHUDAddedTo(recognizedView2, animated: true)
        hud.labelText = "Processing ..."
        hud1.labelText = "Processing ..."
        
        dismissViewControllerAnimated(true, completion: {
            
            let processImage = self.processingImage(scaledImage)
            
            self.processImageView.image = processImage
            
            self.performImageRecognition(processImage)
            
        })
        
        self.tvServer.text = ""
        postRequest(scaledImage)
    }
    
    func postRequest(image: UIImage){
        let manager = AFHTTPRequestOperationManager()
        
        let url = "https://ocr.a9t9.com/api/Parse/Image"
        
        let params = [
            "apikey":"helloworld",
            "language" : "eng",

        ]
        let imageData = UIImageJPEGRepresentation(image, 1)
        manager.POST(url, parameters: params, constructingBodyWithBlock: { (data) in
            data.appendPartWithFileData(imageData!, name: "file" as String, fileName: "file.jpg" as String, mimeType:"image/jpeg"  as String)
            }, success: { (operation, responseObject) in
                print(responseObject)
                
                if(responseObject["ParsedResults"] != nil){
                    let arrs = responseObject["ParsedResults"] as! NSArray
                    let value = arrs[0]
                    print(value["ParsedText"])
                    
                    self.tvServer.text = value["ParsedText"] as! String
                    MBProgressHUD.hideHUDForView(self.recognizedView2, animated: true)
                    
                }
            }, failure: { (operation, error) in
                MBProgressHUD.hideHUDForView(self.recognizedView2, animated: true)
                print(error)
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

