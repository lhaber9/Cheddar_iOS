//
//  ActivityIndicatorCell.swift
//  Cheddar
//
//  Created by Lucas Haber on 8/21/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation

class ActivityIndicatorCell: UITableViewCell {
    
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    static var activityIndicatorHeight:CGFloat = 32
    
    
    override func willMoveToSuperview(newSuperview: UIView?) {
        activityIndicator.startAnimating()
        backgroundView?.backgroundColor = ColorConstants.whiteColor
    }
}