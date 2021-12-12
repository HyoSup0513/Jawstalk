//
//  SelectFriendViewController.swift
//  JawsTalk
//
//  Created by hyosup on 11/29/21.
//

import UIKit
import Firebase
import BEMCheckBox

// handle selecting other users when users make group chat
class SelectFriendViewController: UIViewController,UITableViewDataSource, UITableViewDelegate, BEMCheckBoxDelegate {
    @IBOutlet weak var create_room_btn: UIButton!
    @IBOutlet weak var tableview: UITableView!
    var array : [UserModel] = []
    var users = Dictionary<String, Bool>()
    
    // show number of users using service
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return array.count
    }
    
    // show check box
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var view = tableView.dequeueReusableCell(withIdentifier: "SelectFriendCell", for: indexPath) as! SelectFriendCell
        view.label_name.text = array[indexPath.row].name
        view.imageview_profile.kf.setImage(with: URL(string: array[indexPath.row].profileImageUrl!))
        view.checkbox.delegate = self
        view.checkbox.tag = indexPath.row
        
        return view
    }
    
    // check checkbox
    func didTap(_ checkBox: BEMCheckBox) {
        // checkbox checkked
        if(checkBox.on){
            users[self.array[checkBox.tag].uid!] = true
        }// checkbox unchecked
        else{
            users.removeValue(forKey: self.array[checkBox.tag].uid!)
        }
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()

        Database.database().reference().child("users").observe(DataEventType.value, with: { (snapshot) in
            
            self.array.removeAll()
            
            // remove self
            let myUid = Auth.auth().currentUser?.uid
            
            for child in snapshot.children{
                let fchild = child as! DataSnapshot
                let userModel = UserModel()
                
                userModel.setValuesForKeys(fchild.value as! [String : Any])
                
                if(userModel.uid == myUid){
                    continue
                }
                
                self.array.append(userModel)
            }
            
            DispatchQueue.main.async{
                self.tableview.reloadData();
            }
            
        })
        
        create_room_btn.addTarget(self, action: #selector(createRoom), for: .touchUpInside)
    }
    
    // create group chat room
    @objc func createRoom(){
        var myUid = Auth.auth().currentUser?.uid
        users[myUid!] = true
        let nsDic = users as! NSDictionary
        
        Database.database().reference().child("chatrooms").childByAutoId().child("users").setValue(nsDic)
        
        let view = self.storyboard?.instantiateViewController(withIdentifier: "PeopleViewController") as? PeopleViewController
        self.navigationController?.pushViewController(view!, animated: true)
        
        let alertController : UIAlertController = UIAlertController(title: "Group Chat Room is created!", message: "Check on Chat Tab", preferredStyle: UIAlertController.Style.alert)
        
        let alertAction : UIAlertAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler:nil)
        alertController.addAction(alertAction)
        present(alertController, animated: true, completion: nil)
    }
    

}

class SelectFriendCell : UITableViewCell {
    @IBOutlet weak var label_name: UILabel!
    @IBOutlet weak var imageview_profile: UIImageView!
    @IBOutlet weak var checkbox: BEMCheckBox!
    
}
