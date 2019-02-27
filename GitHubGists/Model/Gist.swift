//
//  Gist.swift
//  GitHubGists
//
//  Created by Eugene Ar on 23/02/2019.
//  Copyright © 2019 Kin. All rights reserved.
//

import Foundation
import Alamofire

class Gist {
    var gistID: String
    var gistURL: String
    var gistDescription: String
    var owner: Owner
    var delegate: FeedDelegate?
    var content: String?
    var files: [File]?
    var commits: [Commit]?
    
    struct Owner {
        let login: String?
        let id: Int?
        let avatarURL: String?
        var avatarImage: UIImage?
    }
    
    struct File {
        let filename: String?
        let content: String?
    }
    
    struct Commit {
        let id: String?
        let changes: NSAttributedString?
    }
    
    init(gistID: String, gistURL: String, gistDescription: String, owner: Owner) {
        self.gistID = gistID
        self.gistURL = gistURL
        self.gistDescription = gistDescription
        self.owner = owner
    }
    
    // Loading lacking info, like files, its names and requesting commits
    func loadGistContent(delegate: FeedDelegate) {
        print("Getting info for gistID: \(self.gistID)")
        if !Feed.checkInternetConnection() { return }
        
        Alamofire.request("https://api.github.com/gists/\(self.gistID)").responseJSON { (response) in
            guard let json = response.result.value as? [String: Any] else {
                print("Malformed data received at fetching gist info: \(String(describing: response.result.value))")
                return
            }
            
            // Launching proccess of loading commints while parcing files data
            guard let commitsURL = json["commits_url"] as? String else {
                print("Cannot get commits_url from json")
                return
            }
            DispatchQueue(label: "loadCommits").async {
                self.loadCommits(url: commitsURL, delegate: delegate)
            }
            
            // Parcing files data
            
            guard let files = json["files"] as? [String: [String: Any]] else {
                print("Malformed data on trying get gist files: \(json)")
                return
            }
        
            var tempFiles = [File]()
            for file in files {
                let fileName = file.value["filename"] as? String
                let content = file.value["content"] as? String
                tempFiles.append(File(filename: fileName, content: content))
            }
            self.files = tempFiles
            
            print("Getting info for gistID: \(self.gistID) was successful")
            delegate.finishUpdating(updateTableView: true)
        }
    }
    
    // Loading commits
    func loadCommits(url: String, delegate: FeedDelegate) {
        print("Getting commits for gistID: \(self.gistID)")
        if !Feed.checkInternetConnection() { return }
        
        Alamofire.request(url).responseJSON { (response) in
            guard let commits = response.result.value as? [[String: Any]] else {
                print("Malformed data received at fetching commits: \(response.result.value!))")
                return
            }
            
            // Preparing array of commits
            var tempCommits = [Commit]()
            for commit in commits {
                guard let status = commit["change_status"] as? [String: Any] else {
                    print("Malformed data received at unpacking change_status: \(commit))")
                    return
                }
                
                // Configuring changes as attributed string to show deletions/addition using colors
                let additions = ((status["additions"] as? Int)?.description)!
                let deletions = ((status["deletions"] as? Int)?.description)!
                let changes = self.makeAttributedStringForChanges(additions: additions, deletions: deletions)

                tempCommits.append(Commit(id: commit["version"] as? String, changes: changes))
            }
            self.commits = tempCommits
            print("Getting commits for gistID: \(self.gistID) was successful")
            delegate.finishUpdating(updateTableView: true)
        }
    }
    
    // MARK - stuff
    
    // Making an attributed string to show deletions/addition on different colors
    func makeAttributedStringForChanges(additions: String, deletions: String) -> NSAttributedString? {
        let html = """
        <html>
        <body>
        <span style="color: green;font-family: Helvetica Neue">\(additions)</span>
        <span style="color: black;font-family: Helvetica Neue"> / </span>
        <span style="color: red;font-family: Helvetica Neue">\(deletions)</span>
        </body>
        </html>
        """
        let data = Data(html.utf8)
        if let attributedString = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil) {
            return attributedString
        }
        return nil
    }
}
