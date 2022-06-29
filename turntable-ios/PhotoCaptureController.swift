//
//  PhotoCaptureController.swift
//  turntable-ios
//
//  Created by User on 14/06/2022.
//

import Foundation
import AVFoundation
import UIKit
import Photos

enum PhotoCaptureError: Error {
    case cannotCreateUIImage
    case cannotCreateFileDataRepresentation
    case photoProcessing(error: Error)
    case photoSaving(error: Error)
}

class PhotoCaptureController: NSObject, AVCapturePhotoCaptureDelegate {
    let captureSession = AVCaptureSession()
    let photoOutput = AVCapturePhotoOutput()
    
    private var videoDevice: AVCaptureDevice!
    
    private var capturePhotoCallback: ((Result<(), Error>) -> Void)?
    
    var videoZoom: CGFloat {
        get { videoDevice?.videoZoomFactor ?? 0 }
        set { videoDevice?.videoZoomFactor = newValue }
    }
    
    var photoCaptureMode: PhotoCaptureMode = .photo {
        didSet {
            if photoCaptureMode != oldValue {
                photoCaptureModeChanged()
            }
        }
    }
    
    var maxAvailableVideoZoom: CGFloat {
        return videoDevice?.maxAvailableVideoZoomFactor ?? 0
    }
    
    override init() {
        super.init()
        
        PHPhotoLibrary.requestAuthorization { status in
            Console.shared.print("PhotoLibrary authorization status: \(status)")
        }
        
        guard let videoDevice = AVCaptureDevice.default(for: .video) else {
            Console.shared.print("no video capture device")
            return
        }
        
        do {
            try videoDevice.lockForConfiguration()
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            guard captureSession.canAddInput(videoDeviceInput) else {
                fatalError("cannot add input \(videoDeviceInput)")
            }
            
            captureSession.beginConfiguration()
            captureSession.addInput(videoDeviceInput)
            
            guard captureSession.canAddOutput(photoOutput) else {
                fatalError("cannot add output \(photoOutput)")
            }
            captureSession.addOutput(photoOutput)
            photoCaptureModeChanged()
            
            captureSession.commitConfiguration()
            self.videoDevice = videoDevice
        } catch {
            Console.shared.print("error initializing capture session:\n\(error)")
            return
        }
        
        Console.shared.print("Initialized PhotoCaptureController")
    }
    
    private func photoCaptureModeChanged() {
        func toAVsessionPreset(mode: PhotoCaptureMode) -> AVCaptureSession.Preset {
            switch mode {
            case .photo:
                return .photo
            case .hd2160:
                return .hd4K3840x2160
            case .hd1080:
                return .hd1920x1080
            case .hd720:
                return .hd1280x720
            case .vga640x480:
                return .vga640x480
            }
        }
        
        captureSession.sessionPreset = toAVsessionPreset(mode: photoCaptureMode)
    }
    
    private func onCapturePhoto(result: Result<(), Error>) {
        let cb = capturePhotoCallback
        capturePhotoCallback = nil
        cb?(result)
    }
    
    func set(orientation: AVCaptureVideoOrientation) {
        for connection in captureSession.connections {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = orientation
            }
        }
    }
    
    func capturePhoto(callback: ((Result<(), Error>) -> Void)? = nil) {
        capturePhotoCallback = callback
        
        let settings = AVCapturePhotoSettings(rawPixelFormatType: 0, rawFileType: nil, processedFormat: nil, processedFileType: .jpg)
        settings.flashMode = .off
        settings.isAutoRedEyeReductionEnabled = false
        
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            onCapturePhoto(result: .failure(PhotoCaptureError.photoProcessing(error: error)))
        } else {
            if let data = photo.fileDataRepresentation() {
                PHPhotoLibrary.shared().performChanges({
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    creationRequest.addResource(with: .photo, data: data, options: nil)
                }, completionHandler: { success, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            self.onCapturePhoto(result: .failure(PhotoCaptureError.photoSaving(error: error)))
                        } else {
                            self.onCapturePhoto(result: .success(()))
                        }
                    }
                })
            } else {
                onCapturePhoto(result: .failure(PhotoCaptureError.cannotCreateFileDataRepresentation))
            }
        }
    }
    
    func startRunning() {
        captureSession.startRunning()
    }
    
    func stopRunning() {
        captureSession.stopRunning()
    }
}

extension PHAuthorizationStatus: CustomStringConvertible {
    public var description: String {
        switch self {
        case .authorized:
            return "authorized"
        case .denied:
            return "denied"
        case .limited:
            return "limited"
        case .notDetermined:
            return "notDetermined"
        case .restricted:
            return "restricted"
        @unknown default:
            return "..."
        }
    }
}
