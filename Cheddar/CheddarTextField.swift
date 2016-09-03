//
//  CheddarTextField.swift
//  Cheddar
//
//  Created by Lucas Haber on 6/30/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation

class CheddarTextField : UITextField {
    
    override func draw(_ rect: CGRect) {
        
        let startingPoint   = CGPoint(x: rect.minX, y: rect.maxY)
        let endingPoint     = CGPoint(x: rect.maxX, y: rect.maxY)
        
        let path = UIBezierPath()
        
        path.move(to: startingPoint)
        path.addLine(to: endingPoint)
        path.lineWidth = 2.0
        
        ColorConstants.textPrimary.setStroke()
        
        path.stroke()
    }
}
