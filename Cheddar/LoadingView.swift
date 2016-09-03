//
//  LoadingView.swift
//  Cheddar
//
//  Created by Lucas Haber on 3/29/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation

class LoadingView: UIView {
    
    @IBOutlet var loadingImageView: UIImageView!
    @IBOutlet var loadingTextLabel: UILabel!
    
    override func willMove(toSuperview newSuperview: UIView?) {
        loadingImageView.image = UIImage.animatedImageNamed("LoadingImage-", duration: 2.0)
    }
    
    class func instanceFromNib() -> LoadingView {
        return UINib(nibName: "LoadingView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! LoadingView
    }
}
