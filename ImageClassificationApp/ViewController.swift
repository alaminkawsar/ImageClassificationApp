//
//  ViewController.swift
//  ImageClassificationApp
//
//  Created by Khayrul on 3/19/22.
//

import UIKit

class ViewController: UIViewController {
    
    var cnt: Int = 1
    
    private var modelParser: ModelParser? =
      ModelParser(modelFileInfo: MobileNet.modelInfo, labelsFileInfo: MobileNet.labelsInfo)

    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var confidence: UITextField!
    @IBAction func pressButton(_ sender: Any) {
        
        textField.text = "Hello Tom"
        doInference()
    }
    
    @IBAction func next(_ sender: Any) {
        if cnt >= 8 {
            cnt = 1
        }
        else {
            cnt = cnt + 1
            image.image = UIImage(named: String(cnt))
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    private func doInference() {
        if let imageAnalysis = image?.image {
            sceneLabel(forImage: imageAnalysis)
        }
    }
    
    private func sceneLabel(forImage image:UIImage) {
        if let pixelBuffer = buffer(from: image) {
            guard let getObject = self.modelParser?.runModel(onFrame: pixelBuffer) else {
                return
            }
            let result = getObject.inferences
            
           // print(result[0].confidence, result[1].confidence)
            
            if result[0].confidence > result[1].confidence {
                textField.text = "This is: " + result[0].label
                confidence.text = "Confidence Score: " + String(result[0].confidence)
            } else {
                confidence.text = "Confidence Score :" + String(result[1].confidence)
                textField.text = "This is: " + result[1].label
            }
            
        }
    }


}

func buffer(from image: UIImage) -> CVPixelBuffer? {
  let attrs = [
    kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
    kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
  ] as CFDictionary

  var pixelBuffer: CVPixelBuffer?
  let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                   Int(image.size.width),
                                   Int(image.size.height),
                                   kCVPixelFormatType_32BGRA,
                                   attrs,
                                   &pixelBuffer)

  guard let buffer = pixelBuffer, status == kCVReturnSuccess else {
    return nil
  }

  CVPixelBufferLockBaseAddress(buffer, [])
  defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
  let pixelData = CVPixelBufferGetBaseAddress(buffer)

  let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
  guard let context = CGContext(data: pixelData,
                                width: Int(image.size.width),
                                height: Int(image.size.height),
                                bitsPerComponent: 8,
                                bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                                space: rgbColorSpace,
                                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
    return nil
  }

  context.translateBy(x: 0, y: image.size.height)
  context.scaleBy(x: 1.0, y: -1.0)

  UIGraphicsPushContext(context)
  image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
  UIGraphicsPopContext()

  return pixelBuffer
}
