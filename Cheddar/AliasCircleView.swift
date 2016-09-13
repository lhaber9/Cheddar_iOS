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
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        if (newSuperview == nil || color == nil || alias == nil) {
            return
        }
            
        height = newSuperview!.frame.height
        
        lockedBackgroundColor = UIColor.clear
        
        indicatorView.layer.cornerRadius = indicatorView.frame.size.height / 2
        indicatorView.lockedBackgroundColor = ColorConstants.outboundChatBubble
        indicatorStrokeView.layer.cornerRadius = indicatorStrokeView.frame.size.height / 2
        indicatorStrokeView.lockedBackgroundColor = ColorConstants.whiteColor
        
        initalsLabel.text = alias.initials()
        initalsLabel.textColor = ColorConstants.whiteColor
        initialsWidthConstraint.constant = height * sizeFactor
        initalsLabel.adjustsFontSizeToFitWidth = true
        
        layoutIfNeeded()
        setNeedsDisplay()
    }
    
    class func instanceFromNibWithAlias(_ alias: Alias, color: UIColor, sizeFactor: CGFloat) -> AliasCircleView {
        let aliasCircleView = UINib(nibName: "AliasCircleView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! AliasCircleView
        aliasCircleView.alias = alias
        aliasCircleView.color = color
        aliasCircleView.sizeFactor = sizeFactor
        return aliasCircleView
    }
    
    func setCellAlias(_ alias: Alias, color:UIColor) {
        self.alias = alias
        initalsLabel.text = alias.initials()
        self.color = color
        layoutIfNeeded()
        setNeedsDisplay()
    }
    
    func setTextSize(_ size: CGFloat) {
        initalsLabel.adjustsFontSizeToFitWidth = false
        initalsLabel.font = UIFont(name: "Effra-Medium", size: size)
        initalsLabel.removeConstraint(initialsWidthConstraint)
        layoutIfNeeded()
        setNeedsDisplay()
    }
    
    func showUnreadIndicator(_ show: Bool) {
        let radius = height / 2
        let indicatorRadius = indicatorStrokeView.frame.height / 2
        let indicatorOffset = radius - (radius * 0.70710) - indicatorRadius
        
        indicatorTopConstraint.constant = indicatorOffset
        indicatorLeftConstraint.constant = indicatorOffset
        
        if (show) {
            indicatorStrokeView.isHidden = false
        }
        else {
            indicatorStrokeView.isHidden = true
        }
        
        layoutIfNeeded()
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let ctx: CGContext = UIGraphicsGetCurrentContext()!
        ctx.saveGState()
        
        let path = UIBezierPath(roundedRect: rect, cornerRadius: rect.height / 2)
        let clipPath: CGPath = path.cgPath
        
        ctx.addPath(clipPath)
        if (color != nil) {
            ctx.setFillColor(color.cgColor)
        }
        
        ctx.closePath()
        ctx.fillPath()
        ctx.restoreGState()
    }
}
