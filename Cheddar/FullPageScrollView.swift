//
//  FullPageScrollView.swift
//  Cheddar
//
//  Created by Lucas Haber on 6/7/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation

protocol FullPageScrollDelegate: class {
    func showChat()
    func showLogin()
    func changeBackgroundColor(color:UIColor)
}

class FullPageScrollView: UIViewController, UIScrollViewDelegate, FrontPageViewDelegate {
    
    weak var delegate: FullPageScrollDelegate!
    
    @IBOutlet var scrollView: UIScrollView!
    var scrollViewWidthConstraint: NSLayoutConstraint!
    
    var pages: [FrontPageView]! = []
    var currentPageIndex: Int = 0
    
    var isAnimatingPages = false
    
    override func viewDidLoad() {
        scrollView.delegate = self
    }
    
    func currentPage() -> FrontPageView {
        return pages[currentPageIndex]
    }
    
    func addPage(pageContents: FrontPageView) {
        if (scrollViewWidthConstraint != nil) {
            scrollView.removeConstraint(scrollViewWidthConstraint)
        }
        
        scrollViewWidthConstraint = nil
        scrollView.addSubview(pageContents)
        
        pageContents.autoSetDimension(ALDimension.Width, toSize: UIScreen.mainScreen().bounds.size.width)
        
        if (pages.count > 0) {
            let lastPage = pages.last!
            pageContents.autoPinEdge(ALEdge.Top, toEdge: ALEdge.Top, ofView: lastPage)
            pageContents.autoPinEdge(ALEdge.Bottom, toEdge: ALEdge.Bottom, ofView: lastPage)
            pageContents.autoPinEdge(ALEdge.Left, toEdge: ALEdge.Right, ofView: lastPage)
        }
        else {
            pageContents.autoPinEdgeToSuperviewEdge(ALEdge.Left)
            pageContents.autoPinEdgeToSuperviewEdge(ALEdge.Top)
            pageContents.autoPinEdgeToSuperviewEdge(ALEdge.Bottom)
            pageContents.autoPinEdge(ALEdge.Top, toEdge: ALEdge.Top, ofView: view, withOffset: -22)
            pageContents.autoPinEdge(ALEdge.Bottom, toEdge: ALEdge.Bottom, ofView: view)
        }
        
        scrollViewWidthConstraint = NSLayoutConstraint(item: pageContents, attribute: NSLayoutAttribute.Trailing, relatedBy: NSLayoutRelation.Equal, toItem: scrollView, attribute: NSLayoutAttribute.Trailing, multiplier: 1, constant: 0)
        scrollViewWidthConstraint.priority = 900
        
        scrollView.addConstraint(scrollViewWidthConstraint)
        
        pages.append(pageContents)
        
    }
    
    @IBAction func goToNextPage() {
        if (isAnimatingPages) { return }
        scrollToPage(currentPageIndex + 1, animated: true)
    }
    
    @IBAction func goToPrevPage() {
        if (isAnimatingPages) { return }
        scrollToPage(currentPageIndex - 1, animated: true)
    }
    
    func goToLastPage() {
        if (isAnimatingPages) { return }
        scrollToPage(pages.count - 1, animated: true)
    }
    
    func scrollToPage(pageIdx: Int, animated: Bool) {
        isAnimatingPages = true
        if (pageIdx < 0 || pageIdx >= pages.count) {
            return
        }
        
        currentPageIndex = pageIdx
        scrollView.setContentOffset(CGPointMake(scrollView.frame.size.width * CGFloat(currentPageIndex), 0.0), animated:animated)
    }
    
    // MARK: FrontPageViewDelegate
    
    func showChat() {
        delegate.showLogin()
    }

    func showLogin() {
        delegate.showLogin()
    }
  
    // MARK: UIScrollViewDelegate

    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        currentPageIndex = Int(scrollView.contentOffset.x / scrollView.frame.size.width);
    }
    
    func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        isAnimatingPages = false
        currentPageIndex = Int(scrollView.contentOffset.x / scrollView.frame.size.width);
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
    }
}