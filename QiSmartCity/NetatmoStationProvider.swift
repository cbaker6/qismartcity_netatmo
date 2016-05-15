//
//  NetatmoStationProvider.swift
//  netatmoclient
//
//  Created by Corey Baker on 5/10/16.
//  Copyright © 2016 University of California San Diego. All rights reserved.
//
//  Original code by: Thomas Kluge, https://github.com/thkl/NetatmoSwift

import Foundation
import CoreData

//Currently not using anything in this class
struct NetatmoStation: Equatable {
    var id: String
    var stationName: String?
    var type: String!
    var location_lat:Double?
    var location_lon:Double?
    var altitude :Double?
    var timeZone: String?
    
    var lastUpgrade : NSDate!
    var firmware : Int!
    var moduleIds = [String]()
    
    var lastStatusStore : NSDate = NSDate()
}

func ==(lhs: NetatmoStation, rhs: NetatmoStation) -> Bool {
    return lhs.id == rhs.id
}


extension NetatmoStation {
    
    init(managedObject : NSManagedObject) {
        self.id = managedObject.valueForKey(kQSStationId) as! String
        self.stationName = managedObject.valueForKey(kQSStationName) as? String
    
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

class NetatmoStationProvider {
    
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
    
    func stations()->Array<NetatmoStation> {
        let fetchRequest = NSFetchRequest(entityName: kQSStation)
        fetchRequest.fetchLimit = 1
        let results = try! coreDataStore.managedObjectContext.executeFetchRequest(fetchRequest) as! [NSManagedObject]
        return results.map{NetatmoStation(managedObject: $0 )}
    }
    
    func createStation(id: String, name: String, type : String, location: [Double], altitude: Double?, timeZone: String?)->NSManagedObject {
        let newStation = NSManagedObject(entity: coreDataStore.managedObjectContext.persistentStoreCoordinator!.managedObjectModel.entitiesByName[kQSStation]!, insertIntoManagedObjectContext: coreDataStore.managedObjectContext)
        
        newStation.setValue(id, forKey: kQSStationId)
        newStation.setValue(name, forKey: kQSStationName)
        newStation.setValue(type, forKey: kQSStationType)
        newStation.setValue(location[0], forKey: kQSStationLocationLat)
        newStation.setValue(location[1], forKey: kQSStationLocationLon)
        
        try! coreDataStore.managedObjectContext.save()
        return newStation
    }
    
    func getStationWithId(id: String)->NSManagedObject? {
        let fetchRequest = NSFetchRequest(entityName: kQSStation)
        fetchRequest.predicate = NSPredicate(format: "\(kQSStationId) == %@", argumentArray: [id])
        fetchRequest.fetchLimit = 1
        let results = try! coreDataStore.managedObjectContext.executeFetchRequest(fetchRequest) as! [NSManagedObject]
        return results.first
    }
    
}