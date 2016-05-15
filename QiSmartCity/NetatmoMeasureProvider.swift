//
//  NetatmoMeasureProvider.swift
//  netatmoclient
//
//  Created by Corey Baker on 5/10/16.
//  Copyright © 2016 University of California San Diego. All rights reserved.
//
//  Original code by: Thomas Kluge, https://github.com/thkl/NetatmoSwift

import Foundation
import CoreData

//Currently not using anything in this class

struct NetatmoMeasure: Equatable {
    var timestamp : NSDate
    var type: Int
    var value : Double
    /*
     var unit : String {
     return (NetatmoMeasureUnit(rawValue: self.type)?.unit)!
     }*/
}

func ==(lhs: NetatmoMeasure, rhs: NetatmoMeasure) -> Bool {
    return (lhs.timestamp.timeIntervalSince1970 == rhs.timestamp.timeIntervalSince1970) && (lhs.type == rhs.type)
}


extension NetatmoMeasure {
    
    init(managedObject : NSManagedObject) {
        self.timestamp = managedObject.valueForKey(kQSTimeStamp) as! NSDate
        self.type =  managedObject.valueForKey(kQSType) as! Int
        self.value =  managedObject.valueForKey(kQSValue) as! Double
    }
    
}



class NetatmoMeasureProvider {
    
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
    
    func createMeasure(timeStamp : NSDate , type : Int, value: AnyObject? , forStation : NetatmoStation? , forModule : NetatmoModule? )->NSManagedObject? {
        guard let mvalue = value as? Double else {
            return nil
        }
        
        let test = self.getMeasureWithTimeStamp(timeStamp, andType: type)
        
        if (test != nil){
            return test!
        }
        
        let newMeasure = NSManagedObject(entity: coreDataStore.managedObjectContext.persistentStoreCoordinator!.managedObjectModel.entitiesByName[kQSMeasurement]!,
                                         insertIntoManagedObjectContext: coreDataStore.managedObjectContext)
        
        newMeasure.setValue(timeStamp, forKey: kQSTimeStamp)
        newMeasure.setValue(type, forKey: kQSType)
        newMeasure.setValue(mvalue , forKey: kQSValue)
        
        // Fetch Station or Module
        
        if (forStation != nil) {
            newMeasure.setValue(forStation!.id , forKey: kQSStationId)
        }
        
        if (forModule != nil) {
            newMeasure.setValue(forModule!.id , forKey: kQSModuleId)
        }
        
        
        try! coreDataStore.managedObjectContext.save()
        return newMeasure
    }
    
    func insertMeasuresWithJsonData(json: NSDictionary , forStation : NetatmoStation? , forModule : NetatmoModule?) {
        
        if let body = json["body"] as? Array<NSDictionary> {
            for dat : NSDictionary in body {
                
                let beg_time = dat["beg_time"]?.doubleValue
                var step : Double = 0
                
                let step_time = dat["step_time"]?.doubleValue
                let values = dat[kQSValue] as! Array<NSArray>
                
                for value : NSArray in values {
                    
                    let dt = NSDate(timeIntervalSince1970: beg_time! + step)
                    
                    var measurelist = forStation!.measurementTypes
                    
                    if (forModule != nil) {
                        measurelist = forModule!.measurementTypes
                    }
                    
                    var i = 0
                    
                    for measureType: NetatmoMeasureType in measurelist {
                        self.createMeasure(dt, type: measureType.hashValue , value: value[i], forStation: forStation, forModule: forModule)
                        i += 1
                    }
                    
                    if (step_time != nil ) { step = step + step_time! }
                }
            }
        }
        
    }
    
    func getLastMeasureDate(forStation : NetatmoStation? , forModule : NetatmoModule?)->NSDate {
        let fetchRequest = NSFetchRequest(entityName: kQSMeasurement)
        
        if (forModule != nil) {
            fetchRequest.predicate = NSPredicate(format: "\(kQSModuleId) == %@", argumentArray: [forModule!.id])
        } else {
            fetchRequest.predicate = NSPredicate(format: "\(kQSStationId) == %@ && moduleid = NULL", argumentArray: [forStation!.id])
        }
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: kQSTimeStamp, ascending: false)]
        fetchRequest.fetchLimit = 1
        let results = try! coreDataStore.managedObjectContext.executeFetchRequest(fetchRequest) as! [NSManagedObject]
        
        if ( results.first != nil ) {
            return results.first?.valueForKey(kQSTimeStamp) as! NSDate
        } else {
            return NSDate().dateByAddingTimeInterval(-3600)
        }
    }
    
    private func getMeasureWithTimeStamp(date : NSDate , andType : Int)->NSManagedObject? {
        let fetchRequest = NSFetchRequest(entityName: kQSMeasurement)
        fetchRequest.predicate = NSPredicate(format: "\(kQSTimeStamp) == %@ && type == %@", argumentArray: [date,andType])
        
        fetchRequest.fetchLimit = 1
        let results = try! coreDataStore.managedObjectContext.executeFetchRequest(fetchRequest) as! [NSManagedObject]
        return results.first
    }
    
    func getMeasurementfor(station : NetatmoStation, module : NetatmoModule?,
                           withTypes:[NetatmoMeasureType], betweenStartDate: NSDate, andEndDate: NSDate)->Array<NetatmoMeasure> {
        return self.getMeasurementfor(station, module: module, withTypes: withTypes, betweenStartDate: betweenStartDate, andEndDate: andEndDate,ascending : false)
    }
    
    func getMeasurementfor(station : NetatmoStation, module : NetatmoModule?,
                           withTypes:[NetatmoMeasureType], betweenStartDate: NSDate, andEndDate: NSDate, ascending: Bool)->Array<NetatmoMeasure> {
        
        let fetchRequest = NSFetchRequest(entityName: kQSMeasurement)
        var resultArray = Array<NetatmoMeasure>()
        let types = withTypes.map({$0.hashValue})
        
        if (module == nil) {
            fetchRequest.predicate = NSPredicate(format: "\(kQSStationId) == %@ && moduleid == NULL && timestamp >= %@ && timestamp <= %@ && type IN %@", argumentArray: [station.id, betweenStartDate,andEndDate,types])
        } else {
            let moduleid = (module != nil) ? module!.id : ""
            fetchRequest.predicate = NSPredicate(format: "\(kQSStationId) == %@ && moduleid == %@ && timestamp >= %@ && timestamp <= %@ && type IN %@", argumentArray: [station.id,moduleid, betweenStartDate,andEndDate,types])
        }
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: kQSTimeStamp, ascending: ascending)]
        
        let results = try! coreDataStore.managedObjectContext.executeFetchRequest(fetchRequest) as! [NSManagedObject]
        for obj: NSManagedObject in results {
            resultArray.append(NetatmoMeasure(managedObject: obj))
        }
        return resultArray
    }
}