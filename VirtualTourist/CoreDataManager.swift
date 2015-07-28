//
//  CoreDataManager.swift
//
//  Created by Oleksandr Iaroshenko on 06.06.15.
//  Copyright (c) 2015 Oleksandr Iaroshenko. All rights reserved.
//

import Foundation
import CoreData

class CoreDataManager {

    // MARK: - Magic values
    private struct Defaults {
        static let Model = "Model"
        static let ModelExtension = "momd"

        static let SQLBase = "VirtualTourist.sqlite"
    }

    // MARK: - Singleton pattern

    static let sharedInstance = CoreDataManager()

    // MARK: - Core Data stack

    var context: NSManagedObjectContext?

    private init() {
        let modelURL = NSBundle.mainBundle().URLForResource(Defaults.Model, withExtension: Defaults.ModelExtension)!
        let managedObjectModel = NSManagedObjectModel(contentsOfURL: modelURL)!
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)

        let documentsDirURL = NSFileManager.defaultManager().URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask).first as! NSURL
        let sqlBaseURL = documentsDirURL.URLByAppendingPathComponent(Defaults.SQLBase)

        if let storeAdded = coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: sqlBaseURL, options: nil, error: NSErrorPointer()) {

            context = NSManagedObjectContext()
            context!.persistentStoreCoordinator = coordinator
        }
    }

    // MARK: - Core Data saving support
    
    func saveContext () {
        if let context = context {
            if context.hasChanges && !context.save(NSErrorPointer()) {
                println("Log: Changes were not saved to disk.")
            }
        }
    }
}