//
//  NetadmoModuleProvider.swift
//  netatmoclient
//
//  Created by Corey Baker on 5/10/16.
//  Copyright © 2016 University of California San Diego. All rights reserved.
//
//  Original code by: Thomas Kluge, https://github.com/thkl/NetatmoSwift

import Foundation
import CoreData

//Currently not using anything in this class

struct NetatmoModule: Equatable {
  var id: String
  var moduleName: String
  var type: String //Might need to make an enum for types
  var stationid : String
}

func ==(lhs: NetatmoModule, rhs: NetatmoModule) -> Bool {
  return lhs.id == rhs.id
}


extension NetatmoModule {
  
  init(managedObject : NSManagedObject) {
    self.id = managedObject.valueForKey(kQSModuleId) as! String
    self.moduleName = managedObject.valueForKey(kQSModuleName) as! String
    self.type =  managedObject.valueForKey(kQSModuleType) as! String
    self.stationid =  managedObject.valueForKey(kQSParentStationId) as! String
  }
  
  var measurementTypes : [NetatmoMeasureType] {
    switch self.type {
    case "NAMain":
      return [.Temperature,.CO2,.Humidity,.Pressure,.Noise]
    case "NAModule1","NAModule4":
      return [.Temperature,.Humidity]
    case "NAModule3":
      return [.Rain]
    case "NAModule2":
      return [.WindStrength,.WindAngle]
    default:
      return []
    }
  }

}



class NetadmoModuleProvider {
  
  private let coreDataStore: CoreDataStore!
  
  init(coreDataStore : CoreDataStore?) {
    if (coreDataStore != nil) {
      self.coreDataStore = coreDataStore
    } else {
      self.coreDataStore = CoreDataStore()
    }
  }
  func save() {
    try! coreDataStore.managedObjectContext.save()
  }
  
  func modules()->Array<NetatmoModule> {
    let fetchRequest = NSFetchRequest(entityName: kQSModule)
    fetchRequest.fetchLimit = 1
    let results = try! coreDataStore.managedObjectContext.executeFetchRequest(fetchRequest) as! [NSManagedObject]
    return results.map{NetatmoModule(managedObject: $0 )}
  }

  
  func createModule(id: String, name: String, type : String, stationId : String)->NSManagedObject {
    let newModule = NSManagedObject(entity: coreDataStore.managedObjectContext.persistentStoreCoordinator!.managedObjectModel.entitiesByName[kQSModule]!, insertIntoManagedObjectContext: coreDataStore.managedObjectContext)
    
    newModule.setValue(id, forKey: kQSModuleId)
    newModule.setValue(name, forKey: kQSModuleName)
    newModule.setValue(type, forKey: kQSModuleType)
    newModule.setValue(stationId, forKey: kQSParentStationId)
    try! coreDataStore.managedObjectContext.save()
    return newModule
  }
  
  func getModuleWithId(id: String)->NSManagedObject? {
    let fetchRequest = NSFetchRequest(entityName: kQSModule)
    fetchRequest.predicate = NSPredicate(format: "\(kQSModuleId) == %@", argumentArray: [id])
    fetchRequest.fetchLimit = 1
    let results = try! coreDataStore.managedObjectContext.executeFetchRequest(fetchRequest) as! [NSManagedObject]
    return results.first
  }
  
}