//
//  FullPageScrollView.swift
//  Cheddar
//
//  Created by Lucas Haber on 6/7/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation

class FullPageScrollView: UIViewController, UIScrollViewDelegate, FrontPageViewDelegate {
    
    @IBOutlet var scrollView: UIScrollView!
    var scrollViewWidthConstraint: NSLayoutConstraint!
    
    var pages: [UIView]! = []
    var currentPageIndex: Int = 0
    
    var isAnimatingPages = false
    
    override func viewDidLoad() {
        scrollView.delegate = self
    }
    
    func currentPage() -> UIView {
        return pages[currentPageIndex]
    }
    
    func addPage(pageContents: UIView) {
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
    
    func didScrollToPage(page: Int) {
        // implemented by subclasses
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
        scrollToPage(pages.count - 1, animated: true)
    }
    
    func goToLastPageNoAnimation() {
        scrollToPage(pages.count - 1, animated: false)
        didScrollToPage(pages.count - 1)
    }
    
    func goToFirstPage() {
        scrollToPage(0, animated: true)
    }
    
    func scrollToPage(pageIdx: Int, animated: Bool) {
        if (pageIdx < 0 || pageIdx >= pages.count) {
            return
        }
        isAnimatingPages = true
        
        currentPageIndex = pageIdx
        scrollView.setContentOffset(CGPointMake(scrollView.frame.size.width * CGFloat(currentPageIndex), 0.0), animated:animated)
    }
    
    // MARK: FrontPageViewDelegate
    
//    func showChat() {
//        delegate.showChat()
//    }
//
//    func showLogin() {
//        delegate.showLogin()
//    }
  
    // MARK: UIScrollViewDelegate

    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        currentPageIndex = Int(scrollView.contentOffset.x / scrollView.frame.size.width);
    }
    
    func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        isAnimatingPages = false
        currentPageIndex = Int(scrollView.contentOffset.x / scrollView.frame.size.width);
    }
    
//    func scrollViewDidScroll(scrollView: UIScrollView) {
//        delegate.scrollViewDidScroll(scrollView)
//    }
}