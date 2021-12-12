//
//  GroupChatroomViewController.swift
//  JawsTalk
//
//  Created by hyosup on 11/29/21.
//

import UIKit
import Firebase

// Group chat room view
class GroupChatroomViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // count number of messages
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    // handler user and others' message
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // user's own message
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
            // other users' message
            let destinationUser = users![self.comments[indexPath.row].uid!]
            let view = tableView.dequeueReusableCell(withIdentifier: "DestinationMessageCell", for: indexPath) as! DestinationMessageCell
            view.label_name.text = destinationUser!["name"] as! String
            view.label_message.text = self.comments[indexPath.row].message
            view.label_message.numberOfLines = 0
            
            let imageUrl = destinationUser!["profileImageUrl"] as! String
            let url = URL(string:(imageUrl))
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
    
    @IBOutlet weak var textfield_message: UITextField!
    @IBOutlet weak var tableview: UITableView!
    @IBOutlet weak var button_send: UIButton!
    var destinationRoom : String?
    var uid : String?
    var databaseRef : DatabaseReference?
    var observe : UInt?
    var comments : [ChatModel.Comment] = []
    var users : [String:AnyObject]?
    var userModel : UserModel?
    var peopleCount : Int?

    
    override func viewDidLoad() {
        super.viewDidLoad()

        uid = Auth.auth().currentUser?.uid
        
        Database.database().reference().child("users").observeSingleEvent(of: DataEventType.value, with: {(datasnapshot) in
            self.users = datasnapshot.value as! [String:AnyObject]
        })
        
        button_send.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        getMessageList()
    }
    
    // handle sendding message
    @objc func sendMessage(){
        let value : Dictionary<String,Any> = [
            "uid" : uid!,
            "message" : textfield_message.text!,
            "timestamp" : ServerValue.timestamp()
        ]
        
        Database.database().reference().child("chatrooms").child(destinationRoom!).child("comments").childByAutoId().setValue(value, withCompletionBlock: {(error,ref) in
            self.textfield_message.text = ""
        })
    }
    
    // get message from the chat rooms and show them
    func getMessageList(){
        databaseRef = Database.database().reference().child("chatrooms").child(self.destinationRoom!).child("comments")
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
            
            // to NSDic
            let nsDic = readUserDic as NSDictionary
            
            // check no meesage
            if(self.comments.last?.readUsers.keys == nil){
                
            }
            
            if((self.comments.last?.readUsers.keys.contains(uid!)) != nil){
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

    // handle message's read count
    func setReadCount(label : UILabel?, position: Int?){
        let readCount = self.comments[position!].readUsers.count
        
        if(peopleCount == nil){
            Database.database().reference().child("chatrooms").child(destinationRoom!).child("users").observeSingleEvent(of: DataEventType.value, with: {(datasnapshot) in
                let dic = datasnapshot.value as! [String:Any]
                self.peopleCount = dic.count
                let numReadCount = dic.count - readCount
                if (numReadCount > 0){
                    label?.isHidden = false
                    label!.text = String(numReadCount)
                    
                }else{
                    label?.isHidden = true
                }
            })
        }else{
            
            let numReadCount = peopleCount! - readCount
            if (numReadCount > 0){
                label?.isHidden = false
                label!.text = String(numReadCount)
                
            }else{
                label?.isHidden = true
            }
        }
    }
    
}
