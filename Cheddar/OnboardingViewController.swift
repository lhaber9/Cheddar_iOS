//
//  OnboardingViewController.swift
//  Cheddar
//
//  Created by Lucas Haber on 6/5/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation

class OnboardingViewController: FullPageScrollView {
    
    @IBOutlet var leftArrow: UIImageView!
    @IBOutlet var rightArrow: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        leftArrow.alpha = 0
        
        setupOnboardingPages()
        
        delegate.changeBackgroundColor(ColorConstants.iconColors.first!)
    }
    
    func setupOnboardingPages() {
        let introView = IntroView.instanceFromNib()
        let matchView = MatchView.instanceFromNib()
        let groupView = GroupView.instanceFromNib()
        let alphaWarningView = AlphaWarningView.instanceFromNib()
        
        introView.delegate = self
        matchView.delegate = self
        groupView.delegate = self
        alphaWarningView.delegate = self
        
        addPage(introView)
        addPage(matchView)
        addPage(groupView)
        addPage(alphaWarningView)
    }
    
    func displayArrows() {
        UIView.animateWithDuration(0.1) { () -> Void in
            if (self.currentPageIndex == 0) {
                self.leftArrow.alpha = 0
                self.rightArrow.alpha = 1
            }
            else if (self.currentPageIndex == 1 || self.currentPageIndex == 2) {
                self.leftArrow.alpha = 1
                self.rightArrow.alpha = 1
            }
            else if (self.currentPageIndex == 3) {
                self.leftArrow.alpha = 0
                self.rightArrow.alpha = 0
            }
        }
    }
    
    // MARK: UIScrollViewDelegate
    
    override func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        super.scrollViewDidEndDecelerating(scrollView);
        displayArrows()
    }
    
    override func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        super.scrollViewDidEndScrollingAnimation(scrollView);
        displayArrows()
    }
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView);
        let color = ColorConstants.iconColorForFloat(scrollView.contentOffset.x / scrollView.frame.size.width)
        delegate.changeBackgroundColor(color)
    }
}