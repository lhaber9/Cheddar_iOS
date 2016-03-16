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
        
        leftIcon.backgroundColor = ColorConstants.inboundIcons[0]
        rightIcon.backgroundColor = ColorConstants.outboundChatBubble
    }
    
    func setShowAliasLabel(showAliasLabel: Bool) {
        if (showAliasLabel) {
            messageTopConstraintAlias.priority = 950;
            messageTopConstraint.priority = 200;
            aliasLabelView.hidden = false;
        }
        else {
            messageTopConstraintAlias.priority = 200;
            messageTopConstraint.priority = 950;
            aliasLabelView.hidden = true;
        }
    }
    
    func setIsOutbound(isOutbound: Bool) {
        if (isOutbound) {
            leftSideMessageConstraint.priority = 200;
            rightSideMessageConstraint.priority = 900;
            leftSideLabelConstraint.priority = 200;
            rightSideLabelConstraint.priority = 900;
            messageBackground.backgroundColor = ColorConstants.outboundChatBubble
            messageLabel.textColor = ColorConstants.outboundMessageText
            rightIcon.hidden = false;
            leftIcon.hidden = true;
        }
        else {
            leftSideMessageConstraint.priority = 900;
            rightSideMessageConstraint.priority = 200;
            leftSideLabelConstraint.priority = 900;
            rightSideLabelConstraint.priority = 200;
            messageBackground.backgroundColor = ColorConstants.inboundChatBubble
            messageLabel.textColor = ColorConstants.inboundMessageText
            rightIcon.hidden = true;
            leftIcon.hidden = false;
        }
    }
    
    func setStatus(status:MessageStatus) {
        if (status == MessageStatus.Success) {
            messageBackground.alpha = 1
        }
        else if (status == MessageStatus.Sent) {
            messageBackground.alpha = 0.65
        }
        else if (status == MessageStatus.Error) {
            messageBackground.alpha = 1
        }
    }

    func setMessageText(text: String, alias: Alias, isOutbound: Bool, showAliasLabel:Bool, showAliasIcon:Bool, status:MessageStatus) {
        messageLabel.text = text
        messageHeightConstraint.constant = ChatCell.labelHeightForText(text)
        if (text.characters.count == 1) {
            messageLabel.textAlignment = NSTextAlignment.Center
        }
        else {
            messageLabel.textAlignment = NSTextAlignment.Left
        }
        
        leftIconLabel.text = alias.initials()
        rightIconLabel.text = alias.initials()
        aliasLabel.text = alias.name
        aliasLabel.textColor = ColorConstants.aliasLabelText
        
        setShowAliasLabel(showAliasLabel)
        setIsOutbound(isOutbound)
        setStatus(status)
        
        if (!showAliasIcon){
            rightIcon.hidden = true;
            leftIcon.hidden = true;
        }
        
        setNeedsLayout()
        layoutIfNeeded()
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