//
//  SignupViewController.swift
//  JawsTalk
//
//  Created by hyosup on 11/23/21.
//

import UIKit
import Firebase

// Sign Up Scene
class SignupViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var name: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var cancel: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    
    let remoteconfg = RemoteConfig.remoteConfig()
    var color : String! = nil
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let statusBar = UIView()
        self.view.addSubview(statusBar)
        statusBar.snp.makeConstraints { (mc) in
            mc.right.top.left.equalTo(self.view)
            mc.height.equalTo(25)
        }
        
        color = remoteconfg["splash_background"].stringValue
        statusBar.backgroundColor = UIColor(hex: color)
        signUpButton.backgroundColor = UIColor(hex: color)
        cancel.backgroundColor = UIColor(hex: color)
        
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(imagePicker)))
        
        signUpButton.addTarget(self, action: #selector(signupEvent), for: .touchUpInside)
        cancel.addTarget(self, action: #selector(cancelEvent), for: .touchUpInside)
    }
    
    // Image Picker, set user's profile image
    @objc func imagePicker(){
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
        
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        imageView.image = info[.originalImage] as? UIImage
        dismiss(animated: true, completion: nil)
    }
    
    // Sign Up Event
    @objc func signupEvent(){
        password.textContentType = .oneTimeCode
        Auth.auth().createUser(withEmail: email.text!, password: password.text!) { (user,error) in
            let uid = user?.user.uid
            let image = self.imageView.image?.jpegData(compressionQuality: 0.1)
            
            // check duplication
            if error != nil {
                let alertController : UIAlertController = UIAlertController(title: "Please check the information.", message: "Duplication Error", preferredStyle: UIAlertController.Style.alert)
                
                let alertAction : UIAlertAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler:nil)
                alertController.addAction(alertAction)
                self.present(alertController, animated: true, completion: nil)
            }
            else{
            let imageRef = Storage.storage().reference().child("userImages").child(uid ?? "")

            imageRef.putData(image!, metadata: nil, completion: {(StorageMetadata, Error) in

                imageRef.downloadURL(completion: { (url, err) in

                    let values = ["name":self.name.text,"profileImageUrl":url?.absoluteString, "uid":Auth.auth().currentUser?.uid]
                    
                    Database.database().reference().child("users").child(uid!).setValue(values) { (error, ref) in
                        if(error == nil){
                            self.cancelEvent()
                        }
                    }

                })
            })
            
        }
        }
    }
    
    // Cancel Event
    @objc func cancelEvent(){
        self.dismiss(animated: true, completion: nil)
    }
}
