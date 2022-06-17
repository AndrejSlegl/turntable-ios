//
//  VideoPreviewView.swift
//  turntable-ios
//
//  Created by User on 14/06/2022.
//

import Foundation
import AVFoundation
import UIKit

class VideoPreviewView: UIView {
    // Use AVCaptureVideoPreviewLayer as the view's backing layer.
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    
    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
    
    // Connect the layer to a capture session.
    var session: AVCaptureSession? {
        get { previewLayer.session }
        set { previewLayer.session = newValue }
    }
}
