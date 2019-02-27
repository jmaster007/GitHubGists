//
//  FeedDelegate.swift
//  GitHubGists
//
//  Created by Eugene Ar on 27/02/2019.
//  Copyright © 2019 Kin. All rights reserved.
//

protocol FeedDelegate {
    func finishUpdating(updateTableView: Bool)
    func refreshCell(_ row: Int)
}

extension FeedDelegate {
    // making it kinda optional
    func refreshCell(_ row: Int) {}
}
