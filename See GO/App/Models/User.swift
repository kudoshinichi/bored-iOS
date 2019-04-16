//
//  User.swift
//  See GO
//
//  Created by Bhargav Singapuri on 16/4/19.
//

import Foundation

struct userItem {
    let admin: Bool
    let username: String
    let uid: String
    let flagothers: Int
    
    func toAnyObject() -> Any {
        return [
            "Admin": admin,
            "Username": username,
            "UID": uid,
            "FlagOthers": flagothers,
        ]
    }
}
