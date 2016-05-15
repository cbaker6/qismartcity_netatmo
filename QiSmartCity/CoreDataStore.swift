//
//  CoreDataStack.swift
//  QiSmartCity
//
//  Created by Corey Baker on 5/10/16.
//  Copyright © 2016 University of California San Diego. All rights reserved.
//
//  Original code by: Thomas Kluge, https://github.com/thkl/NetatmoSwift

import Foundation
import CoreData

//Currently used to store authentication informaiton. Is setup to store other data
class CoreDataStore {
  
  
  private lazy var applicationDocumentsDirectory: NSURL = {
    let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
    return urls[urls.count-1]
    }()
  
  private lazy var managedObjectModel: NSManagedObjectModel = {
    let modelURL = NSBundle.mainBundle().URLForResource("netatmoclient", withExtension: "momd")!
    return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
  
  private lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
    let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
    let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("netatmoclient.sqlite")
    do {
      try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
    } catch {
      fatalError("Couldn't load database: \(error)")
    }
    
    return coordinator
    }()
  
  lazy var managedObjectContext: NSManagedObjectContext = {
    let coordinator = self.persistentStoreCoordinator
    var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
    managedObjectContext.persistentStoreCoordinator = coordinator
    return managedObjectContext
    }()
  
  func deleteObject(object : NSManagedObject) {
    self.managedObjectContext.deleteObject(object)
    try! self.managedObjectContext.save()
  }
}