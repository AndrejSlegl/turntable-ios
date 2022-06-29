//
//  AppSettingsViewController.swift
//  turntable-ios
//
//  Created by User on 14/06/2022.
//

import Foundation
import UIKit

class AppSettingsViewController: UIViewController, ConsoleListener {
    
    @IBOutlet weak var settingsTableView: UITableView!
    @IBOutlet weak var consoleTableView: UITableView!
    
    let consoleDataSource = ConsoleTableDataSource()
    let settingsDataSource = AppSettingsTableDataSource()
    
    private var didScrollToEnd = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Console.shared.add(listener: self)
        consoleTableView.dataSource = consoleDataSource
        settingsTableView.dataSource = settingsDataSource
        
        settingsTableView.keyboardDismissMode = .interactive
        consoleTableView.keyboardDismissMode = .onDrag
        
        settingsTableView.contentInsetAdjustmentBehavior = .never
        settingsTableView.contentInset = .init(top: 8, left: 0, bottom: 8, right: 0)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame), name: UIResponder.keyboardWillShowNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        
        consoleTableView.reloadData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !didScrollToEnd,
            consoleTableView.bounds.height > 0,
            consoleTableView.contentSize.height > 0 {
            didScrollToEnd = true
            
            DispatchQueue.main.async {
                let numRows = self.consoleDataSource.console.lines.count
                if numRows > 0 {
                    self.consoleTableView.scrollToRow(at: .init(row: numRows - 1, section: 0), at: .none, animated: false)
                }
            }
        }
    }
    
    @objc private func keyboardWillChangeFrame(_ not: Notification) {
        if let frame = not.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect, let window = view.window {
            let origin = window.convert(frame.origin, to: settingsTableView)
            let height = max(0, settingsTableView.bounds.height - origin.y)
            settingsTableView.contentInset.bottom = height + 8
        }
    }
    
    func onPrint(line: String, level: Console.DebugLevel) {
        consoleTableView.reloadData()
    }
}
