//
//  ChatCell.swift
//  Cheddar
//
//  Created by Lucas Haber on 2/7/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation

protocol ChatCellDelegate:class {
    func showDeleteMessageOptions(chatEvent:ChatEvent)
}

class ChatCell: UITableViewCell, UITextViewDelegate {
    
    weak var delegate:ChatCellDelegate!
    
    @IBOutlet var messageLabel: UITextView!
    @IBOutlet var messageBackground: UIView!
    @IBOutlet var messageBackgroundWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet var leftSideMessageConstraint: NSLayoutConstraint!
    @IBOutlet var rightSideMessageConstraint: NSLayoutConstraint!
    @IBOutlet var leftSideLabelConstraint: NSLayoutConstraint!
    @IBOutlet var rightSideLabelConstraint: NSLayoutConstraint!
    
    @IBOutlet var messageHeightConstraint: NSLayoutConstraint!
    @IBOutlet var messageBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet var errorLeftConstraint: NSLayoutConstraint!
    @IBOutlet var errorRightConstraint: NSLayoutConstraint!
    @IBOutlet var errorLabel: UILabel!
    
    @IBOutlet var aliasLabelView: UIView!
    @IBOutlet var aliasLabel: UILabel!

    @IBOutlet var timestampLabelBottomToMessageConstraint: NSLayoutConstraint!
    @IBOutlet var timestampLabelTopConstraint: NSLayoutConstraint!
    @IBOutlet var timestampLabelView: UIView!
    @IBOutlet var timestampLabel: UILabel!

    @IBOutlet var rightIconContainer: UIView!
    @IBOutlet var leftIconContainer: UIView!
    
    var rightAliasIcon: AliasCircleView!
    var leftAliasIcon: AliasCircleView!
    
    var chatEvent:ChatEvent!
    
    static var verticalTextBuffer:CGFloat = 13
    static var bufferSize:CGFloat = 8
    static var largeBufferSize:CGFloat = 15
    static var aliasLabelHeight:CGFloat = 15
    static var timestampLabelHeight:CGFloat = 15
    static var singleRowHeight:CGFloat = 32
    static var messageMaxWidth:CGFloat = 250
    
    override func willMoveToSuperview(newSuperview: UIView?) {
        messageBackground.layer.cornerRadius = ChatCell.singleRowHeight/2;
        messageLabel.textColor = ColorConstants.textPrimary
        messageLabel.textContainer.lineFragmentPadding = 0;
        messageLabel.textContainerInset = UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 0)
        messageLabel.opaque = true
        messageLabel.selectable = false
        messageLabel.delegate = self
        
        messageBackground.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(ChatCell.didTapCell)))
        
        backgroundView?.backgroundColor = ColorConstants.whiteColor
        timestampLabel.backgroundColor = ColorConstants.whiteColor
        aliasLabel.backgroundColor = ColorConstants.whiteColor
        
        rightIconContainer.opaque = true
        leftIconContainer.opaque = true
        
        ChatCell.messageMaxWidth = messageBackgroundWidthConstraint.constant
    }
    
    class func labelHeightForText(text: String) -> CGFloat {
        
        var height = round(text.boundingRectWithSize(CGSizeMake(messageMaxWidth, CGFloat(FLT_MAX)),
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
        if (withTimestampLabel) {
            height += timestampLabelHeight
        }
        return height
    }
    
    func setShowAliasLabel(showAliasLabel: Bool, andTimestampLabel showTimestampLabel: Bool) {
        
        if (showAliasLabel) {
            aliasLabelView.hidden = false
        } else {
            aliasLabelView.hidden = true
        }
        
        if (showTimestampLabel) {
            timestampLabelView.hidden = false
            if (!showAliasLabel) {
                timestampLabelBottomToMessageConstraint.priority = 950
            } else {
                timestampLabelBottomToMessageConstraint.priority = 200
            }
        } else {
            timestampLabelView.hidden = true
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
            rightIconContainer.hidden = false;
            leftIconContainer.hidden = true;
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
            messageLabel.backgroundColor = ColorConstants.inboundChatBubble
            rightIconContainer.hidden = true;
            leftIconContainer.hidden = false;
        }
    }
    
    func setStatus(status:ChatEventStatus) {
        if (status == ChatEventStatus.Success) {
            messageBackground.backgroundColor = ColorConstants.outboundChatBubble
            messageLabel.backgroundColor = ColorConstants.outboundChatBubble
        }
        else if (status == ChatEventStatus.Sent) {
            messageBackground.backgroundColor = ColorConstants.outboundChatBubbleSending
            messageLabel.backgroundColor = UIColor.clearColor()
            messageBackground.alpha = 0.62
            messageBackground.opaque = false
        }
        else if (status == ChatEventStatus.Error) {
            messageBackground.backgroundColor = ColorConstants.outboundChatBubbleFail
            messageLabel.backgroundColor = ColorConstants.outboundChatBubbleFail
            errorLabel.hidden = false
        }
    }
    
    func setBottomGapSize(size: CGFloat) {
        messageBottomConstraint.constant = 2 + size
    }
    
    // options are {text:String, alias:Alias, showAliasLabel:Bool, isOutbound:Bool, status:String, showAliasIcon:Bool}
    func setMessageOptions(options: [String:AnyObject]) {
        
        self.chatEvent = options["chatEvent"] as! ChatEvent
        
        self.messageLabel.text = chatEvent.body
        let height = ChatCell.labelHeightForText( self.messageLabel.text )
        self.messageHeightConstraint.constant = height
        self.errorLabel.hidden = true
        self.messageBackground.alpha = 1
        self.messageBackground.opaque = true
        
        if (self.messageLabel.text.characters.count == 1) {
            self.messageLabel.textAlignment = NSTextAlignment.Center
        }
        else {
            self.messageLabel.textAlignment = NSTextAlignment.Left
        }
        
        let alias = chatEvent.alias
        self.aliasLabel.text = alias.name.lowercaseString
        self.aliasLabel.textColor = ColorConstants.aliasLabelText
        self.timestampLabel.text = Utilities.formatDate(chatEvent.createdAt, withTrailingHours: true)
        self.timestampLabel.textColor = ColorConstants.timestampText
        self.setShowAliasLabel(options["showAliasLabel"] as! Bool, andTimestampLabel: options["showTimestampLabel"] as! Bool)
        self.setBottomGapSize(options["bottomGapSize"] as! CGFloat)
        
        
        let isOutbound = options["isOutbound"] as! Bool
        self.setIsOutbound(isOutbound)
        if (isOutbound) {
            self.setStatus(ChatEventStatus(rawValue:options["status"] as! String)!)
            
            if (rightAliasIcon == nil) {
                rightAliasIcon = AliasCircleView.instanceFromNibWithAlias(alias, color: ColorConstants.outboundChatBubble, sizeFactor: 0.7)
                self.rightIconContainer.addSubview(rightAliasIcon)
                rightAliasIcon.autoPinEdgesToSuperviewEdges()
            }
            
            rightAliasIcon.setCellAlias(alias, color: ColorConstants.outboundChatBubble)
            rightAliasIcon.setTextSize(15)
        }
        else {
            if (leftAliasIcon == nil) {
                leftAliasIcon = AliasCircleView.instanceFromNibWithAlias(alias, color: ColorConstants.iconColors[Int(alias.colorId)], sizeFactor: 0.7)
                self.leftIconContainer.addSubview(leftAliasIcon)
                leftAliasIcon.autoPinEdgesToSuperviewEdges()
            }
            
            leftAliasIcon.setCellAlias(alias, color: ColorConstants.iconColors[Int(alias.colorId)])
            leftAliasIcon.setTextSize(15)
        }
        
        if (!(options["showAliasIcon"] as! Bool)){
            self.rightIconContainer.hidden = true;
            self.leftIconContainer.hidden = true;
        }
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
        
        var menuItems:[UIMenuItem] = []
        menuItems.append(UIMenuItem(title:"Copy", action:#selector(ChatCell.copyCell)))
        menuItems.append(UIMenuItem(title:"Delete", action:#selector(ChatCell.deleteMessage)))
        
        if (links(messageLabel.attributedText.string).count > 0) {
            menuItems.append(UIMenuItem(title:"Go To Link", action:#selector(ChatCell.showLink)))
        }
        
        theMenu.menuItems = menuItems
        theMenu.setTargetRect(messageBackground.frame, inView:self)
        theMenu.setMenuVisible(true, animated:true)
    }
    
    func showLink() {
        let link = messageLabel.attributedText.attributedSubstringFromRange(links(messageLabel.attributedText.string)[0].range).string
        UIApplication.sharedApplication().openURL(NSURL(string: link)!)
    }
    
    func deleteMessage() {
        delegate?.showDeleteMessageOptions(chatEvent)
    }
    
    override func canPerformAction(action: Selector, withSender sender: AnyObject?) -> Bool {
        if  action == #selector(ChatCell.copyCell) ||
            action == #selector(ChatCell.showLink) ||
            action == #selector(ChatCell.deleteMessage)   {
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
}