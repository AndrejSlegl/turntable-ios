//
//  ViewController.swift
//  turntable-ios
//
//  Created by User on 11/06/2022.
//

import UIKit

class ViewController: UIViewController, SocketConnectionDelegate {
    @IBOutlet weak var previewView: VideoPreviewView!
    @IBOutlet weak var captureBtn: UIButton!
    @IBOutlet weak var settingsBtn: UIButton!
    
    private var connection: SocketConnection!
    private let captureController = PhotoCaptureController()
    private let settings = AppSettings.shared
    private var startGestureScale: CGFloat = 0
    
    private var isConnected = false {
        didSet {
            if !isConnected {
                isCapturing = false
            }

            if isConnected != oldValue {
                updateConnectionStatus()
            }
        }
    }
    
    private var isCapturing = false {
        didSet { updateCameraImage() }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        settingsBtn.addTarget(self, action: #selector(didPressSettings), for: .touchUpInside)
        
        captureBtn.addTarget(self, action: #selector(didPressCapture), for: .touchUpInside)
        previewView.session = captureController.captureSession
        captureController.set(orientation: .landscapeRight)
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(didPinch))
        previewView.addGestureRecognizer(pinchRecognizer)
        
        captureController.startRunning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        
        captureController.videoZoom = CGFloat(settings.cameraZoom)
        captureController.photoCaptureMode = settings.photoCaptureMode ?? .photo
        
        if connection?.host != (settings.turntableHost ?? "") || connection?.port != UInt32(settings.turntablePort) {
            setupConnection()
            connection.connect()
        } else if !isConnected {
            connection.connect()
        }
    }
    
    private func setupConnection() {
        isConnected = false
        connection = SocketConnection(host: settings.turntableHost ?? "", port: UInt32(settings.turntablePort))
        connection.delegate = self
    }
    
    @objc private func didPressCapture() {
        isCapturing = !isCapturing
        
        if isCapturing {
            if connection.error != nil {
                isConnected = false
                connection.connect()
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.capturePhoto()
            }
        }
    }
    
    func lineReceived(socketConnection: SocketConnection, line: String) {
        Console.shared.print("socket received: \(line)")
        
        switch line {
        case "PONG":
            if !isConnected && isCapturing {
                moveForward()
            }
            isConnected = true
            
        case "DONE":
            capturePhoto()
            
        default:
            break
        }
    }
    
    func outputStreamError(socketConnection: SocketConnection, error: Error) {
        isConnected = false
        Console.shared.print("socket error:\n\(error)", level: .error)
    }
    
    func streamEndEncountered(socketConnection: SocketConnection) {
        isConnected = false
        Console.shared.print("stream end encountered", level: .error)
    }
    
    func openCompleted(socketConnection: SocketConnection) {
        if !isConnected {
            socketConnection.write(line: "PING")
        }
    }
    
    @objc private func didPressSettings() {
        performSegue(withIdentifier: "showSettings", sender: nil)
    }
    
    private func updateCameraImage() {
        captureBtn.setImage(UIImage(systemName: isCapturing ? "xmark" : "camera"), for: .normal)
    }
    
    private func updateConnectionStatus() {
        Console.shared.print("isConnected = \(isConnected)", level: .info)
        captureBtn.tintColor = isConnected ? UIColor.systemGreen : UIColor.label
    }
    
    private func capturePhoto() {
        guard isCapturing else { return }

        Console.shared.print("capturing photo")
        captureController.capturePhoto() {
            switch $0 {
            case .success:
                if self.isCapturing {
                    self.moveForward()
                }
            case .failure(let error):
                self.isCapturing = false
                Console.shared.print("capturePhoto error:\n\(error)", level: .error)
            }
        }
    }
    
    private func moveForward() {
        if isConnected {
            let steps = max(1, settings.turntableSteps)
            connection.write(line: "left;" + String(steps))
        }
    }
    
    @objc private func didPinch(pinchRecognizer: UIPinchGestureRecognizer) {
        switch pinchRecognizer.state {
        case .began:
            startGestureScale = captureController.videoZoom
        case .changed:
            let maxZoom = min(4, captureController.maxAvailableVideoZoom)
            let scale = min(max(1, pinchRecognizer.scale * startGestureScale), maxZoom)
            captureController.videoZoom = scale
        case .ended:
            startGestureScale = 0
            settings.cameraZoom = Float(captureController.videoZoom)
        default:
            break
        }
    }
}
