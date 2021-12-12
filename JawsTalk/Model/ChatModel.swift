//
//  ChatModel.swift
//  JawsTalk
//
//  Created by hyosup on 11/25/21.
//

//import UIKit
import ObjectMapper

// Chat Model Database
class ChatModel: Mappable {
    
    public var users: Dictionary<String, Bool> = [:] // chat room users
    public var comments : Dictionary<String, Comment> = [:] // chat messages
    
    required init?(map: Map) {
    }
    func mapping(map: Map) {
        users <- map["users"]
        comments <- map["comments"]
    }
    
    public class Comment : Mappable {
        public var uid : String?
        public var message : String?
        public var timestamp : Int?
        public var readUsers : Dictionary<String,Bool> = [:]
        
        public required init?(map: Map) {
        }
        public func mapping(map: Map) {
            uid <- map["uid"]
            message <- map["message"]
            timestamp <- map["timestamp"]
            readUsers <- map["readUsers"]
        }
        
    }
}
