//
//  ChatRoomsViewController.swift
//  JawsTalk
//
//  Created by hyosup on 11/26/21.
//

import UIKit
import Firebase
import Kingfisher

// Chat tab
class ChatRoomsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var uid : String!
    var chatrooms : [ChatModel]! = []
    var keys : [String] = []
    var destinationUser : [String] = []
    
    @IBOutlet weak var tableview: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()

        self.uid = Auth.auth().currentUser?.uid
        self.chatrooms.removeAll()
        self.getChatroomsList()
    }
    

    // get chat room list to show
    func getChatroomsList(){
        Database.database().reference().child("chatrooms").queryOrdered(byChild: "users/"+uid).queryEqual(toValue: true).observeSingleEvent(of: DataEventType.value, with: {(datasnapshot) in
            for item in datasnapshot.children.allObjects as! [DataSnapshot]{
                if let chatroomdic = item.value as? [String:AnyObject]{
                    let chatModel = ChatModel(JSON: chatroomdic)
                    self.keys.append(item.key)
                    self.chatrooms.append(chatModel!)
                }
            }
            self.tableview.reloadData()
        })
    }

    // count number of chat rooms
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.chatrooms.count
    }
    
    // set chat room properties
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RowCell", for: indexPath) as! CustomCell
        var destinationUid : String?
        
        
        for item in chatrooms[indexPath.row].users{
            if(item.key != self.uid){
                destinationUid = item.key
                destinationUser.append(destinationUid!)
            }
        }
        
        Database.database().reference().child("users").child(destinationUid!).observeSingleEvent(of: DataEventType.value, with: {
            (datasnapshot) in
            
            let userModel = UserModel()
            userModel.setValuesForKeys(datasnapshot.value as! [String:AnyObject])
            
            cell.label_title.text = userModel.name
            let url = URL(string: userModel.profileImageUrl!)
            
            cell.imageview.layer.cornerRadius = cell.imageview.frame.width/2
            cell.imageview.layer.masksToBounds = true
            cell.imageview.kf.setImage(with: url)
            
            // check if there's a message
            if(self.chatrooms[indexPath.row].comments.keys.count == 0){
                return
            }
            
            let lastMessagekey = self.chatrooms[indexPath.row].comments.keys.sorted(){$0>$1}
            cell.label_lastmessage.text = self.chatrooms[indexPath.row].comments[lastMessagekey[0]]?.message
            
            let unixTime = self.chatrooms[indexPath.row].comments[lastMessagekey[0]]?.timestamp
            cell.label_timestamp.text = unixTime?.toDayTime
        })

        return cell
    }
    
    override func viewDidAppear(_ animated: Bool) {
        viewDidLoad()
    }
    
    // if click chat room cell, then move to chat room
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        // If group chat
        if(self.destinationUser[indexPath.row].count > 2){
            let destinationUid = self.destinationUser[indexPath.row]
            let view = self.storyboard?.instantiateViewController(withIdentifier: "GroupChatroomViewController") as! GroupChatroomViewController
            view.destinationRoom = self.keys[indexPath.row]

            
            self.navigationController?.pushViewController(view, animated: true)
        }else{
            // if one-on-one chat
            let destinationUid = self.destinationUser[indexPath.row]
            let view = self.storyboard?.instantiateViewController(withIdentifier: "ChatViewController") as! ChatViewController
            view.destinationUid = destinationUid
            
            self.navigationController?.pushViewController(view, animated: true)
        }
        
    }
}

class CustomCell : UITableViewCell{
    @IBOutlet weak var imageview: UIImageView!
    @IBOutlet weak var label_lastmessage: UILabel!
    @IBOutlet weak var label_title: UILabel!
    @IBOutlet weak var label_timestamp: UILabel!
    
}
