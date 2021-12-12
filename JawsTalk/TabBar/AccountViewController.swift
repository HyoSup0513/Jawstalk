//
//  AccountViewController.swift
//  JawsTalk
//
//  Created by hyosup on 11/27/21.
//

import UIKit
import Firebase

// Account tab
class AccountViewController: UIViewController {

    @IBOutlet weak var user_name: UILabel!
    @IBOutlet weak var user_email: UILabel!
    @IBOutlet weak var user_comment: UILabel!
    @IBOutlet weak var conditionsButton: UIButton!
    @IBOutlet weak var logout_button: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()

        conditionsButton.addTarget(self, action: #selector(showAlert), for: .touchUpInside)
        showUserInfo()
    }
    override func viewDidAppear(_ animated: Bool) {
        viewDidLoad()
    }
    
    // show user's account information
    func showUserInfo(){
        let cur_user = Auth.auth().currentUser
        let uid = Auth.auth().currentUser?.uid
        
        Database.database().reference().child("users").child(uid!).observeSingleEvent(of: DataEventType.value, with: { (datasnapshot) in
            
            let userModel = UserModel()
            userModel.setValuesForKeys(datasnapshot.value as! [String:AnyObject])
            self.user_name.text = userModel.name
            self.user_email.text = cur_user?.email
            self.user_comment.text = userModel.comment
            
        })
    }
    
    // handle logout function
    @IBAction func logoutButtonAction(_ sender:UIButton){
        logoutCheck()
    }
    func logoutCheck(){
        
        do { try Auth.auth().signOut() }
         catch { print("Error for logging out.") }
        
        self.view.window?.rootViewController?.presentedViewController!.dismiss(animated: true, completion: nil)
    }
    
    // set user's status message
    @objc func showAlert(){
        let alertController = UIAlertController(title: "Status Message", message: nil, preferredStyle: UIAlertController.Style.alert)
        alertController.addTextField{ (textfield) in
            textfield.placeholder = "Please enter status message"
        }
        alertController.addAction(UIAlertAction(title: "Check", style: .default, handler: { (action) in
            if let textfield = alertController.textFields?.first{
                let dic = ["comment": textfield.text!]
                let uid = Auth.auth().currentUser?.uid
                Database.database().reference().child("users").child(uid!).updateChildValues(dic)
            }
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: {(action) in
            
        }))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
}
