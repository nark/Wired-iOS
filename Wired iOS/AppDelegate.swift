//
//  AppDelegate.swift
//  Wired iOS
//
//  Created by Rafael Warnault on 31/03/2020.
//  Copyright © 2020 Read-Write. All rights reserved.
//

import UIKit
import CoreData
import WiredSwift_iOS
import Reachability

extension UserDefaults {
    func image(forKey key: String) -> UIImage? {
        var image: UIImage?
        if let imageData = data(forKey: key) {
            image = try! NSKeyedUnarchiver.unarchivedObject(ofClass: UIImage.self, from: imageData)
        }
        return image
    }
    func set(image: UIImage?, forKey key: String) {
        var imageData: NSData?
        if let image = image {
            imageData = try! NSKeyedArchiver.archivedData(withRootObject: image, requiringSecureCoding: false) as NSData
        }
        set(imageData, forKey: key)
    }
}



@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    public static let shared:AppDelegate = UIApplication.shared.delegate as! AppDelegate

    var window:UIWindow?

    override init() {
        super.init()
        
        UIButton.appearance().tintColor = UIColor.systemGreen
        UIBarButtonItem.appearance().tintColor = UIColor.systemGreen
        
        // Default preferences
        UserDefaults.standard.register(defaults: [
            "WSUserNick": "WiredSwift",
            "WSUserStatus": "Share The Wealth"
        ])
        
        if UserDefaults.standard.image(forKey: "WSUserIcon") == nil {
            if let image = UIImage(named: "DefaultIcon") {
                UserDefaults.standard.set(image: image, forKey: "WSUserIcon")
            }
        }
        
        UserDefaults.standard.synchronize()
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        Logger.setMaxLevel(.INFO)
        
        let splitViewController = window!.rootViewController as! UISplitViewController
        splitViewController.preferredDisplayMode = UISplitViewController.DisplayMode.primaryOverlay

        return true
    }

    
    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "Wired3")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
