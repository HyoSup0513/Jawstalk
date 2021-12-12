//
//  ChatViewController.swift
//  JawsTalk
//
//  Created by hyosup on 11/25/21.
//

import UIKit
import Firebase
import Kingfisher

// Chat Scene
class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var bottomConstraint : NSLayoutConstraint!
    @IBOutlet weak var tableview : UITableView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var textfield_message : UITextField!
    var uid : String?
    var chatRoomUid : String?
    var comments : [ChatModel.Comment] = []
    var userModel : UserModel?
    var databaseRef : DatabaseReference?
    var observe : UInt?
    var peopleCount : Int?
    
    public var destinationUid : String? // chat target uid
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        uid = Auth.auth().currentUser?.uid
        sendButton.addTarget(self, action: #selector(createRoom), for: .touchUpInside)
        checkChatRoom()
        self.tabBarController?.tabBar.isHidden = true
        let tap : UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    // Keyboard will disappear when typing ends
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
        self.tabBarController?.tabBar.isHidden = false
        
        // end watching
        databaseRef?.removeObserver(withHandle: observe!)
    }
    
    @objc func keyboardWillShow(notification : Notification){
        if let keyboardSize = (notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue{
            self.bottomConstraint.constant = keyboardSize.height
        }
        
        UIView.animate(withDuration: 0, animations: {self.view.layoutIfNeeded()}, completion: {(complete) in
            
            if self.comments.count > 0 {
                self.tableview.scrollToRow(at: IndexPath(item:self.comments.count - 1, section:0), at: UITableView.ScrollPosition.bottom, animated: true)
            }
        })
    }
    
    @objc func keyboardWillHide(notification : Notification){
        self.bottomConstraint.constant = 20
        self.view.layoutIfNeeded()
    }
    
    @objc func dismissKeyboard(){
        self.view.endEditing(true)
    }
    
    // Keyboard appear when to type
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if(self.comments[indexPath.row].uid == uid){
            let view = tableView.dequeueReusableCell(withIdentifier: "MyMessageCell", for: indexPath) as! MyMessageCell
            view.label_message!.text = self.comments[indexPath.row].message
            view.label_message!.numberOfLines = 0
            
            if let time = self.comments[indexPath.row].timestamp{
                view.label_timestamp.text = time.toDayTime
            }
            
            setReadCount(label: view.label_read, position: indexPath.row)
            
            return view
        }else{
            let view = tableView.dequeueReusableCell(withIdentifier: "DestinationMessageCell", for: indexPath) as! DestinationMessageCell
            view.label_name.text = userModel?.name
            view.label_message.text = self.comments[indexPath.row].message
            view.label_message.numberOfLines = 0
            
            let url = URL(string:(self.userModel?.profileImageUrl)!)!
            view.imageview_profile.layer.cornerRadius = view.imageview_profile.frame.width/2
            view.imageview_profile.clipsToBounds = true
            view.imageview_profile.kf.setImage(with: url)
            
            if let time = self.comments[indexPath.row].timestamp{
                view.label_timestamp.text = time.toDayTime
            }
            
            setReadCount(label: view.label_read, position: indexPath.row)
            
            return view
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    
    @objc func createRoom(){
        let createRoomInfo : Dictionary<String, Any> = [
            "users": [
                uid!: true,
                destinationUid! : true
            ]
        ]
        
        if(chatRoomUid == nil){
            self.sendButton.isEnabled = false
            
            // create chat room
            Database.database().reference().child("chatrooms").childByAutoId().setValue(createRoomInfo, withCompletionBlock: {(err, ref) in
                if(err == nil){
                    self.checkChatRoom()
                }
            })
        }else{
            // if chat room is already exists, don't create same room again
            let value : Dictionary<String, Any> = [
                "uid" : uid!,
                "message" : textfield_message.text!,
                "timestamp" : ServerValue.timestamp()
            ]
            
            Database.database().reference().child("chatrooms").child(chatRoomUid!).child("comments").childByAutoId().setValue(value) { (error, ref) in
                self.textfield_message.text = ""
            }
        }
    }
    
    // Check the chat room to display
    func checkChatRoom(){
        Database.database().reference().child("chatrooms").queryOrdered(byChild: "users/" + uid!).queryEqual(toValue: true).observeSingleEvent(of: DataEventType.value, with: { (datasnapshot) in
            for item in datasnapshot.children.allObjects as! [DataSnapshot]{
                if let chatRoomDic = item.value as? [String:AnyObject]{
                    let chatModel = ChatModel(JSON: chatRoomDic)
                    if(chatModel?.users[self.destinationUid!] == true && chatModel?.users.count == 2){
                        self.chatRoomUid = item.key
                        self.sendButton.isEnabled = true
                        self.getDestinationInfo()
                    }
                }
            }
        })
    }
    
    // Get infomration of the other user
    func getDestinationInfo(){
        Database.database().reference().child("users").child(self.destinationUid!).observeSingleEvent(of: DataEventType.value, with: { (datasnapshot) in
            self.userModel = UserModel()
            self.userModel?.setValuesForKeys(datasnapshot.value as! [String:Any])
            self.getMessageList()
        })
    }
    
    // Set user's read count for message cell
    func setReadCount(label : UILabel?, position: Int?){
        let readCount = self.comments[position!].readUsers.count
        
        // if there's no user
        if(peopleCount == nil){
            Database.database().reference().child("chatrooms").child(chatRoomUid!).child("users").observeSingleEvent(of: DataEventType.value, with: {(datasnapshot) in
                let dic = datasnapshot.value as! [String:Any]
                self.peopleCount = dic.count
                let numReadCount = self.peopleCount! - readCount
                if (numReadCount > 0){
                    label?.isHidden = false
                    label?.text = String(numReadCount)
                    
                }else{
                    label?.isHidden = true
                }
            })
        }else{
            
            let numReadCount = self.peopleCount! - readCount
            if (numReadCount > 0){
                label?.isHidden = false
                label?.text = String(numReadCount)
                
            }else{
                label?.isHidden = true
            }
        }
    }
    
    func getMessageList(){
        databaseRef = Database.database().reference().child("chatrooms").child(self.chatRoomUid!).child("comments")
        observe = databaseRef!.observe(DataEventType.value, with: { [self](datasnapshot) in
            self.comments.removeAll()
            var readUserDic : Dictionary<String, AnyObject> = [:]
            for item in datasnapshot.children.allObjects as! [DataSnapshot]{
                let key = item.key as String
                let comment = ChatModel.Comment(JSON: item.value as! [String: AnyObject])
                let comment_mod = ChatModel.Comment(JSON: item.value as! [String: AnyObject])
                comment_mod?.readUsers[self.uid!] = true
                readUserDic[key] = comment_mod?.toJSON() as! NSDictionary
                self.comments.append(comment!)
            }
            
            // Convert to NSDic
            let nsDic = readUserDic as NSDictionary
            
            // check there's a message or not
            if(self.comments.last?.readUsers.keys == nil){
            }
            
            // calculate read count
            if((self.comments.last?.readUsers.keys.contains(self.uid!)) != nil){
                datasnapshot.ref.updateChildValues(nsDic as! [AnyHashable : Any], withCompletionBlock: {(error,ref) in
                    self.tableview.reloadData()
                    
                    if self.comments.count > 0 {
                        self.tableview.scrollToRow(at: IndexPath(item:self.comments.count - 1, section:0), at: UITableView.ScrollPosition.bottom, animated: true)
                    }
                })
            }else{
                self.tableview.reloadData()
                
                if self.comments.count > 0 {
                    self.tableview.scrollToRow(at: IndexPath(item:self.comments.count - 1, section:0), at: UITableView.ScrollPosition.bottom, animated: true)
                }
            }

            
        })
    }
}

extension Int{
    var toDayTime : String{
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en-US")
        dateFormatter.dateFormat = "yyyy.MM.dd HH:mm"
        let date = Date(timeIntervalSince1970: Double(self)/1000)
        return dateFormatter.string(from: date)
    }
}

class MyMessageCell : UITableViewCell{

    @IBOutlet weak var label_timestamp: UILabel!
    @IBOutlet weak var label_message: UILabel!
    @IBOutlet weak var label_read: UILabel!
}

class DestinationMessageCell :UITableViewCell{

    @IBOutlet weak var label_name: UILabel!
    @IBOutlet weak var imageview_profile: UIImageView!

    @IBOutlet weak var label_timestamp: UILabel!
    @IBOutlet weak var label_read: UILabel!
    
    @IBOutlet weak var label_message: UILabel!
}
