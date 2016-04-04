//
//  CheddarTextView.swift
//  Cheddar
//
//  Created by Lucas Haber on 3/30/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation

class CheddarTextView: UITextView {
    override func awakeFromNib() {
        textColor = ColorConstants.textPrimary
    }
    
    override func canBecomeFirstResponder() -> Bool {
        return false
    }
    
    override func shouldChangeTextInRange(range: UITextRange, replacementText text: String) -> Bool {
        resignFirstResponder()
        return false
    }
}