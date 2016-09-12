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
    
    //@IBOutlet var errorLeftConstraint: NSLayoutConstraint!
    //@IBOutlet var errorRightConstraint: NSLayoutConstraint!
    @IBOutlet var errorLabel: UILabel!
    
    @IBOutlet var aliasLabelView: UIView!
    @IBOutlet var aliasLabel: UILabel!

    @IBOutlet var aliasLabelLeftConstraint: NSLayoutConstraint!
    @IBOutlet var aliasLabelRightConstraint: NSLayoutConstraint!
    @IBOutlet var mainViewTopConstraint: NSLayoutConstraint!
    
    @IBOutlet var timestampLabelBottomToMessageConstraint: NSLayoutConstraint!
    @IBOutlet var timestampLabelTopConstraint: NSLayoutConstraint!
    @IBOutlet var timestampLabelView: UIView!
    @IBOutlet var timestampLabel: UILabel!

    @IBOutlet var rightIconContainer: UIView!
    @IBOutlet var leftIconContainer: UIView!
    
    var rightAliasIcon: AliasCircleView!
    var leftAliasIcon: AliasCircleView!
    
    var chatEvent:ChatEvent!
    
    var isOutbound: Bool!
    var status: ChatEventStatus!
    var bottomGap: CGFloat!
    
    static var verticalTextBuffer:CGFloat = 13
    static var bufferSize:CGFloat = 8
    static var largeBufferSize:CGFloat = 15
    static var aliasLabelHeight:CGFloat = 15
    static var timestampLabelHeight:CGFloat = 15
    static var singleRowHeight:CGFloat = 32
    static var messageMaxWidth:CGFloat = 230
    
    override func willMove(toSuperview newSuperview: UIView?) {
        //messageBackground.layer.cornerRadius = ChatCell.singleRowHeight/2;
        
        //messageBackground.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(ChatCell.didTapCell)))
        
        backgroundView?.backgroundColor = ColorConstants.whiteColor
        timestampLabel.backgroundColor = ColorConstants.whiteColor
        aliasLabel.backgroundColor = ColorConstants.whiteColor
        
        //ChatCell.messageMaxWidth = 180
        
        rightIconContainer.backgroundColor = UIColor.clear
        leftIconContainer.backgroundColor = UIColor.clear
    }
    
    override var canBecomeFirstResponder: Bool {
        get {
            return true
        }
    }
    
    class func labelRectForText(_ text: String) -> CGRect {
        return text.boundingRect(with: CGSize(width: messageMaxWidth, height: CGFloat(FLT_MAX)),
                          options: NSStringDrawingOptions.usesLineFragmentOrigin,
                          attributes: [NSFontAttributeName: UIFont(name: "Effra-Regular", size: 16)!],
                          context: nil)
    }
    
    class func labelHeightForText(_ text: String) -> CGFloat {
        return labelRectForText(text).height
    }


    class func backgroundHeightForText(_ text: String) -> CGFloat {
        
        var height = round(labelHeightForText(text)) + verticalTextBuffer
        
        if (height > ChatCell.singleRowHeight) {
            height += 4
        }
        return height
    }
    
    class func labelWidthForText(_ text: String) -> CGFloat {
        return labelRectForText(text).width
    }
    
    class func backgroundWidthForText(_ text: String) -> CGFloat {
        
        let width = round(labelWidthForText(text)) + 20
        
        return width
    }
    
    class func rowHeightForText(_ text: String, withAliasLabel: Bool, withTimestampLabel: Bool) -> CGFloat {
        var height = backgroundHeightForText(text)
        if (withAliasLabel) {
            height += aliasLabelHeight
        }
        if (withTimestampLabel) {
            height += timestampLabelHeight
        }
        return height
    }
    
    func setShowAliasLabel(_ showAliasLabel: Bool, andTimestampLabel showTimestampLabel: Bool) {
        
        var topConstant:CGFloat = 0
        
        if (showAliasLabel) {
            topConstant += 15
            aliasLabelView.isHidden = false
        } else {
            aliasLabelView.isHidden = true
        }
        
        if (showTimestampLabel) {
            topConstant += 15
            timestampLabelView.isHidden = false
            if (!showAliasLabel) {
                timestampLabelBottomToMessageConstraint.priority = 950
            } else {
                timestampLabelBottomToMessageConstraint.priority = 200
            }
        } else {
            timestampLabelView.isHidden = true
        }
        
        mainViewTopConstraint.constant = topConstant
        layoutIfNeeded()
    }
    
    func setIsOutbound(_ isOutbound: Bool) {
        self.isOutbound = isOutbound
        if (isOutbound) {
            //errorLeftConstraint.priority = 200;
            //errorRightConstraint.priority = 900;
            aliasLabelLeftConstraint.priority = 200
            aliasLabelRightConstraint.priority = 900
            rightIconContainer.isHidden = false;
            leftIconContainer.isHidden = true;
        }
        else {
            //errorLeftConstraint.priority = 900;
            //errorRightConstraint.priority = 200;
            aliasLabelLeftConstraint.priority = 900
            aliasLabelRightConstraint.priority = 200
            rightIconContainer.isHidden = true;
            leftIconContainer.isHidden = false;
        }
    }
    
    func setStatus(_ status:ChatEventStatus) {
        self.status = status
        if (status == ChatEventStatus.Error) {
            errorLabel.isHidden = false
        }
    }
    
    func setBottomGapSize(_ size: CGFloat) {
        bottomGap = 2 + size
    }
    
    // options are {text:String, alias:Alias, showAliasLabel:Bool, isOutbound:Bool, status:String, showAliasIcon:Bool}
    func setMessageOptions(_ options: [String:AnyObject]) {
        
        self.chatEvent = options["chatEvent"] as! ChatEvent
        
        self.errorLabel.isHidden = true
        
        let alias = chatEvent.alias
        self.aliasLabel.text = alias?.name.lowercased()
        self.aliasLabel.textColor = ColorConstants.aliasLabelText
        DispatchQueue.main.async {
            self.timestampLabel.text = Utilities.formatDate(self.chatEvent.createdAt, withTrailingHours: true)
        }
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
                rightAliasIcon.setTextSize(15)
            }
            
            rightAliasIcon.setCellAlias(alias!, color: ColorConstants.outboundChatBubble)
        }
        else {
            if (leftAliasIcon == nil) {
                leftAliasIcon = AliasCircleView.instanceFromNibWithAlias(alias!, color: ColorConstants.iconColors[Int((alias?.colorId)!)], sizeFactor: 0.7)
                self.leftIconContainer.addSubview(leftAliasIcon)
                leftAliasIcon.autoPinEdgesToSuperviewEdges()
                leftAliasIcon.setTextSize(15)
            }
            
            leftAliasIcon.setCellAlias(alias!, color: ColorConstants.iconColors[Int((alias?.colorId)!)])
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
        //messageLabel.isUserInteractionEnabled = false
        let _ = becomeFirstResponder()
        let theMenu = UIMenuController.shared
        
        var menuItems:[UIMenuItem] = []
        menuItems.append(UIMenuItem(title:"Copy", action:#selector(ChatCell.copyCell)))
        menuItems.append(UIMenuItem(title:"Delete", action:#selector(ChatCell.deleteMessage)))
        
        if (links(chatEvent.body).count > 0) {
            menuItems.append(UIMenuItem(title:"Go To Link", action:#selector(ChatCell.showLink)))
        }
        
        theMenu.menuItems = menuItems
        //theMenu.setTargetRect(messageBackground.frame, in:self)
        theMenu.setMenuVisible(true, animated:true)
    }
    
    func showLink() {
        let text: NSString = chatEvent.body! as NSString
        var link = text.substring(with: links(chatEvent.body)[0].range)
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
        //messageBackground.alpha = 0.8
        NotificationCenter.default.addObserver(self, selector: #selector(UIResponder.resignFirstResponder), name: NSNotification.Name.UIMenuControllerDidHideMenu, object: nil)
        return super.becomeFirstResponder()
    }
    
    override func resignFirstResponder() -> Bool {
        //messageBackground.alpha = 1
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIMenuControllerDidHideMenu, object: nil)
        return super.resignFirstResponder()
    }
    
    func copyCell() {
        let board = UIPasteboard.general
        board.string = chatEvent.body
        let menu = UIMenuController.shared
        menu.setMenuVisible(false, animated: true)
        //messageBackground.alpha = 1
    }
    
    override func copy() -> Any {
        let board = UIPasteboard.general
        board.string = chatEvent.body
        let menu = UIMenuController.shared
        menu.setMenuVisible(false, animated: true)
        //messageBackground.alpha = 1
        return chatEvent.body
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let ctx: CGContext = UIGraphicsGetCurrentContext()!
        ctx.saveGState()
    
        let text = chatEvent.body!
        
        let backgroundWidth = ChatCell.backgroundWidthForText(text)
        let backgroundHeight = ChatCell.backgroundHeightForText(text)
        let y = rect.height - bottomGap - backgroundHeight
        var x = rect.width - 48 - backgroundWidth
        
        if (isOutbound == false) {
            x = 48
        }
        
        let backgroundRect = CGRect(x: x, y: y, width: backgroundWidth, height: backgroundHeight)
        let path = UIBezierPath(roundedRect: backgroundRect, cornerRadius: ChatCell.singleRowHeight/2)
        let clipPath: CGPath = path.cgPath
        
        ctx.addPath(clipPath)
        
        if (isOutbound == true) {
            if (status == ChatEventStatus.Success) {
                ctx.setFillColor(ColorConstants.outboundChatBubble.cgColor)
            }
            else if (status == ChatEventStatus.Sent) {
                ctx.setFillColor(ColorConstants.outboundChatBubbleSending.withAlphaComponent(0.62).cgColor)
            }
            else if (status == ChatEventStatus.Error) {
                ctx.setFillColor(ColorConstants.outboundChatBubbleFail.cgColor)
            }
        } else {
            ctx.setFillColor(ColorConstants.inboundChatBubble.cgColor)
        }
        
        ctx.closePath()
        ctx.fillPath()
        ctx.restoreGState()
        
        let textRect = CGRect(x: x + 10, y: y + 7, width: ChatCell.labelWidthForText(text), height: ChatCell.labelHeightForText(text))

        var attributes: [String : Any] = [
            NSForegroundColorAttributeName: ColorConstants.textPrimary,
            NSFontAttributeName: UIFont(name: "Effra-Regular", size: 16)!
        ]
        
        if (isOutbound == true) {
            attributes[NSForegroundColorAttributeName] = ColorConstants.outboundMessageText
        }
        
        let paragraphStyle = NSMutableParagraphStyle()
        if (text.characters.count == 1) {
            paragraphStyle.alignment = .center
        }
        else {
            paragraphStyle.alignment = .left
        }
        attributes[NSParagraphStyleAttributeName] = paragraphStyle
        
        text.draw(in: textRect, withAttributes: attributes)
    }
}
