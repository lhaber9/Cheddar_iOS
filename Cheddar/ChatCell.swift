//
//  ChatCell.swift
//  Cheddar
//
//  Created by Lucas Haber on 2/7/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation


class ChatCell: UITableViewCell {
    
    @IBOutlet var messageLabel: CheddarTextView!
    @IBOutlet var messageBackground: UIView!
    
    @IBOutlet var leftSideMessageConstraint: NSLayoutConstraint!
    @IBOutlet var rightSideMessageConstraint: NSLayoutConstraint!
    @IBOutlet var leftSideLabelConstraint: NSLayoutConstraint!
    @IBOutlet var rightSideLabelConstraint: NSLayoutConstraint!
    
    @IBOutlet var messageHeightConstraint: NSLayoutConstraint!
    @IBOutlet var messageTopConstraintAlias: NSLayoutConstraint!
    @IBOutlet var messageTopConstraint: NSLayoutConstraint!
    
    @IBOutlet var errorLeftConstraint: NSLayoutConstraint!
    @IBOutlet var errorRightConstraint: NSLayoutConstraint!
    @IBOutlet var errorLabel: UILabel!
    
    @IBOutlet var aliasLabelView: UIView!
    @IBOutlet var aliasLabel: UILabel!

    @IBOutlet var rightIcon: UIView!
    @IBOutlet var rightIconLabel: UILabel!
    @IBOutlet var leftIcon: UIView!
    @IBOutlet var leftIconLabel: UILabel!
    
    static var verticalTextBuffer:CGFloat = 13;
    static var aliasLabelHeight:CGFloat = 18;
    static var singleRowHeight:CGFloat = 32;
    
    override func willMoveToSuperview(newSuperview: UIView?) {
        messageBackground.layer.cornerRadius = ChatCell.singleRowHeight/2;
        leftIcon.layer.cornerRadius = ChatCell.singleRowHeight/2;
        rightIcon.layer.cornerRadius = ChatCell.singleRowHeight/2;
        
        leftIcon.backgroundColor = ColorConstants.inboundIcons[0]
        rightIcon.backgroundColor = ColorConstants.outboundChatBubble
        
        messageLabel.textContainer.lineFragmentPadding = 0;
        messageLabel.textContainerInset = UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 0)
    }
    
    class func labelHeightForText(text: String) -> CGFloat {
        
        var height = round(text.boundingRectWithSize(CGSizeMake(180, CGFloat(FLT_MAX)),
            options: NSStringDrawingOptions.UsesLineFragmentOrigin,
            attributes: [NSFontAttributeName: UIFont(name: "Effra", size: 16)!],
            context: nil).height) + verticalTextBuffer
        
        if (height > ChatCell.singleRowHeight) {
            height += 4
        }
        return height
    }
    
    class func rowHeightForText(text: String, withAliasLabel: Bool) -> CGFloat {
        var height = labelHeightForText(text)
        if (withAliasLabel) {
            height += aliasLabelHeight
        }
        return height
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
            errorLeftConstraint.priority = 200;
            errorRightConstraint.priority = 900;
            leftSideMessageConstraint.priority = 200;
            rightSideMessageConstraint.priority = 900;
            leftSideLabelConstraint.priority = 200;
            rightSideLabelConstraint.priority = 900;
            messageLabel.textColor = ColorConstants.outboundMessageText
            rightIcon.hidden = false;
            leftIcon.hidden = true;
        }
        else {
            errorLeftConstraint.priority = 900;
            errorRightConstraint.priority = 200;
            leftSideMessageConstraint.priority = 900;
            rightSideMessageConstraint.priority = 200;
            leftSideLabelConstraint.priority = 900;
            rightSideLabelConstraint.priority = 200;
            messageLabel.textColor = ColorConstants.textPrimary
            messageBackground.backgroundColor = ColorConstants.inboundChatBubble
            rightIcon.hidden = true;
            leftIcon.hidden = false;
        }
    }
    
    func setStatus(status:ChatEventStatus) {
        if (status == ChatEventStatus.Success) {
            messageBackground.backgroundColor = ColorConstants.outboundChatBubble
        }
        else if (status == ChatEventStatus.Sent) {
            messageBackground.backgroundColor = ColorConstants.outboundChatBubbleSending
            messageBackground.alpha = 0.62
        }
        else if (status == ChatEventStatus.Error) {
            messageBackground.backgroundColor = ColorConstants.outboundChatBubbleFail
            errorLabel.hidden = false
        }
    }
    
    // options are {text:String, alias:Alias, showAliasLabel:Bool, isOutbound:Bool, status:String, showAliasIcon:Bool}
    func setMessageOptions(options: [String:AnyObject]) {
        
        messageLabel.text = options["text"] as! String
        let height = ChatCell.labelHeightForText( messageLabel.text )
        messageHeightConstraint.constant = height
        
        if (messageLabel.text.characters.count == 1) {
            messageLabel.textAlignment = NSTextAlignment.Center
        }
        else {
            messageLabel.textAlignment = NSTextAlignment.Left
        }
        
        let alias = options["alias"] as! Alias
        leftIconLabel.text = alias.initials()
        rightIconLabel.text = alias.initials()
        aliasLabel.text = alias.name.lowercaseString
        aliasLabel.textColor = ColorConstants.aliasLabelText
        
        errorLabel.hidden = true
        messageBackground.alpha = 1
        
        setShowAliasLabel(options["showAliasLabel"] as! Bool)
        setIsOutbound(options["isOutbound"] as! Bool)
        if (options["isOutbound"] as! Bool) {
            setStatus(ChatEventStatus(rawValue:options["status"] as! String)!)
        }
        
        if (!(options["showAliasIcon"] as! Bool)){
            rightIcon.hidden = true;
            leftIcon.hidden = true;
        }
        
        setNeedsLayout()
        layoutIfNeeded()
    }
}