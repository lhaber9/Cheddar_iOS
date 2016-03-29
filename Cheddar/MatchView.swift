//
//  MatchView.swift
//  Cheddar
//
//  Created by Lucas Haber on 3/28/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation

class MatchView: FrontPageView {
    
    @IBOutlet var bottomTextLabel: UILabel!
    
    override func awakeFromNib() {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 10
        paragraphStyle.alignment = NSTextAlignment.Center;
        let attributes = [NSParagraphStyleAttributeName: paragraphStyle]
        let attributedText = NSAttributedString(string: bottomTextLabel.text!, attributes: attributes)
        bottomTextLabel.attributedText = attributedText
    }
    
    class func instanceFromNib() -> UIView {
        return UINib(nibName: "MatchView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! MatchView
    }
}