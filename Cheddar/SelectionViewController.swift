//
//  SelectionViewController.swift
//  
//
//  Created by Lucas Haber on 2/4/16.
//
//

import Foundation

class SelectionViewController: FrontPageViewController {
    
    @IBOutlet var oneOnOneButton: UIView!
    @IBOutlet var groupButton: UIView!
    @IBOutlet var singleImageContainer: UIView!
    @IBOutlet var groupImageContainer: UIView!
    
    var scaledSingleImage: UIImageView!
    var scaledGroupImage: UIImageView!
    var scaledSingleSelectedImage: UIImageView!
    var scaledGroupSelectedImage: UIImageView!
    
    var singleSelected: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupButtonImages()
        
        oneOnOneButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "selectedOneOnOne"))
        groupButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "selectedGroup"))
        
        showButtonImages()
    }
    
    func selectedOneOnOne() {
        oneOnOneButton.backgroundColor = UIColor.lightGrayColor()
        groupButton.backgroundColor = UIColor.whiteColor()
        singleSelected = true
        showButtonImages()
    }
    
    func selectedGroup() {
        groupButton.backgroundColor = UIColor.lightGrayColor()
        oneOnOneButton.backgroundColor = UIColor.whiteColor()
        singleSelected = false
        showButtonImages()
    }
    
    func showButtonImages() {
        if (singleSelected) {
            singleImageContainer.addSubview(scaledSingleSelectedImage)
            groupImageContainer.addSubview(scaledGroupImage)
            
            scaledSingleSelectedImage.autoAlignAxisToSuperviewAxis(ALAxis.Vertical)
            scaledSingleSelectedImage.autoPinEdgeToSuperviewEdge(ALEdge.Top, withInset: 5)
            
            scaledGroupImage.autoAlignAxisToSuperviewAxis(ALAxis.Vertical)
            scaledGroupImage.autoPinEdgeToSuperviewEdge(ALEdge.Top, withInset: 5)
        }
        else {
            singleImageContainer.addSubview(scaledSingleImage)
            groupImageContainer.addSubview(scaledGroupSelectedImage)
            
            scaledSingleImage.autoAlignAxisToSuperviewAxis(ALAxis.Vertical)
            scaledSingleImage.autoPinEdgeToSuperviewEdge(ALEdge.Top, withInset: 5)
            
            scaledGroupSelectedImage.autoAlignAxisToSuperviewAxis(ALAxis.Vertical)
            scaledGroupSelectedImage.autoPinEdgeToSuperviewEdge(ALEdge.Top, withInset: 5)
        }
        
    }
    
    func setupButtonImages() {
        
        let singleImage = UIImage(named: "single.png")!
        let groupImage = UIImage(named: "group.png")!
        let singleSelectedImage = UIImage(named: "single_selected.png")!
        let groupSelectedImage = UIImage(named: "group_selected.png")!
        
        let singleImageSize = CGSizeApplyAffineTransform(singleImage.size, CGAffineTransformMakeScale(0.166, 0.166))
        let groupImageSize = CGSizeApplyAffineTransform(groupImage.size, CGAffineTransformMakeScale(0.166, 0.166))
        let singleSelectedImageSize = CGSizeApplyAffineTransform(singleSelectedImage.size, CGAffineTransformMakeScale(0.166, 0.166))
        let groupSelectedImageSize = CGSizeApplyAffineTransform(groupSelectedImage.size, CGAffineTransformMakeScale(0.166, 0.166))
        let hasAlpha = true
        let scale: CGFloat = 0.0
        
        UIGraphicsBeginImageContextWithOptions(singleImageSize, !hasAlpha, scale)
        singleImage.drawInRect(CGRect(origin: CGPointZero, size: singleImageSize))
        scaledSingleImage = UIImageView(image:UIGraphicsGetImageFromCurrentImageContext())
        UIGraphicsEndImageContext()
        
        UIGraphicsBeginImageContextWithOptions(groupImageSize, !hasAlpha, scale)
        groupImage.drawInRect(CGRect(origin: CGPointZero, size: groupImageSize))
        scaledGroupImage = UIImageView(image:UIGraphicsGetImageFromCurrentImageContext())
        UIGraphicsEndImageContext()
        
        UIGraphicsBeginImageContextWithOptions(singleSelectedImageSize, !hasAlpha, scale)
        singleSelectedImage.drawInRect(CGRect(origin: CGPointZero, size: singleSelectedImageSize))
        scaledSingleSelectedImage = UIImageView(image:UIGraphicsGetImageFromCurrentImageContext())
        UIGraphicsEndImageContext()
        
        UIGraphicsBeginImageContextWithOptions(groupSelectedImageSize, !hasAlpha, scale)
        groupSelectedImage.drawInRect(CGRect(origin: CGPointZero, size: groupSelectedImageSize))
        scaledGroupSelectedImage = UIImageView(image:UIGraphicsGetImageFromCurrentImageContext())
        UIGraphicsEndImageContext()
    }
}