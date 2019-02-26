//
//  Gist.swift
//  GitHubGists
//
//  Created by Eugene Ar on 23/02/2019.
//  Copyright © 2019 Kin. All rights reserved.
//

import Foundation
import Alamofire

// MARK - делаем класс

protocol GistDelegate {
    func finishUpdating(updateTableView: Bool)
    func refreshCell(_ row: Int)
}

class Gist {
    var gistID: String?
    var gistURL: String?
    var gistDescription: String?
    var owner: Owner
    var delegate: GistDelegate?
    
    struct Owner {
        let login: String?
        let id: Int?
        let avatarURL: String?
        var avatarImage: UIImage?
    }
    
    init(gistID: String, gistURL: String, gistDescription: String, owner: Owner) {
        self.gistID = gistID
        self.gistURL = gistURL
        self.gistDescription = gistDescription
        self.owner = owner
    }
    
    static var feed: [Gist] = []
    static var page: Int = 1
    
    // Load /more for add at the bootm of TableView
    static func loadMore(delegate: GistDelegate) {
        let request = "https://api.github.com/gists/public?page=\(self.page)"
        print("Requesting to load more")
        self.requestData(request: request, delegate: delegate, isStickDown: true)
    }
    
    // Remove all and update /feed
    static func updateFeed(delegate: GistDelegate) {
        self.page = 1
        print("Requesting to update feed")
        let request = "https://api.github.com/gists/public"
        requestData(request: request, delegate: delegate, isStickDown: false)
        
    }
    
    static private func requestData(request: String, delegate: GistDelegate, isStickDown: Bool) {
        if !NetworkReachabilityManager()!.isReachable {
            print("No internet connection while fetching data")
            return
        }
        // Trying to request a data
        print("Requesting a data: \(request)")
        Alamofire.request(request).responseJSON { (response) -> Void in
            print("Current page: \(self.page)")
            
            guard response.result.isSuccess else {
                print("Error occured while fetching gists: \(String(describing: response.result.error))")
                return
            }
            
            //Checking if response have right format
            guard let loadedData = response.result.value as? [[String: AnyObject]] else {
                print("Malformed data received from gists service: \(String(describing: response.result.value))")
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
            if Gist.feed.first?.gistID == feed.first?.gistID {
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
            DispatchQueue(label: "downloading images").async{
                for index in startsAt...(self.feed.count - 1) {
                    self.loadImage(forRow: index, delegate: delegate)
                }
            }
            self.page += 1
        }
    }
    
    static func loadImage(forRow row: Int, delegate: GistDelegate) {
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
}
