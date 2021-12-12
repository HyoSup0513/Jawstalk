//
//  MainViewController.swift
//  JawsTalk
//
//  Created by hyosup on 11/24/21.
//

import UIKit
import SnapKit
import Firebase
import Kingfisher

// People Tab
class PeopleViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var array : [UserModel] = []
    var tableview : UITableView!
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // table view
        tableview = UITableView()
        tableview.delegate = self
        tableview.dataSource = self
        tableview.register(PeopleViewTableCell.self, forCellReuseIdentifier: "Cell")
        view.addSubview(tableview)
        tableview.snp.makeConstraints {
            (mc) in mc.top.equalTo(view)
            mc.bottom.left.right.equalTo(view)
            
        }

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
        
        // Create Group Chat button
        let GroupChatButton = UIButton()
        view.addSubview(GroupChatButton)
        GroupChatButton.snp.makeConstraints{
            (mc) in
            mc.bottom.equalTo(view).offset(-90)
            mc.right.equalTo(view).offset(-20)
            mc.width.height.equalTo(50)
        }
        GroupChatButton.backgroundColor = UIColor.green
        GroupChatButton.addTarget(self, action: #selector(showSelectFriendController), for: .touchUpInside)
        GroupChatButton.layer.cornerRadius = 25
        GroupChatButton.layer.masksToBounds = true
        GroupChatButton.setTitle("Group Chat", for: .normal)
        GroupChatButton.titleLabel?.numberOfLines = 2;
        GroupChatButton.titleLabel?.textAlignment = .center
        GroupChatButton.titleLabel?.lineBreakMode = .byWordWrapping
        GroupChatButton.titleLabel?.font = .systemFont(ofSize: 14)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        viewDidLoad()
    }
    
    @objc func showSelectFriendController(){
        self.performSegue(withIdentifier: "SelectFriendSegue", sender: nil)
    }
    
    // people cell design
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableview.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! PeopleViewTableCell
        
        let imageview = cell.imageview!
        
        imageview.snp.makeConstraints { (mc) in
            mc.centerY.equalTo(cell)
            mc.left.equalTo(cell).offset(10)
            mc.height.width.equalTo(35)
            
        }
        
        let url = URL(string: array[indexPath.row].profileImageUrl!)
        imageview.layer.cornerRadius = 50/2
        imageview.clipsToBounds = true
        imageview.kf.setImage(with: url)
        
        
        let label = cell.label
        label.snp.makeConstraints{(mc) in
            mc.centerY.equalTo(cell)
            mc.left.equalTo(imageview.snp.right).offset(20)
        }
        
        label.text = array[indexPath.row].name
        
        // set and show people's status message
        let label_status = cell.label_status!
        label_status.snp.makeConstraints{(mc) in
            mc.centerX.right.equalTo(cell.uiview_status_backgrond)
            mc.centerY.equalTo(cell.uiview_status_backgrond)
        }
        if let status_comment = array[indexPath.row].comment{
            label_status.text = status_comment
        }
        
        cell.uiview_status_backgrond.snp.makeConstraints{(mc) in
            mc.right.equalTo(cell).offset(-10)
            mc.centerY.equalTo(cell)
            if let count = label_status.text?.count{
                mc.width.equalTo(count * 9)
            }else{
                mc.width.equalTo(0)
            }
            mc.height.equalTo(30)
        }
        cell.uiview_status_backgrond.backgroundColor = UIColor.systemYellow
        
        return cell
    }
    
    // table height
    func tableview(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat{
        return 70;
    }
    
    // number of people cell
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return array.count
    }
    
    // if click cell, then move to chat view
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let view = self.storyboard?.instantiateViewController(withIdentifier: "ChatViewController") as? ChatViewController
        
        view?.destinationUid = self.array[indexPath.row].uid
        
        self.navigationController?.pushViewController(view!, animated: true)
    }
}

class PeopleViewTableCell : UITableViewCell{
    var imageview : UIImageView! = UIImageView()
    var label : UILabel = UILabel()
    var label_status : UILabel! = UILabel()
    var uiview_status_backgrond : UIView = UIView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.addSubview(imageview!)
        self.addSubview(label)
        self.addSubview(uiview_status_backgrond)
        self.addSubview(label_status)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
