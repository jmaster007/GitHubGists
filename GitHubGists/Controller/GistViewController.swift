//
//  GistViewController.swift
//  GitHubGists
//
//  Created by Eugene Ar on 23/02/2019.
//  Copyright © 2019 Kin. All rights reserved.
//

import UIKit

class GistViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, FeedDelegate {
    
    @IBOutlet weak var infoTableView: UITableView!

    weak var gist: Gist!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DispatchQueue(label: "loadGistContent").async {
            self.gist.loadGistContent(delegate: self)
        }
    }
    
    // MARK - table View
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            guard let filesCount = gist.files?.count else { return 0 }
            return filesCount
        case 2:
            guard let commitsCount = gist.commits?.count else { return 0 }
            return commitsCount
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch (indexPath.section) {
            case 0:
                if let cell: UserTableViewCell = tableView.dequeueReusableCell(withIdentifier: "UserCell") as? UserTableViewCell {
                    cell.userNameLabel.text = self.gist.owner.login
                    cell.userAvatarImageView.image = self.gist.owner.avatarImage
                    cell.descriptionLabel.text = self.gist.gistDescription
                    return cell
                }
                return UserTableViewCell()
            case 1:
                if let cell: FileTableViewCell = tableView.dequeueReusableCell(withIdentifier: "FileCell") as? FileTableViewCell {
                    cell.fileContentTextView.text = self.gist.files?[indexPath.row].content
                    cell.fileNameLabel.text = self.gist.files?[indexPath.row].filename
                    return cell
                }
                return FileTableViewCell()
            case 2:
                if let cell: CommitTableViewCell = tableView.dequeueReusableCell(withIdentifier: "CommitsCell") as? CommitTableViewCell{
                    cell.commitLabel.text = self.gist.commits?[indexPath.row].id
                    cell.changesLabel.attributedText = self.gist.commits?[indexPath.row].changes
                    return cell
                }
                return CommitTableViewCell()
            default:
                return UITableViewCell()
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    // MARK - gist delegate
    
    func finishUpdating(updateTableView: Bool) {
        self.infoTableView.reloadData()
    }
}
