//
//  ConsoleTableDataSource.swift
//  turntable-ios
//
//  Created by User on 15/06/2022.
//

import Foundation
import UIKit

class ConsoleTableDataSource: NSObject, UITableViewDataSource {
    let console = Console.shared
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return console.lines.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "text", for: indexPath) as? ConsoleTextTableCell else {
            return UITableViewCell()
        }
        
        let line = console.lines[indexPath.row]
        cell.txtLabel.text = line.0
        cell.txtLabel.textColor = line.1 == .error ? UIColor.systemRed : UIColor.label
        
        return cell
    }
}
