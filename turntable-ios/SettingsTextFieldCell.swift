//
//  SettingsTextFieldCell.swift
//  turntable-ios
//
//  Created by User on 15/06/2022.
//

import Foundation
import UIKit

class SettingsTextFieldCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var textField: UITextField!
    
    private var item: AppSettingsItem?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        textField.addTarget(self, action: #selector(textValueChanged), for: .editingChanged)
    }
    
    @objc private func textValueChanged() {
        if validate(), let item = item {
            item.value = textField.text ?? ""
            item.valueChanged(item.value)
        }
    }
    
    @discardableResult
    private func validate() -> Bool {
        let isValid = item?.validate(textField.text ?? "") == nil
        textField.textColor = isValid ? UIColor.label : UIColor.systemRed
        return isValid
    }
    
    func configure(with item: AppSettingsItem) {
        self.item = item
        titleLabel.text = item.title
        textField.text = item.value
        if case .textField(let keyboardType) = item.type {
            textField.keyboardType = keyboardType
        }
        
        textField.delegate = item as? UITextFieldDelegate
        
        validate()
    }
}
