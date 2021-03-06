//
//  AppSettingsTableDataSource.swift
//  turntable-ios
//
//  Created by User on 15/06/2022.
//

import Foundation
import UIKit

class AppSettingsTableDataSource: NSObject, UITableViewDataSource {
    private let settings = AppSettings.shared
    private var settingItems: [AppSettingsItem] = []
    
    override init() {
        super.init()
        
        weak var `self` = self
        settingItems = [
            AppSettingsItem(
                type: .textField(keyboardType: .numbersAndPunctuation),
                title: "Host & Port",
                value: (settings.turntableHost ?? "") + ":" + String(settings.turntablePort),
                validate: { self?.parseHostAndPort($0) == nil ? "Invalid format" : nil },
                valueChanged: {
                    if let val = self?.parseHostAndPort($0) {
                        self?.settings.turntableHost = val.0
                        self?.settings.turntablePort = val.1
                    }
                }
            ),
            AppSettingsItem(
                type: .textField(keyboardType: .numberPad),
                title: "Steps",
                value: String(settings.turntableSteps),
                validate: { (Int($0) ?? 0) > 0 ? nil : "Invalid format" },
                valueChanged: { self?.settings.turntableSteps = Int($0) ?? 1 }
            ),
            AppSettingsFloatItem(
                type: .textField(keyboardType: .decimalPad),
                title: "camera zoom",
                value: String(settings.cameraZoom),
                validate: { (Float($0) ?? 0) >= 1 ? nil : "Invalid format" },
                valueChanged: { self?.settings.cameraZoom = Float($0) ?? 1 }
            ),
            AppSettingsItem(
                type: .listPicker(listItems: PhotoCaptureMode.allCases.map { $0.asKeyValuePair() }),
                title: "photo resolution",
                value: (settings.photoCaptureMode ?? .photo).rawValue, validate: { _ in nil },
                valueChanged: {
                    PhotoCaptureMode(rawValue: $0).flatMap { self?.settings.photoCaptureMode = $0 }
                }
            )
        ]
    }
    
    private func parseHostAndPort(_ host: String) -> (String, Int)? {
        let split = host.split(separator: ":")
        guard split.count == 2 else { return nil }
        guard let port = Int(split[1]) else { return nil }
        return (String(split[0]), port)
    }
    
    // MARK: UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settingItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = settingItems[indexPath.row]
        
        switch item.type {
        case .textField:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "textField", for: indexPath) as? SettingsTextFieldCell else {
                return UITableViewCell()
            }
            cell.configure(with: item)
            return cell
        case .listPicker:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "listPicker", for: indexPath) as? SettingsListPickerTableCell else {
                return UITableViewCell()
            }
            cell.configure(with: item)
            return cell
        }
    }
}

enum AppSettingsItemType {
    case textField(keyboardType: UIKeyboardType)
    case listPicker(listItems: [(key: String, value: String)])
}

class AppSettingsItem: NSObject {
    let type: AppSettingsItemType
    let title: String
    var value: String
    let validate: (String) -> String?
    let valueChanged: (String) -> Void
    
    init(type: AppSettingsItemType, title: String, value: String, validate: @escaping (String) -> String?, valueChanged: @escaping (String) -> Void) {
        self.type = type
        self.title = title
        self.value = value
        self.validate = validate
        self.valueChanged = valueChanged
        
        super.init()
    }
}

class AppSettingsFloatItem: AppSettingsItem, UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let text = (textField.text ?? "")
        guard let r = Range(range, in: text) else { return true }
        let str = text.replacingCharacters(in: r, with: string)
        
        textField.text = str.replacingOccurrences(of: ",", with: ".")
        textField.sendActions(for: .editingChanged)
        return false
    }
}

extension PhotoCaptureMode {
    var localizedName: String {
        switch self {
        case .photo:
            return "full"
        case .hd2160:
            return "3840x2160"
        case .hd1080:
            return "1920x1080"
        case .hd720:
            return "1280x720"
        case .vga640x480:
            return "640x480"
        }
    }
    
    func asKeyValuePair() -> (key: String, value: String) {
        return (rawValue, localizedName)
    }
}
