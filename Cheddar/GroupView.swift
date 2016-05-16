//
//  GroupView.swift
//  Cheddar
//
//  Created by Lucas Haber on 3/28/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation

class GroupView: FrontPageView {
    
    @IBOutlet var bottomTextLabel: CheddarLabel!
    
    @IBOutlet var imageOffsetSmallConstraint: NSLayoutConstraint!
    @IBOutlet var imageBottomSmallConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 10
        paragraphStyle.alignment = NSTextAlignment.Center;
        let attributes = [NSParagraphStyleAttributeName: paragraphStyle]
        let attributedText = NSAttributedString(string: bottomTextLabel.text!, attributes: attributes)
        bottomTextLabel.attributedText = attributedText
        
        if (Utilities.IS_IPHONE_4_OR_LESS()) {
            imageOffsetSmallConstraint.priority = 950
            imageBottomSmallConstraint.priority = 950
        }
    }
    
    class func instanceFromNib() -> GroupView {
        return UINib(nibName: "GroupView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! GroupView
    }
}