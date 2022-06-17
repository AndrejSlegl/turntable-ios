//
//  SocketConnection.swift
//  turntable-ios
//
//  Created by User on 14/06/2022.
//

import Foundation

protocol SocketConnectionDelegate: AnyObject {
    func lineReceived(socketConnection: SocketConnection, line: String)
    func outputStreamError(socketConnection: SocketConnection, error: Error)
    func streamEndEncountered(socketConnection: SocketConnection)
    func openCompleted(socketConnection: SocketConnection)
}

class SocketConnection: NSObject, StreamDelegate {
    let maxReadLength = 4096
    let host: String
    let port: UInt32

    private var inputStream: InputStream!
    private var outputStream: OutputStream!
    private var readBuffer: UnsafeMutablePointer<UInt8>!
    private var readBufferStr = String()
    private var outputBuffer = String()
    
    weak var delegate: SocketConnectionDelegate?
    
    var error: Error? { outputStream.streamError }
    
    init(host: String, port: UInt32) {
        self.host = host
        self.port = port
    }
    
    deinit {
        disconnect()
    }
    
    func connect() {
        disconnect()
        
        var readStream: Unmanaged<CFReadStream>?
        var writeStream: Unmanaged<CFWriteStream>?
        
        CFStreamCreatePairWithSocketToHost(
            kCFAllocatorDefault,
            host as CFString, port,
            &readStream, &writeStream
        )
        
        inputStream = readStream!.takeRetainedValue()
        outputStream = writeStream!.takeRetainedValue()
        
        inputStream.delegate = self
        outputStream.delegate = self
        
        inputStream.schedule(in: .current, forMode: .common)
        outputStream.schedule(in: .current, forMode: .common)
        
        inputStream.open()
        outputStream.open()
        
        readBuffer = .allocate(capacity: maxReadLength)
        readBufferStr.removeAll()
        outputBuffer.removeAll()
        
        Console.shared.print("starting connection to: \(host):\(port)")
    }
    
    func disconnect() {
        inputStream?.delegate = nil
        outputStream?.delegate = nil
        inputStream?.close()
        outputStream?.close()
        inputStream = nil
        outputStream = nil
    }

    private func readAvailableBytes(stream: InputStream) -> String? {
        guard stream.hasBytesAvailable else {
            return nil
        }
        
        let numberOfBytesRead = stream.read(readBuffer, maxLength: maxReadLength)
        
        if numberOfBytesRead <= 0 {
            return nil
        } else if let str = String(
            bytesNoCopy: readBuffer, length: numberOfBytesRead,
            encoding: .utf8, freeWhenDone: false
        ) {
            let spl = str.split(separator: "\n", omittingEmptySubsequences: false)
            if spl.count < 2 {
                readBufferStr += spl[0]
                return nil
            }
            
            let line = readBufferStr + spl[0]
            readBufferStr.removeAll()
            readBufferStr += spl[1]
            
            return line
        } else {
            return nil
        }
    }

    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case .hasBytesAvailable:
            if let str = readAvailableBytes(stream: aStream as! InputStream) {
                delegate?.lineReceived(socketConnection: self, line: str)
            }
            
        case .endEncountered:
            delegate?.streamEndEncountered(socketConnection: self)
            
        case .errorOccurred:
            if let err = aStream.streamError, aStream == outputStream {
                delegate?.outputStreamError(socketConnection: self, error: err)
            }
            
        case .hasSpaceAvailable:
            //Console.shared.print("hasSpaceAvailable: \(aStream)")
            flushBuffer()
            
        case .openCompleted:
            //Console.shared.print("openCompleted: \(aStream)")
            if aStream == outputStream {
                delegate?.openCompleted(socketConnection: self)
            }
            
        default:
            break
        }
    }
    
    func write(line: String) {
        Console.shared.print("socket sending: \(line)")
        outputBuffer += line + "\n"
        flushBuffer()
    }
    
    private func flushBuffer() {
        if outputStream.hasSpaceAvailable && !outputBuffer.isEmpty {
            outputStream.write(string: outputBuffer)
            outputBuffer.removeAll()
        }
    }
}

extension OutputStream {
    func write(string: String) {
        if let data = string.data(using: .utf8) {
            _ = data.withUnsafeBytes { p in
                self.write(p, maxLength: data.count)
            }
        }
    }
}
