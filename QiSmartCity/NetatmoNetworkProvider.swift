//
//  NetworkStack.swift
//  netatmoclient
//
//  Created by Corey Baker on 5/10/16.
//  Copyright © 2016 University of California San Diego. All rights reserved.
//
//  Original code by: Thomas Kluge, https://github.com/thkl/NetatmoSwift

import Foundation
import CoreData

class NetatmoNetworkProvider  {
    
    private let stationprovider = NetatmoStationProvider(coreDataStore: nil)
    private let moduleprovider = NetadmoModuleProvider(coreDataStore: nil)
    private let networkStack = NetworkStack()
    private let loginProvider = NetatmoLoginProvider()
    
    init() {
        //assert(kQSCNetatmoClientId != nil,"Please provide your ClientID from Netatmo Dev Center (NetatmoCientConstants.swift)")
        //assert(kQSCNetatmoSecret != nil,"Please provide your ClientSecret from Netatmo Dev Center (NetatmoCientConstants.swift)")
    }
    
    func loginWithUser(username : String, password : String, completionHandler: (token : String?, error : NSError?)->Void) {
        loginProvider.authenticate(username, password: password) { (newToken, error) -> Void in
            completionHandler(token: newToken, error: error)
        }
    }
    
    //Currently not using this method
    func getStationData(completionHandler:(stations :Array<NSManagedObject>? , error : NSError?)->Void) {
        
        loginProvider.getAuthenticationToken { (token) -> Void in
            if token == nil {
                completionHandler(stations: nil, error: NSError(domain: "airpolution.calit2.net.authenticationtoken_notfound", code: 500, userInfo: nil))
                return
            }
            
            var stations = Array<NSManagedObject>()
            
            let postData = ["access_token":token!]
            let url = NSURL(string: kQSNetatmoGetDeviceListURL)
            
            self.networkStack.callUrl(url!, method: .POST, arguments: postData) { (resultData, error) -> Void in
                
                do {
                    if let parsed = try NSJSONSerialization.JSONObjectWithData(resultData!, options: NSJSONReadingOptions.AllowFragments) as? NSDictionary {
                        if let body = parsed["body"] as? NSDictionary {
                            
                            if let devices = body["devices"] as? Array<NSDictionary> {
                                for device : NSDictionary in devices {
                                    
                                    let d_id = device["_id"] as! String
                                    let d_name = device["station_name"] as! String
                                    let d_type = device["type"] as! String
                                    let d_plcace = device["position"] as! [Double] //This will not work, need to fix
                                    
                                    if let station = self.stationprovider.getStationWithId(d_id) {
                                        stations.append(station)
                                    } else {
                                        let station = self.stationprovider.createStation(d_id, name: d_name, type: d_type, location: d_plcace, altitude: nil, timeZone: nil)
                                        stations.append(station)
                                    }
                                    
                                }
                            }
                            
                            if let modules = body["modules"] as? Array<NSDictionary> {
                                for module : NSDictionary in modules {
                                    let m_mainID = module["main_device"] as! String
                                    let m_id = module["_id"] as! String
                                    let m_name = module["module_name"] as! String
                                    let m_type = module["type"] as! String
                                    
                                    if (self.moduleprovider.getModuleWithId(m_id) == nil) {
                                        self.moduleprovider.createModule(m_id, name: m_name, type: m_type, stationId: m_mainID)
                                    }
                                }
                            }
                        }
                        completionHandler(stations: stations ,error: error)
                    }
                } catch let error as NSError {
                    print("A JSON parsing error occurred, here are the details:\n \(error)")
                    completionHandler(stations: nil , error: error)
                }
            }
        }
    }
    
    
    // This is the main method to get devices in the netatmo
    // Accessing public netatmo device information can be found here: https://dev.netatmo.com/doc/methods/getpublicdata
    //
    func getPublicData(locationArea: LatitudeLongitude, completionHandler:(stations :[String:AnyObject]?, error : NSError?)->Void) {
        
        loginProvider.getAuthenticationToken { (token) -> Void in
            if token == nil {
                completionHandler(stations: nil, error: NSError(domain: "airpolution.calit2.net.authenticationtoken_notfound", code: 500, userInfo: nil))
                return
            }
            
            //Stores all of the found stations
            var stations = [String:AnyObject]()
            
            //Used for REST .POST
            let postData : [String:AnyObject] = [
                "access_token": token!,
                "lat_ne": locationArea.lat_ne,
                "lon_ne": locationArea.lon_ne,
                "lat_sw": locationArea.lat_sw,
                "lon_sw": locationArea.lon_sw
                //"filter": "true",
                //"temperature": "temperature"
            ]
            
            //Preparing string for to make a REST Post
            let url = NSURL(string: kQSNetatmoGetPublicDataURL)
            
            self.networkStack.callUrl(url!, method: .POST, arguments: postData) { (resultData, error) -> Void in
                
                do {
                    if let parsed = try NSJSONSerialization.JSONObjectWithData(resultData!, options: NSJSONReadingOptions.AllowFragments) as? [String:AnyObject] {
                        
                        if let stations_from_web = parsed["body"] as? [[String:AnyObject]] {
                            
                            for station_from_web : [String:AnyObject] in stations_from_web {
                                
                                let s_id = station_from_web["_id"] as! String
                                let s_place = station_from_web["place"] as! [String:AnyObject]
                                let s_location = s_place["location"] as! [Double]
                                let s_altitude = s_place["altitude"] as! Double
                                let s_timezone = s_place["timezone"] as! String
                                
                                //CoreData: If you need to store the station
                                //This works, but not needed for the current implementation
                                /*if let station = self.stationprovider.getStationWithId(s_id) {
                                    stations.append(station)
                                } else {
                                    let station = self.stationprovider.createStation(s_id, name: "", type: "", location: s_location, altitude: s_altitude, timeZone: s_timezone)
                                    stations.append(station)
                                }*/
                                
                                var module_dict = [String:AnyObject]()
                                
                                //Parse modules
                                let modules = station_from_web["measures"] as! [String:[String:AnyObject]]
                                
                                //Get all of the sensors plugged into this devices
                                for (key,data) in modules{
                                    
                                    //Only handled "types", need something else to handle rest
                                    if let m_type = data["type"] as? [String]{
                                        let m_temp = data["res"] as! [String: [AnyObject]]
                                        var m_results = [Double]()
                                        //In cases seen, this only iterates once
                                        for(_, f_data) in m_temp{
                                            //m_id = f_id
                                            m_results = f_data as! [Double]
                                        }
                                        
                                        var resultsDict = [String:Double]()
                                        
                                        //Assumes types and results are always the same size
                                        for i in 0 ..< m_results.count {
                                            resultsDict[m_type[i]] = m_results[i]
                                        }
                                        
                                        module_dict[key] = resultsDict
                                    }
                                    
                                }
                                
                                //Insert station information in the stations dictionary
                                stations[s_id] = [
                                    "s_location":s_location,
                                    "s_altitude":s_altitude,
                                    "s_timezone":s_timezone,
                                    "modules":module_dict
                                ]
                                
                                //CoreData: If you need to store the temperature for a module
                                //This works as far as finding the temperature, need to write additional method to store temp
                                /*for (key,data) in modules{
                                    var m_type = data["type"] as! [String]
                                    if let m_index_of_temp = m_type.indexOf("temperature"){
                                        var m_temp = data["res"] as! [String: [AnyObject]]
                                        
                                        var m_id:String
                                        var m_results:Double
                                        
                                        for(f_id, f_data) in m_temp{
                                            m_id = f_id
                                            var m_results = f_data[m_index_of_temp]
                                        }
                                        
                                        //Store m_results in core database to save all temperatures
                                    }
                                }*/
                                
                            }
                            
                        }
                        completionHandler(stations: stations, error: error)
                    }
                } catch let error as NSError {
                    print("A JSON parsing error occurred, here are the details:\n \(error)")
                    completionHandler(stations: nil , error: error)
                }
            }
        }
    }
    
    //Currently not using this method
    func fetchMeasurements(device:NetatmoStation ,module: NetatmoModule? ,completionHandler:(error : NSError?)->Void) {
        let mp = NetatmoMeasureProvider(coreDataStore: nil)
        let startDate = mp.getLastMeasureDate(device, forModule: module)
        let endDate = NSDate()
        self.fetchMeasurements(device, module: module, startDate: startDate, endDate: endDate, completionHandler: completionHandler)
    }
    
    //Currently not using this method
    func fetchMeasurements(device:NetatmoStation ,module: NetatmoModule?, startDate : NSDate , endDate: NSDate, completionHandler:(error : NSError?)->Void) {
        
        loginProvider.getAuthenticationToken { (token) -> Void in
            if token == nil {
                completionHandler(error: NSError(domain: "", code: 500, userInfo: nil))
                return
            }
            
            let url = NSURL(string: kQSNetatmoGetMeasureURL)
            let mp = NetatmoMeasureProvider(coreDataStore: nil)
            let dbegin = Int(startDate.timeIntervalSince1970)
            let dend = Int(endDate.timeIntervalSince1970)
            
            var measurelist = device.measurementTypes
            var module_id = ""
            
            if (module != nil) {
                module_id =  module!.id
                measurelist = module!.measurementTypes
            }
            
            //let typeList = (measurelist.map { "\($0.rawValue)" } as [String]).joinWithSeparator(",")
            let typeList = (measurelist.map { "\($0)" } as [String]).joinWithSeparator(",")
            
            let postData : [String:AnyObject] = ["access_token":token!,
                "optimize":"true",
                "device_id":device.id,
                "scale":"max",
                "module_id":module_id,
                "type": typeList,
                "date_begin":dbegin,
                "date_end":dend];
            
            self.networkStack.callUrl(url!, method: .POST, arguments: postData) { (resultData, error) -> Void in
                if (error == nil) {
                    do {
                        if let parsed = try NSJSONSerialization.JSONObjectWithData(resultData!, options: NSJSONReadingOptions.AllowFragments) as? NSDictionary {
                            mp.insertMeasuresWithJsonData(parsed, forStation: device, forModule: module)
                        }
                        completionHandler(error: error)
                        
                    } catch let error as NSError {
                        print("A JSON parsing error occurred, here are the details:\n \(error)")
                        completionHandler(error: error)
                    }
                    
                } else {
                    print(error)
                    completionHandler(error: error)
                }
                
            };
        }
    }
    
}