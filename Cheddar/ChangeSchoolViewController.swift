//
//  ChangeSchoolViewController.swift
//  Cheddar
//
//  Created by Lucas Haber on 7/11/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation

protocol ChangeSchoolDelegate: class {
    func hideChangeSchoolView()
}

class ChangeSchoolViewController: UIViewController {
    
    weak var delegate:ChangeSchoolDelegate!
    
    @IBOutlet var emailField: UITextField!
    @IBOutlet var schoolField: UITextField!
    
    @IBOutlet var sendButton: CheddarButton!
    
    override func viewDidLoad() {
        sendButton.setPrimaryButton()
    }
    
    @IBAction func sendTap() {
        
        let schoolName = schoolField.text!
        let email = emailField.text!
        
        CheddarRequest.sendSchoolChangeRequest(schoolName, email: email, successCallback: { (object) in
                self.delegate.hideChangeSchoolView()
            }) { (error) in
        }
    }
}
