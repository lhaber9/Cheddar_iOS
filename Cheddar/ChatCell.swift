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
    
    @IBOutlet var leftSideMessageConstraint: NSLayoutConstraint!
    @IBOutlet var rightSideMessageConstraint: NSLayoutConstraint!
    @IBOutlet var leftSideLabelConstraint: NSLayoutConstraint!
    @IBOutlet var rightSideLabelConstraint: NSLayoutConstraint!
    
    @IBOutlet var messageHeightConstraint: NSLayoutConstraint!
    @IBOutlet var messageTopConstraintAlias: NSLayoutConstraint!
    @IBOutlet var messageTopConstraint: NSLayoutConstraint!
    
    @IBOutlet var aliasLabelView: UIView!
    @IBOutlet var aliasLabel: UILabel!

    @IBOutlet var rightIcon: UIView!
    @IBOutlet var rightIconLabel: UILabel!
    @IBOutlet var leftIcon: UIView!
    @IBOutlet var leftIconLabel: UILabel!
    
    static var verticalTextBuffer:CGFloat = 13;
    static var aliasLabelHeight:CGFloat = 18;
    
    override func willMoveToSuperview(newSuperview: UIView?) {
        messageBackground.layer.cornerRadius = 15;
        leftIcon.layer.cornerRadius = 15;
        rightIcon.layer.cornerRadius = 15;
        
        rightIcon.backgroundColor = UIColor.redColor()
    }
    
    var alias: Alias! {
        didSet {
            leftIconLabel.text = alias.initials()
            rightIconLabel.text = alias.initials()
            aliasLabel.text = alias.name
        }
    }
    
    var isOutbound: Bool! {
        didSet {
            if (isOutbound == true) {
                messageBackground.backgroundColor = UIColor.lightGrayColor()
//                messageLabel.textAlignment = NSTextAlignment.Right
                leftSideMessageConstraint.priority = 200;
                rightSideMessageConstraint.priority = 900;
                leftSideLabelConstraint.priority = 200;
                rightSideLabelConstraint.priority = 900;
                messageBackground.backgroundColor = UIColor.redColor()
                messageLabel.textColor = UIColor.whiteColor()
                rightIcon.hidden = false;
                leftIcon.hidden = true;
            }
        }
    }
    
    var showAliasLabel: Bool! {
        didSet {
            if (showAliasLabel == true) {
                messageTopConstraintAlias.priority = 900;
                messageTopConstraint.priority = 200;
                aliasLabelView.hidden = false;
            }
        }
    }
    
    func setMessageText(text: String) {
        messageLabel.text = text
        messageHeightConstraint.constant = ChatCell.labelHeightForText(text)
    }
    
    class func labelHeightForText(text: String) -> CGFloat {
        return round(text.boundingRectWithSize(CGSizeMake(192, 9999),
                                                        options: NSStringDrawingOptions.UsesLineFragmentOrigin,
                                                        attributes: [NSFontAttributeName: UIFont.systemFontOfSize(14)],
                                                        context: nil).height) + verticalTextBuffer
    }
    
    class func rowHeightForText(text: String, withAliasLabel: Bool) -> CGFloat {
        var height = labelHeightForText(text)
        if (withAliasLabel) {
            height += aliasLabelHeight
        }
        return height
    }
    
}