//
//  ChatCell.swift
//  Cheddar
//
//  Created by Lucas Haber on 2/7/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation


class ChatCell: UITableViewCell {
    
    @IBOutlet var messageLabel: UITextView!
    @IBOutlet var messageBackground: UIView!
    
    @IBOutlet var leftSideMessageConstraint: NSLayoutConstraint!
    @IBOutlet var rightSideMessageConstraint: NSLayoutConstraint!
    @IBOutlet var leftSideLabelConstraint: NSLayoutConstraint!
    @IBOutlet var rightSideLabelConstraint: NSLayoutConstraint!
    
    @IBOutlet var messageHeightConstraint: NSLayoutConstraint!
    @IBOutlet var messageTopConstraintTimestamp: NSLayoutConstraint!
    @IBOutlet var messageTopConstraintAlias: NSLayoutConstraint!
    @IBOutlet var messageTopConstraint: NSLayoutConstraint!
    
    @IBOutlet var errorLeftConstraint: NSLayoutConstraint!
    @IBOutlet var errorRightConstraint: NSLayoutConstraint!
    @IBOutlet var errorLabel: UILabel!
    
    @IBOutlet var aliasLabelView: UIView!
    @IBOutlet var aliasLabel: UILabel!
    
    @IBOutlet var timestampLabelView: UIView!
    @IBOutlet var timestampLabel: UILabel!

    @IBOutlet var rightIcon: UIView!
    @IBOutlet var rightIconLabel: UILabel!
    @IBOutlet var leftIcon: UIView!
    @IBOutlet var leftIconLabel: UILabel!
    
    var rightAliasIcon: AliasCircleView!
    var leftAliasIcon: AliasCircleView!
    
    static var verticalTextBuffer:CGFloat = 13
    static var aliasLabelHeight:CGFloat = 15
    static var timestampLabelHeight:CGFloat = 15
    static var singleRowHeight:CGFloat = 32
    
    override func willMoveToSuperview(newSuperview: UIView?) {
        messageBackground.layer.cornerRadius = ChatCell.singleRowHeight/2;
        messageLabel.textColor = ColorConstants.textPrimary
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
    
    class func rowHeightForText(text: String, withAliasLabel: Bool, withTimestampLabel: Bool) -> CGFloat {
        var height = labelHeightForText(text)
        if (withAliasLabel) {
            height += aliasLabelHeight
        }
        else if (withTimestampLabel) {
            height += timestampLabelHeight
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
    
    func setShowTimestampLabel(showTimestampLabel: Bool) {
        if (showTimestampLabel) {
            messageTopConstraintTimestamp.priority = 950;
            messageTopConstraint.priority = 200;
            timestampLabelView.hidden = false;
        }
        else {
            messageTopConstraintTimestamp.priority = 200;
            messageTopConstraint.priority = 950;
            timestampLabelView.hidden = true;
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
        
        self.messageLabel.text = options["text"] as! String
        let height = ChatCell.labelHeightForText( self.messageLabel.text )
        self.messageHeightConstraint.constant = height
        self.errorLabel.hidden = true
        self.messageBackground.alpha = 1
        
        if (self.messageLabel.text.characters.count == 1) {
            self.messageLabel.textAlignment = NSTextAlignment.Center
        }
        else {
            self.messageLabel.textAlignment = NSTextAlignment.Left
        }
        
        
        let alias = options["alias"] as! Alias
        self.aliasLabel.text = alias.name.lowercaseString
        self.aliasLabel.textColor = ColorConstants.aliasLabelText
        self.timestampLabel.text = Utilities.formatDate(options["date"] as! NSDate, withTrailingHours: true)
        self.timestampLabel.textColor = ColorConstants.timestampText
        self.setShowAliasLabel(options["showAliasLabel"] as! Bool)
        self.setShowTimestampLabel(options["showTimestampLabel"] as! Bool)
        
        let isOutbound = options["isOutbound"] as! Bool
        self.setIsOutbound(isOutbound)
        if (isOutbound) {
            self.setStatus(ChatEventStatus(rawValue:options["status"] as! String)!)
            
            if (rightAliasIcon == nil) {
                rightAliasIcon = AliasCircleView.instanceFromNibWithAlias(alias, color: ColorConstants.outboundChatBubble, sizeFactor: 0.7)
                self.rightIcon.addSubview(rightAliasIcon)
                rightAliasIcon.autoPinEdgesToSuperviewEdges()
            }
            
            rightAliasIcon.setCellAlias(alias, color: ColorConstants.outboundChatBubble)
            rightAliasIcon.setTextSize(15)
        }
        else {
            if (leftAliasIcon == nil) {
                leftAliasIcon = AliasCircleView.instanceFromNibWithAlias(alias, color: ColorConstants.iconColors[Int(alias.colorId)], sizeFactor: 0.7)
                self.leftIcon.addSubview(leftAliasIcon)
                leftAliasIcon.autoPinEdgesToSuperviewEdges()
            }
            
            leftAliasIcon.setCellAlias(alias, color: ColorConstants.iconColors[Int(alias.colorId)])
            leftAliasIcon.setTextSize(15)
        }
        
        if (!(options["showAliasIcon"] as! Bool)){
            self.rightIcon.hidden = true;
            self.leftIcon.hidden = true;
        }
    }
}