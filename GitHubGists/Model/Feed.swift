//
//  Feed.swift
//  GitHubGists
//
//  Created by Eugene Ar on 26/02/2019.
//  Copyright © 2019 Kin. All rights reserved.
//

import Foundation
import Alamofire

class Feed {
    // whole feed here
    static var feed = [Gist]()
    // current feed page
    static var page: Int = 1
    
    // Load /more for add at the bootm of TableView
    static func loadMore(delegate: FeedDelegate) {
        let request = "https://api.github.com/gists/public?page=\(self.page)"
        print("Requesting to load more")
        self.loadFeed(request: request, delegate: delegate, isStickDown: true)
    }
    
    // Remove all and update /feed
    static func updateFeed(delegate: FeedDelegate) {
        self.page = 1
        print("Requesting to update feed")
        let request = "https://api.github.com/gists/public"
        loadFeed(request: request, delegate: delegate, isStickDown: false)
    }
    
    static private func loadFeed(request: String, delegate: FeedDelegate, isStickDown: Bool) {
        // Trying to request a data
        print("Requesting a data: \(request)")
        if !checkInternetConnection() { return }
        Alamofire.request(request).responseJSON { (response) -> Void in
            print("Current page: \(self.page)")
            
            guard response.result.isSuccess else {
                print("Error occured while fetching gists: \(response.result.error!)")
                return
            }
            
            //Checking if response have right format
            guard let loadedData = response.result.value as? [[String: AnyObject]] else {
                print("Malformed data received from gists service: \(response.result.value!)")
                return
            }
            
            var feed = [Gist]()
            
            // Parcing data from JSON
            for var gistDict in loadedData {
                guard let owner = gistDict["owner"] as? [String: AnyObject] else {
                    print("Malford data while trying get owner info: \(gistDict)")
                    return
                }
                
                feed.append(Gist(
                    gistID: gistDict["id"] as! String,
                    gistURL: gistDict["url"] as! String,
                    gistDescription: (gistDict["description"] is NSNull ? "" : gistDict["description"] as! String),
                    owner: Gist.Owner(
                        login: owner["login"] as? String,
                        id: owner["id"] as? Int,
                        avatarURL: owner["avatar_url"] as? String,
                        avatarImage: nil
                )))
            }
            
            // Checking if loaded data isn't the same we have
            if self.feed.first?.gistID == feed.first?.gistID {
                print("Nothing new loaded...")
                delegate.finishUpdating(updateTableView: false)
                return
            }
            
            // If downloaded different pack of gists...
            print("Have new items...")
            
            // startsAt is for images to load only new pack
            var startsAt: Int
            
            // /more or /feed
            if isStickDown {
                var newFeed = [Gist]()
                newFeed.append(contentsOf: self.feed)
                newFeed.append(contentsOf: feed)
                startsAt = self.feed.count - 1
                self.feed = newFeed
            } else {
                self.feed = feed
                startsAt = 0
            }
            delegate.finishUpdating(updateTableView: true)
            
            // downloading images for new pack
            print("Downloading images...")
            DispatchQueue(label: "loadImage(s)").async{
                for index in startsAt...(self.feed.count - 1) {
                    self.loadImage(forRow: index, delegate: delegate)
                }
            }
            self.page += 1
        }
    }
    
    static func loadImage(forRow row: Int, delegate: FeedDelegate) {
        if self.feed[row].owner.avatarImage == nil, let url = self.feed[row].owner.avatarURL {
            self.feed[row].owner.avatarImage = UIImage()
            print("Will load image using url \(url)")
            Alamofire.request(url).responseData { (response) in
                if let imageData = response.result.value, let image = UIImage(data: imageData) {
                    
                    self.feed[row].owner.avatarImage = image
                    delegate.refreshCell(row)
                } else {
                    self.feed[row].owner.avatarImage = nil
                    
                }
            }
        }
    }
    
    static func checkInternetConnection() -> Bool {
        if !NetworkReachabilityManager()!.isReachable {
            print("No internet connection while fetching data")
            return false
        }
        return true
    }
    
}
