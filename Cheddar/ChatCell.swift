//
//  ChatCell.swift
//  Cheddar
//
//  Created by Lucas Haber on 2/7/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation

class ChatCell: UITableViewCell, UITextViewDelegate {
    
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
    
    static var textFont: UIFont = UIFont(name: "Effra", size: 16)!
    
    override func willMoveToSuperview(newSuperview: UIView?) {
        messageBackground.layer.cornerRadius = ChatCell.singleRowHeight/2;
        leftIcon.layer.cornerRadius = ChatCell.singleRowHeight/2;
        rightIcon.layer.cornerRadius = ChatCell.singleRowHeight/2;
        
        leftIcon.backgroundColor = ColorConstants.inboundIcons[0]
        rightIcon.backgroundColor = ColorConstants.outboundChatBubble
        
        messageLabel.textContainer.lineFragmentPadding = 0;
        messageLabel.textContainerInset = UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 0)
        messageLabel.selectable = false
        messageLabel.delegate = self
        
        messageBackground.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(ChatCell.didTapCell)))
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
    
    func setStatus(status:MessageStatus) {
        if (status == MessageStatus.Success) {
            messageBackground.backgroundColor = ColorConstants.outboundChatBubble
        }
        else if (status == MessageStatus.Sent) {
            messageBackground.backgroundColor = ColorConstants.outboundChatBubbleSending
            messageBackground.alpha = 0.62
        }
        else if (status == MessageStatus.Error) {
            messageBackground.backgroundColor = ColorConstants.outboundChatBubbleFail
            errorLabel.hidden = false
        }
    }

    func setMessageText(text: String, alias: Alias, isOutbound: Bool, showAliasLabel:Bool, showAliasIcon:Bool, status:MessageStatus) {
        
        let attrText = NSMutableAttributedString(string: text, attributes: [NSFontAttributeName: ChatCell.textFont])
        for match in links(text) {
            attrText.addAttribute(NSLinkAttributeName, value: "http://www.google.com", range: match.range)
        }
        
        messageLabel.attributedText = attrText
        
        let height = ChatCell.labelHeightForText( messageLabel.text )
        messageHeightConstraint.constant = height
        
        if (text.characters.count == 1) {
            messageLabel.textAlignment = NSTextAlignment.Center
        }
        else {
            messageLabel.textAlignment = NSTextAlignment.Left
        }
        
        leftIconLabel.text = alias.initials()
        rightIconLabel.text = alias.initials()
        aliasLabel.text = alias.name.lowercaseString
        aliasLabel.textColor = ColorConstants.aliasLabelText
        
        errorLabel.hidden = true
        messageBackground.alpha = 1
        
        setShowAliasLabel(showAliasLabel)
        setIsOutbound(isOutbound)
        if (isOutbound) {
            setStatus(status)
        }
        
        if (!showAliasIcon){
            rightIcon.hidden = true;
            leftIcon.hidden = true;
        }
        
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    func links(text: String) -> [NSTextCheckingResult] {
        let detector = try? NSDataDetector(types: NSTextCheckingType.Link.rawValue)
        guard let detect = detector else {
            return []
        }
        return detect.matchesInString(text, options: .ReportCompletion, range: NSMakeRange(0, text.characters.count))
    }
    
    func didTapCell() {
        messageLabel.userInteractionEnabled = false
        becomeFirstResponder()
        let theMenu = UIMenuController.sharedMenuController()
        
        var menuItems = [UIMenuItem(title:"Copy", action:#selector(ChatCell.copyCell))]
        if (links(messageLabel.attributedText.string).count > 0) {
            menuItems.append(UIMenuItem(title:"Go To Link", action:#selector(ChatCell.showLink)))
        }
        
        theMenu.menuItems = menuItems
        theMenu.setTargetRect(messageBackground.frame, inView:self)
        theMenu.setMenuVisible(true, animated:true)
    }
    
    func showLink() {
        
    }
    
    override func canPerformAction(action: Selector, withSender sender: AnyObject?) -> Bool {
        if action == #selector(ChatCell.copyCell) || action == #selector(ChatCell.showLink) {
            return true
        }
        return false
    }
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    override func becomeFirstResponder() -> Bool {
        messageBackground.alpha = 0.8
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(UIResponder.resignFirstResponder), name: UIMenuControllerDidHideMenuNotification, object: nil)
        return super.becomeFirstResponder()
    }
    
    override func resignFirstResponder() -> Bool {
        messageBackground.alpha = 1
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIMenuControllerDidHideMenuNotification, object: nil)
        return super.resignFirstResponder()
    }
    
    func copyCell() {
        let board = UIPasteboard.generalPasteboard()
        board.string = messageLabel.text
        let menu = UIMenuController.sharedMenuController()
        menu.setMenuVisible(false, animated: true)
        messageBackground.alpha = 1
    }
    
    override func copy(sender: AnyObject?) {
        let board = UIPasteboard.generalPasteboard()
        board.string = messageLabel.text
        let menu = UIMenuController.sharedMenuController()
        menu.setMenuVisible(false, animated: true)
        messageBackground.alpha = 1
    }
    
    class func labelHeightForText(text: String) -> CGFloat {
        
        var height = round(text.boundingRectWithSize(CGSizeMake(180, CGFloat(FLT_MAX)),
            options: NSStringDrawingOptions.UsesLineFragmentOrigin,
            attributes: [NSFontAttributeName: textFont],
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
    
}