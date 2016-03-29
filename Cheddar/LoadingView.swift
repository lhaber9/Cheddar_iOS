//
//  LoadingView.swift
//  Cheddar
//
//  Created by Lucas Haber on 3/29/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation

class LoadingView: UIView {
//    override func awakeFromNib() {
//        
//    }
//    
    class func instanceFromNib() -> LoadingView {
        return UINib(nibName: "LoadingView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! LoadingView
    }
}