//
//  ViewController.swift
//  GitHubGists
//
//  Created by Eugene Ar on 23/02/2019.
//  Copyright © 2019 Kin. All rights reserved.
//

import UIKit
import Foundation

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITableViewDataSourcePrefetching, GistDelegate {

    var isLocked = false
    var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:
            #selector(ViewController.handleRefresh(_:)),
                                 for: .valueChanged)
        return refreshControl
    }()
    
    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        Gist.updateFeed(delegate: self)
    }
    
    @IBOutlet weak var feedTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Upload initial data
        DispatchQueue(label: "Initial feed update").async {
            Gist.updateFeed(delegate: self)
        }
        self.feedTableView.addSubview(self.refreshControl)
    }
    
    // MARK - Table view
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Gist.feed.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell: GistTableViewCell = tableView.dequeueReusableCell(withIdentifier: "GistCell") as? GistTableViewCell {
            return cell
        }
        return GistTableViewCell()
    }
    
    func refreshCell(_ row: Int) {
        // refreshing only visible rows
        if let visibleCellsIndeces = self.feedTableView.indexPathsForVisibleRows, visibleCellsIndeces.map({$0.row}).contains(row) {
                self.feedTableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .automatic)
        }
    }
    
    func finishUpdating(updateTableView: Bool) {
        if updateTableView {
            self.feedTableView.reloadData()
        }
        if self.refreshControl.isRefreshing {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.refreshControl.endRefreshing()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        // Check if there is a last row between prefetched
        if indexPaths.map({$0.row}).contains(Gist.feed.count - 1), !self.isLocked {
            self.isLocked = true
            print("is locked: \(self.isLocked)")
            DispatchQueue(label: "Load more").async {
                Gist.loadMore(delegate: self)
                sleep(2)
                self.isLocked = false
            }
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let gist = self.getGistFromFeed(at: indexPath.row)
        (cell as! GistTableViewCell).nameLabel.text = gist.owner.login
        (cell as! GistTableViewCell).gistDescriptionLabel.text = gist.gistDescription
        (cell as! GistTableViewCell).avatarImageView.image = gist.owner.avatarImage
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120.0
    }
    
    // MARK - stuff
    
    func getGistFromFeed(at index: Int) -> Gist {
        return Gist.feed[index]
    }
}

