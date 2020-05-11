//
//  loginViewController.swift
//  Test
//
//  Created by Shunzhe Ma on 5/11/20.
//  Copyright © 2020 Shunzhe Ma. All rights reserved.
//

import Foundation
import UIKit
import AuthenticationServices
import CloudKit

class loginViewController: UIViewController {
    
    @IBOutlet var signInBtnView: UIView!
    var authorizationButton: ASAuthorizationAppleIDButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
         authorizationButton = ASAuthorizationAppleIDButton(type: .default, style: .whiteOutline)
        authorizationButton.frame = CGRect(origin: .zero, size: signInBtnView.frame.size)
        authorizationButton.addTarget(self, action: #selector(handleAppleIdRequest), for: .touchUpInside)
        signInBtnView.addSubview(authorizationButton)
    }
    
    @objc func handleAppleIdRequest(){
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.performRequests()
    }
    
}

extension loginViewController: ASAuthorizationControllerDelegate {
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        let privateDatabase = CKContainer(identifier: "iCloud.com.[Your Name].[App Name]").privateCloudDatabase
        if let appleIDCredential = authorization.credential as?  ASAuthorizationAppleIDCredential {
            let userID = appleIDCredential.user
            if let name = appleIDCredential.fullName?.givenName,
                let emailAddr = appleIDCredential.email {
                //New user (Signing up).
                //Save this information to CloudKit
                let record = CKRecord(recordType: "UserInfo", recordID: CKRecord.ID(recordName: userID))
                record["name"] = name
                record["emailAddress"] = emailAddr
                privateDatabase.save(record) { (_, _) in
                    UserDefaults.standard.set(record.recordID.recordName, forKey: "userProfileID")
                }
            } else {
                //Returning user (signing in)
                //Fetch the user name/ email address
                //from private CloudKit
                privateDatabase.fetch(withRecordID: CKRecord.ID(recordName: userID)) { (record, error) in
                    if let fetchedInfo = record {
                        let name = fetchedInfo["name"] as? String
                        let userEmailAddr = fetchedInfo["emailAddress"] as? String
                        
                        //You can now use the user name and email address (like save it to local)
                        print("Name is \(name) and email address is \(userEmailAddr)")
                        UserDefaults.standard.set(userID, forKey: "userProfileID")
                    }
                }
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print(error.localizedDescription)
    }
    
}

