//
//  Console.swift
//  turntable-ios
//
//  Created by User on 14/06/2022.
//

import Foundation

protocol ConsoleListener: AnyObject {
    func onPrint(line: String, level: Console.DebugLevel)
}

class Console {
    private struct ConsoleListenerWrapper {
        weak var listener: ConsoleListener?
    }
    
    enum DebugLevel {
        case info, warning, error
    }
    
    static let shared = Console()
    
    let timeFormatter = DateFormatter()
    
    private(set) var lines = [(String, DebugLevel)]()
    
    private var listeners = [ConsoleListenerWrapper]()
    
    init() {
        timeFormatter.dateFormat = "[HH:mm:ss]"
    }
    
    func print(_ line: String, level: DebugLevel = .info) {
        let text = timeFormatter.string(from: Date()) + " " + line
        Swift.print(text)
        
        DispatchQueue.main.async {
            self.lines.append((text, level))
            self.listeners.forEach { $0.listener?.onPrint(line: text, level: level) }
        }
    }
    
    func add(listener: ConsoleListener) {
        assert(Thread.isMainThread)
        listeners.append(ConsoleListenerWrapper(listener: listener))
    }
}
