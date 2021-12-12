//
//  LoginViewController.swift
//  JawsTalk
//
//  Created by hyosup on 11/23/21.
//

import UIKit
import Firebase

// Login Scene
class LoginViewController: UIViewController {
    
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var signUp: UIButton!
    let remoteconfg = RemoteConfig.remoteConfig()
    var color : String! = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Check Logout
        try! Auth.auth().signOut()
        
        let statusBar = UIView()
        self.view.addSubview(statusBar)
        statusBar.snp.makeConstraints { (mc) in
            mc.right.top.left.equalTo(self.view)
            mc.height.equalTo(20)
        }
        
        color = remoteconfg["splash_background"].stringValue
        statusBar.backgroundColor = UIColor(hex: color)
        loginButton.backgroundColor = UIColor(hex: color)
        signUp.backgroundColor = UIColor(hex: color)
        
        signUp.addTarget(self, action: #selector(presentSignup), for: .touchUpInside)
        
        loginButton.addTarget(self, action: #selector(loginEvent), for: .touchUpInside)
        
        // If log in is successful, move to tab bar view.
        Auth.auth().addStateDidChangeListener { (auth, user) in
            if (user != nil){
                let view = self.storyboard?.instantiateViewController(withIdentifier: "MainViewTapBarController") as! UITabBarController
                self.present(view, animated: true, completion: nil)
            }
            
        }
        
    }
    
    // Present singup view
    @objc func presentSignup(){
        let view = self.storyboard?.instantiateViewController(withIdentifier: "SignupViewController") as! SignupViewController
        
        self.present(view, animated: true, completion: nil)
    }
    
    // Handle login event
    @objc func loginEvent(){
        Auth.auth().signIn(withEmail: email.text!, password: password.text!) { (user, err) in
            
            if(err != nil){
                let alert = UIAlertController(title: "Error", message: err.debugDescription, preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Check", style: UIAlertAction.Style.default, handler: nil))
                
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
}
