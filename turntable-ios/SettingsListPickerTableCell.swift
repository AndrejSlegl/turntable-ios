//
//  SettingsListPickerTableCell.swift
//  turntable-ios
//
//  Created by User on 29/06/2022.
//

import Foundation
import UIKit

class SettingsListPickerTableCell: UITableViewCell, UIPickerViewDataSource, UIPickerViewDelegate {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var textField: UITextField!
    
    private var item: AppSettingsItem?
    private var listItems: [(key: String, value: String)] = []
    
    private let pickerView = UIPickerView()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        pickerView.dataSource = self
        pickerView.delegate = self
        
        textField.addTarget(self, action: #selector(editingDidBegin), for: .editingDidBegin)
        textField.inputView = pickerView
        
        let keyboardToolbar = UIToolbar()
        let flexBarButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneBarButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(didPressDone))
        keyboardToolbar.items = [flexBarButton, doneBarButton]
        keyboardToolbar.sizeToFit()
        textField.inputAccessoryView = keyboardToolbar
    }
    
    func configure(with item: AppSettingsItem) {
        guard case .listPicker(let listItems) = item.type else {
            fatalError()
        }
        
        self.listItems = listItems
        self.item = item
        titleLabel.text = item.title
        updateTextField()
        
        pickerView.reloadAllComponents()
    }
    
    private func updateTextField() {
        if let item = listItems.first(where: { $0.key == item?.value }) {
            textField.text = item.value
        }
    }
    
    @objc func didPressDone() {
        guard let item = item else { return }
        let value = listItems[pickerView.selectedRow(inComponent: 0)].key
        item.value = value
        item.valueChanged(value)
        updateTextField()
        textField.resignFirstResponder()
    }
    
    @objc func editingDidBegin() {
        if let row = listItems.firstIndex(where: { $0.key == item?.value }) {
            pickerView.selectRow(row, inComponent: 0, animated: false)
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return listItems.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return listItems[row].value
    }
}
