//
//  ChatCell.swift
//  Cheddar
//
//  Created by Lucas Haber on 2/7/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation

protocol ChatCellDelegate:class {
    func showDeleteMessageOptions(_ chatEvent:ChatEvent)
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
    static var messageMaxWidth:CGFloat = 230
    
    override func willMove(toSuperview newSuperview: UIView?) {
        messageBackground.layer.cornerRadius = ChatCell.singleRowHeight/2;
        messageLabel.textColor = ColorConstants.textPrimary
        messageLabel.textContainer.lineFragmentPadding = 0;
        messageLabel.textContainerInset = UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 0)
        messageLabel.isOpaque = true
        messageLabel.isSelectable = false
        messageLabel.delegate = self
        
        messageBackground.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(ChatCell.didTapCell)))
        
        backgroundView?.backgroundColor = ColorConstants.whiteColor
        timestampLabel.backgroundColor = ColorConstants.whiteColor
        aliasLabel.backgroundColor = ColorConstants.whiteColor
        
        rightIconContainer.isOpaque = true
        leftIconContainer.isOpaque = true
        
        ChatCell.messageMaxWidth = messageBackgroundWidthConstraint.constant - 20

    }
    
    override var canBecomeFirstResponder: Bool {
        get {
            return true
        }
    }
    
    class func labelHeightForText(_ text: String) -> CGFloat {
        
        var height = round(text.boundingRect(with: CGSize(width: messageMaxWidth, height: CGFloat(FLT_MAX)),
            options: NSStringDrawingOptions.usesLineFragmentOrigin,
            attributes: [NSFontAttributeName: UIFont(name: "Effra-Regular", size: 16)!],
            context: nil).height) + verticalTextBuffer
        
        if (height > ChatCell.singleRowHeight) {
            height += 4
        }
        return height
    }
    
    class func rowHeightForText(_ text: String, withAliasLabel: Bool, withTimestampLabel: Bool) -> CGFloat {
        var height = labelHeightForText(text)
        if (withAliasLabel) {
            height += aliasLabelHeight
        }
        if (withTimestampLabel) {
            height += timestampLabelHeight
        }
        return height
    }
    
    func setShowAliasLabel(_ showAliasLabel: Bool, andTimestampLabel showTimestampLabel: Bool) {
        
        if (showAliasLabel) {
            aliasLabelView.isHidden = false
        } else {
            aliasLabelView.isHidden = true
        }
        
        if (showTimestampLabel) {
            timestampLabelView.isHidden = false
            if (!showAliasLabel) {
                timestampLabelBottomToMessageConstraint.priority = 950
            } else {
                timestampLabelBottomToMessageConstraint.priority = 200
            }
        } else {
            timestampLabelView.isHidden = true
        }
    }
    
    func setIsOutbound(_ isOutbound: Bool) {
        if (isOutbound) {
            errorLeftConstraint.priority = 200;
            errorRightConstraint.priority = 900;
            leftSideMessageConstraint.priority = 200;
            rightSideMessageConstraint.priority = 900;
            leftSideLabelConstraint.priority = 200;
            rightSideLabelConstraint.priority = 900;
            messageLabel.textColor = ColorConstants.outboundMessageText
            rightIconContainer.isHidden = false;
            leftIconContainer.isHidden = true;
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
            rightIconContainer.isHidden = true;
            leftIconContainer.isHidden = false;
        }
    }
    
    func setStatus(_ status:ChatEventStatus) {
        if (status == ChatEventStatus.Success) {
            messageBackground.backgroundColor = ColorConstants.outboundChatBubble
            messageLabel.backgroundColor = ColorConstants.outboundChatBubble
        }
        else if (status == ChatEventStatus.Sent) {
            messageBackground.backgroundColor = ColorConstants.outboundChatBubbleSending
            messageLabel.backgroundColor = UIColor.clear
            messageBackground.alpha = 0.62
            messageBackground.isOpaque = false
        }
        else if (status == ChatEventStatus.Error) {
            messageBackground.backgroundColor = ColorConstants.outboundChatBubbleFail
            messageLabel.backgroundColor = ColorConstants.outboundChatBubbleFail
            errorLabel.isHidden = false
        }
    }
    
    func setBottomGapSize(_ size: CGFloat) {
        messageBottomConstraint.constant = 2 + size
    }
    
    // options are {text:String, alias:Alias, showAliasLabel:Bool, isOutbound:Bool, status:String, showAliasIcon:Bool}
    func setMessageOptions(_ options: [String:AnyObject]) {
        
        self.chatEvent = options["chatEvent"] as! ChatEvent
        
        self.messageLabel.text = chatEvent.body
        let height = ChatCell.labelHeightForText( self.messageLabel.text )
        self.messageHeightConstraint.constant = height
        self.errorLabel.isHidden = true
        self.messageBackground.alpha = 1
        self.messageBackground.isOpaque = true
        
        if (self.messageLabel.text.characters.count == 1) {
            self.messageLabel.textAlignment = NSTextAlignment.center
        }
        else {
            self.messageLabel.textAlignment = NSTextAlignment.left
        }
        
        let alias = chatEvent.alias
        self.aliasLabel.text = alias?.name.lowercased()
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
                rightAliasIcon = AliasCircleView.instanceFromNibWithAlias(alias!, color: ColorConstants.outboundChatBubble, sizeFactor: 0.7)
                self.rightIconContainer.addSubview(rightAliasIcon)
                rightAliasIcon.autoPinEdgesToSuperviewEdges()
            }
            
            rightAliasIcon.setCellAlias(alias!, color: ColorConstants.outboundChatBubble)
            rightAliasIcon.setTextSize(15)
        }
        else {
            if (leftAliasIcon == nil) {
                leftAliasIcon = AliasCircleView.instanceFromNibWithAlias(alias!, color: ColorConstants.iconColors[Int((alias?.colorId)!)], sizeFactor: 0.7)
                self.leftIconContainer.addSubview(leftAliasIcon)
                leftAliasIcon.autoPinEdgesToSuperviewEdges()
            }
            
            leftAliasIcon.setCellAlias(alias!, color: ColorConstants.iconColors[Int((alias?.colorId)!)])
            leftAliasIcon.setTextSize(15)
        }
        
        if (!(options["showAliasIcon"] as! Bool)){
            self.rightIconContainer.isHidden = true;
            self.leftIconContainer.isHidden = true;
        }
    }
    
    func links(_ text: String) -> [NSTextCheckingResult] {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        guard let detect = detector else {
            return []
        }
        return detect.matches(in: text, options: .reportCompletion, range: NSMakeRange(0, text.characters.count))
    }
    
    func didTapCell() {
        messageLabel.isUserInteractionEnabled = false
        let _ = becomeFirstResponder()
        let theMenu = UIMenuController.shared
        
        var menuItems:[UIMenuItem] = []
        menuItems.append(UIMenuItem(title:"Copy", action:#selector(ChatCell.copyCell)))
        menuItems.append(UIMenuItem(title:"Delete", action:#selector(ChatCell.deleteMessage)))
        
        if (links(messageLabel.attributedText.string).count > 0) {
            menuItems.append(UIMenuItem(title:"Go To Link", action:#selector(ChatCell.showLink)))
        }
        
        theMenu.menuItems = menuItems
        theMenu.setTargetRect(messageBackground.frame, in:self)
        theMenu.setMenuVisible(true, animated:true)
    }
    
    func showLink() {
        var link = messageLabel.attributedText.attributedSubstring(from: links(messageLabel.attributedText.string)[0].range).string
        if (!link.lowercased().hasPrefix("http://")) {
            link = "http://" + link
        }

        UIApplication.shared.openURL(URL(string: link)!)
    }
    
    func deleteMessage() {
        delegate?.showDeleteMessageOptions(chatEvent)
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if  action == #selector(ChatCell.copyCell) ||
            action == #selector(ChatCell.showLink) ||
            action == #selector(ChatCell.deleteMessage)   {
            return true
        }
        return false
    }
    
    override func becomeFirstResponder() -> Bool {
        messageBackground.alpha = 0.8
        NotificationCenter.default.addObserver(self, selector: #selector(UIResponder.resignFirstResponder), name: NSNotification.Name.UIMenuControllerDidHideMenu, object: nil)
        return super.becomeFirstResponder()
    }
    
    override func resignFirstResponder() -> Bool {
        messageBackground.alpha = 1
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIMenuControllerDidHideMenu, object: nil)
        return super.resignFirstResponder()
    }
    
    func copyCell() {
        let board = UIPasteboard.general
        board.string = messageLabel.text
        let menu = UIMenuController.shared
        menu.setMenuVisible(false, animated: true)
        messageBackground.alpha = 1
    }
    
    override func copy() -> Any {
        let board = UIPasteboard.general
        board.string = messageLabel.text
        let menu = UIMenuController.shared
        menu.setMenuVisible(false, animated: true)
        messageBackground.alpha = 1
        return messageLabel.text
    }
}
