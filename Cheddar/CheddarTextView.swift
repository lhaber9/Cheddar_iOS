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
    
    override var contentSize: CGSize {
        didSet {
//            textContainerInset = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        }
    }
}