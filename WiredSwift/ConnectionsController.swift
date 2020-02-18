//
//  ConnectionsController.swift
//  WiredSwift
//
//  Created by Rafael Warnault on 18/02/2020.
//  Copyright © 2020 Read-Write. All rights reserved.
//

import Cocoa

extension Notification.Name {
    static let didAddNewConnection = Notification.Name("didAddNewConnection")
    static let didRemoveConnection = Notification.Name("didRemoveConnection")
}

class ConnectionsController {
    public static let shared = ConnectionsController()
    
    var connections:[Connection] = []
    
    private init() {

    }
    

    
    
    
    // MARK: - Connections
    
    public func addConnection(_ connection: Connection) {
        if connections.index(of: connection) == nil {
            connections.append(connection)
            
            NotificationCenter.default.post(name: .didAddNewConnection, object: connection, userInfo: nil)
        }
    }
    
    public func addConnection(withBookmark bookmark: Bookmark) {
//        let connection = Connection(withSpec: spec, delegate: self)
//        connection.nick = bookmark.nick ?? UserDefaults.standard.string(forKey: "WSUserNick")
//        connection.status = bookmark.status ?? UserDefaults.standard.string(forKey: "WSUserStatus")
    }
    
    
    public func removeConnection(_ connection: Connection) {
        if let i = connections.index(of: connection) {
            connections.remove(at: i)
            
            NotificationCenter.default.post(name: .didRemoveConnection, object: connection, userInfo: nil)
        }
    }
    
    
    
    // MARK: - Bookmarks
    
    public func bookmarks() -> [Bookmark] {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Bookmark")
        
        guard let appDelegate = NSApp.delegate as? AppDelegate else {
            return []
        }
        
        let context = appDelegate.persistentContainer.viewContext
        
        do {
            let results = try context.fetch(fetchRequest)
            let bookmarks = results as! [Bookmark]
            
            return bookmarks
            
        } catch let error as NSError {
            print("Could not fetch \(error)")
        }
        
        return []
    }
    
    
    public func removeBookmark(_ bookmark:Bookmark) {
        if let appDelegate = NSApp.delegate as? AppDelegate  {
            let context = appDelegate.persistentContainer.viewContext
            
            context.delete(bookmark)
        }
    }
}