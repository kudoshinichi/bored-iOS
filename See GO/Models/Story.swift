//
//  Story.swift
//
//  Created by Hongyi Shen on 7/6/18.
//  Copyright © 2018 Razeware LLC. All rights reserved.
//

import Foundation
import Firebase

struct Story {
    //let ref: DatabaseReference?
    let caption: String
    var featured: Bool
    var flagged: Bool
    let location: String
    let uri: String
    let views : Int
    let votes : Int
    let keywords : String
    
    init(caption: String, featured: Bool, flagged: Bool, location: String, uri: String, views: Int, votes: Int, keywords: String) {
        //self.ref = nil
        self.caption = caption
        self.featured = featured
        self.flagged = flagged
        self.location = location
        self.uri = uri
        self.views = views
        self.votes = votes
        self.keywords = keywords
    }
    
    /*init?(snapshot: DataSnapshot) {
        guard
            let value = snapshot.value as? [String: AnyObject],
            let caption = value["Caption"] as? String,
            let featured = value["Featured"] as? Bool,
            let flagged = value["Flagged"] as? Bool,
            let location = value["Location"] as? String,
            let uri = value["URI"] as? String,
            let views = value["Views"] as? Int,
            let votes = value["Votes"] as? Int,
            let keywords = value["Keywords"] as? String
            else {
                return nil
        }
        
        self.ref = snapshot.ref
        self.caption = caption
        self.featured = featured
        self.flagged = flagged
        self.location = location
        self.uri = uri
        self.views = views
        self.votes = votes
        self.keywords = keywords
    }*/
 
    
    func toAnyObject() -> Any {
        return [
            "Caption": caption,
            "Featured": featured,
            "Flagged": flagged,
            "Location": location,
            "URI": uri,
            "Views": views,
            "Votes": votes,
            "Keywords": keywords,
        ]
    }
}
