//
//  IntroView.swift
//  Cheddar
//
//  Created by Lucas Haber on 3/28/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation

class IntroView: FrontPageView {
    
    @IBOutlet var bottomTextLabel: CheddarLabel!
    
    @IBOutlet var cheddarTextSmallConstraint: NSLayoutConstraint!
    @IBOutlet var taglineTextSmallConstraint: NSLayoutConstraint!
    @IBOutlet var bottomTextSmallConstraint: NSLayoutConstraint!
    @IBOutlet var bottomTextSmallWidthConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 10
        paragraphStyle.alignment = NSTextAlignment.Center;
        let attributes = [NSParagraphStyleAttributeName: paragraphStyle]
        let attributedText = NSAttributedString(string: bottomTextLabel.text!, attributes: attributes)
        bottomTextLabel.attributedText = attributedText
        
        if (Utilities.IS_IPHONE_4_OR_LESS()) {
            cheddarTextSmallConstraint.priority = 950
            taglineTextSmallConstraint.priority = 950
            bottomTextSmallConstraint.priority = 950
        }
    }
    
    class func instanceFromNib() -> IntroView {
        return UINib(nibName: "IntroView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! IntroView
    }
}