//
//  UserModel.swift
//  JawsTalk
//
//  Created by hyosup on 11/24/21.
//

import UIKit

// User Model Database
class UserModel: NSObject {
    @objc var name: String? = ""
    @objc var profileImageUrl: String?
    @objc var uid: String? = ""
    @objc var comment : String? = ""
}
