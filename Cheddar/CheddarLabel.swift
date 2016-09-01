//
//  CheddarLabel.swift
//  Cheddar
//
//  Created by Lucas Haber on 3/29/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation

@IBDesignable class CheddarLabel: UILabel {
    override func awakeFromNib() {
        textColor = ColorConstants.textPrimary
    }
}