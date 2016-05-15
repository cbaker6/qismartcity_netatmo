//
//  LoginViewController.swift
//  QiSmartCity
//
//  Created by Corey Baker on 5/11/16.
//  Copyright © 2016 University of California San Diego. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {

    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTestField: UITextField!
    @IBOutlet weak var notificationLabel: UILabel!
    
    let networkProvider = NetatmoNetworkProvider()
    let networkLoginProvider = NetatmoLoginProvider()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
    }
    
    override func viewDidAppear(animated: Bool) {
        networkLoginProvider.getAuthenticationToken({(token) -> Void in
            
            if token != nil{
                self.notificationLabel.hidden = true
                print("User's session is still valid")
                self.performSegueWithIdentifier("seagueToMapView", sender: nil)
            
            }else{
                self.notificationLabel.hidden = false
                self.notificationLabel.text = "User session has expired, please log back in"
                print("User session has expired, please log back in")
            }
            
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func touchedSignIn(sender: AnyObject) {
        
        networkProvider.loginWithUser(usernameTextField.text!, password: passwordTestField.text!) { (token, error) -> Void in
            if token != nil {
                self.notificationLabel.hidden = true
                print("User login successful")
                
                //Need to dispatch in the main thread else MapKit will crash during sign-in
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.performSegueWithIdentifier("seagueToMapView", sender: nil)
                })
                
            }else{
                self.notificationLabel.hidden = false
                self.notificationLabel.text = "Incorrect username or password."
                print(error)
            }
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
