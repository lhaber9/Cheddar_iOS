//
//  AliasCircleView.swift
//  Cheddar
//
//  Created by Lucas Haber on 5/19/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation

class AliasCircleView: LockedBackgroundColorView {
    
    @IBOutlet var circleView: LockedBackgroundColorView!
    @IBOutlet var initalsLabel: UILabel!
    
    @IBOutlet var indicatorView: LockedBackgroundColorView!
    @IBOutlet var indicatorStrokeView: LockedBackgroundColorView!
    
    @IBOutlet var initialsWidthConstraint: NSLayoutConstraint!
    @IBOutlet var indicatorTopConstraint: NSLayoutConstraint!
    @IBOutlet var indicatorLeftConstraint: NSLayoutConstraint!
    
    var alias: Alias!
    var color: UIColor!
    var sizeFactor: CGFloat!
    
    var height: CGFloat!
    
    override func willMoveToSuperview(newSuperview: UIView?) {
        super.willMoveToSuperview(newSuperview)
        if (newSuperview == nil || color == nil || alias == nil) {
            return
        }
            
        height = newSuperview!.frame.height
        
        layer.cornerRadius = height / 2
        lockedBackgroundColor = color
        
        indicatorView.layer.cornerRadius = indicatorView.frame.size.height / 2
        indicatorView.lockedBackgroundColor = ColorConstants.outboundChatBubble
        indicatorStrokeView.layer.cornerRadius = indicatorStrokeView.frame.size.height / 2
        indicatorStrokeView.lockedBackgroundColor = UIColor.whiteColor()
        
        initalsLabel.text = alias.initials()
        initalsLabel.textColor = UIColor.whiteColor()
        initialsWidthConstraint.constant = height * sizeFactor
        initalsLabel.adjustsFontSizeToFitWidth = true
        
        layoutIfNeeded()
    }
    
    class func instanceFromNibWithAlias(alias: Alias, color: UIColor, sizeFactor: CGFloat) -> AliasCircleView {
        let aliasCircleView = UINib(nibName: "AliasCircleView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! AliasCircleView
        aliasCircleView.alias = alias
        aliasCircleView.color = color
        aliasCircleView.sizeFactor = sizeFactor
        return aliasCircleView
    }
    
    func setCellAlias(alias: Alias, color:UIColor) {
        self.alias = alias
        initalsLabel.text = alias.initials()
        lockedBackgroundColor = color
    }
    
    func setTextSize(size: CGFloat) {
        initalsLabel.adjustsFontSizeToFitWidth = false
        initalsLabel.font = UIFont(name: "Effra-Medium", size: size)
        initalsLabel.removeConstraint(initialsWidthConstraint)
        layoutIfNeeded()
    }
    
    func showUnreadIndicator(show: Bool) {
        let radius = height / 2
        let indicatorRadius = indicatorStrokeView.frame.height / 2
        let indicatorOffset = radius - (radius * 0.70710) - indicatorRadius
        
        indicatorTopConstraint.constant = indicatorOffset
        indicatorLeftConstraint.constant = indicatorOffset
        
        if (show) {
            indicatorStrokeView.hidden = false
        }
        else {
            indicatorStrokeView.hidden = true
        }
    }
}