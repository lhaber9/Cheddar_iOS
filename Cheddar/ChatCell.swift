//
//  ChatCell.swift
//  Cheddar
//
//  Created by Lucas Haber on 2/7/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation


class ChatCell: UITableViewCell {
    
    @IBOutlet var messageLabel: UILabel!
    @IBOutlet var messageBackground: UIView!
    @IBOutlet var messageHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet var leftSideConstraint: NSLayoutConstraint!
    @IBOutlet var rightSideConstraint: NSLayoutConstraint!
    
    var isOutbound: Bool! {
        didSet {
            if (isOutbound!) {
                messageBackground.backgroundColor = UIColor.lightGrayColor()
                messageLabel.textAlignment = NSTextAlignment.Right
                leftSideConstraint.priority = 200;
                rightSideConstraint.priority = 900;
            }
        }
    }
    
    func setMessageText(text: String) {
        messageLabel.text = text
//        messageHeightConstraint.constant = ChatCell.labelHeightForText(text)
    }
    
    class func labelHeightForText(text: String) -> CGFloat {
        return round(text.boundingRectWithSize(CGSizeMake(192, 9999),
                                                        options: NSStringDrawingOptions.UsesLineFragmentOrigin,
                                                        attributes: [NSFontAttributeName: UIFont.systemFontOfSize(14)],
                                                        context: nil).height)
    }
    
    class func rowHeightForText(text: String) -> CGFloat {
        return 25 + labelHeightForText(text)
    }
    
}