//
//  ViewController.swift
//  GitHubGists
//
//  Created by Eugene Ar on 23/02/2019.
//  Copyright © 2019 Kin. All rights reserved.
//

import UIKit
import Foundation

class FeedViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITableViewDataSourcePrefetching, FeedDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Upload initial data
        DispatchQueue(label: "Initial updateFeed").async {
            Feed.updateFeed(delegate: self)
        }
        self.feedTableView.addSubview(self.refreshControl)
    }
    
    // MARK - TableView
    
    @IBOutlet weak var feedTableView: UITableView!
    
    var isLocked = false
    
    var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:
            #selector(FeedViewController.handleRefresh(_:)),
                                 for: .valueChanged)
        return refreshControl
    }()
    
    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        // Refreshing at Pull-to-refresh action
        DispatchQueue(label: "updateFeed").async {
            Feed.updateFeed(delegate: self)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Feed.feed.count
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
        if indexPaths.map({$0.row}).contains(Feed.feed.count - 1), !self.isLocked {
            self.isLocked = true
            DispatchQueue(label: "loadMore").async {
                Feed.loadMore(delegate: self)
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
        return Feed.feed[index]
    }
    
    // MARK - things to delegate things to GistVC
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let gistVC = segue.destination as? GistViewController {
            gistVC.gist = (sender as! Gist)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.performSegue(withIdentifier: "ShowGist", sender: self.getGistFromFeed(at: indexPath.row))
    }
    
}

