//
//  ViewController.swift
//  ImageConversion
//
//  Created by Tintash on 22/08/2019.
//  Copyright © 2019 Tintash. All rights reserved.
//

import UIKit

struct PixelData {
    var a: UInt8
    var r: UInt8
    var g: UInt8
    var b: UInt8
}

class ViewController: UIViewController {

    @IBOutlet weak var oldImage: UIImageView!
    @IBOutlet weak var convertedImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        oldImage.image = UIImage(named: "pehlinazar")
    }

    @IBAction func convertImage(_ sender: Any) {
        
        //Converting to pixel RGBA data
        guard let pixelArray = oldImage.image?.getPixelDataArray() else { return }
        
        //Converting the pixel RGBA data back to uiimage
        let imageWidth = Int((oldImage.image?.size.width)!)
        let imageHeight = Int((oldImage.image?.size.height)!)
        let image = imageFromARGB32Bitmap(pixels: pixelArray, width: imageWidth, height: imageHeight)
        
        convertedImage.image = image?.rotate(radians: .pi/2)
        
        print("Coverted But Mirrored")
    }
    
    func imageFromARGB32Bitmap(pixels: [PixelData], width: Int, height: Int) -> UIImage? {
        guard width > 0 && height > 0 else { return nil }
        guard pixels.count == width * height else { return nil }
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
        let bitsPerComponent = 8
        let bitsPerPixel = 32
        
        var data = pixels // Copy to mutable []
        guard let providerRef = CGDataProvider(data: NSData(bytes: &data,
                                                            length: data.count * MemoryLayout<PixelData>.size)
            )
            else { return nil }
        
        guard let cgim = CGImage(
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bitsPerPixel: bitsPerPixel,
            bytesPerRow: width * MemoryLayout<PixelData>.size,
            space: rgbColorSpace,
            bitmapInfo: bitmapInfo,
            provider: providerRef,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
            )
            else { return nil }
        
        return UIImage(cgImage: cgim)
    }
    
}

extension UIImage {
    
    func getPixelData(data: UnsafePointer<UInt8>, pos: CGPoint) -> PixelData {
        
        let pixelInfo : Int = ((Int(self.size.width) * Int(pos.y)) + Int(pos.x)) * 4
        
        let r = data[pixelInfo]
        let g = data[pixelInfo+1]
        let b = data[pixelInfo+2]
        let a = data[pixelInfo+3]
        
        return PixelData(a: a, r: r, g: g, b: b)
    }

    func getPixelDataArray() -> [PixelData]{
        let pixelsWide = Int(self.size.width)
        let pixelsHigh = Int(self.size.height)
        
        guard let pixelData = self.cgImage?.dataProvider?.data else { return [] }
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        
        var imageColors: [PixelData] = []
        for x in 0..<pixelsWide {
            for y in 0..<pixelsHigh {
                let cgPoint = CGPoint(x: x, y: y)
                let color = self.getPixelData(data: data, pos: cgPoint)
                imageColors.append(color)
            }
        }
        return imageColors
    }
}

extension UIImage {
    
    func rotate(radians: Float) -> UIImage? {
        var newSize = CGRect(origin: CGPoint.zero, size: self.size).applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size
        // Trim off the extremely small float value to prevent core graphics from rounding it up
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        let context = UIGraphicsGetCurrentContext()!
        
        // Move origin to middle
        context.translateBy(x: newSize.width/2, y: newSize.height/2)
        // Rotate around middle
        context.rotate(by: CGFloat(radians))
        // Draw the image at its center
        self.draw(in: CGRect(x: -self.size.width/2, y: -self.size.height/2, width: self.size.width, height: self.size.height))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}
