//
//  NetatmoLoginProvider.swift
//  netatmoclient
//
//  Created by Corey Baker on 5/10/16.
//  Copyright © 2016 University of California San Diego. All rights reserved.
//
//  Original code by: Thomas Kluge, https://github.com/thkl/NetatmoSwift

import Foundation
import CoreData

class NetatmoLoginProvider {
    
    let coreDataStore = CoreDataStore()
    
    /**
     Fetch current Token as an NSManagedObject from the Database
     */
    private func getTokenObject(tokenName : String)->NSManagedObject? {
        let fetchRequest = NSFetchRequest(entityName: kQSMetadata)
        fetchRequest.predicate = NSPredicate(format: "key == %@",tokenName)
        fetchRequest.fetchLimit = 1
        let results = try! coreDataStore.managedObjectContext.executeFetchRequest(fetchRequest) as! [NSManagedObject]
        if results.count == 0 {
            return nil
        }
        return results.first!
    }
    
    
    /**
     Returns the current token which stored in the Database
     if the token is not there or if its invalid the method returns nil
     */
    func getAuthenticationToken(completionhandler:(token: String?)->Void) {
        
        guard let token = self.getTokenObject(kQSAuthorizationToken) else {
            completionhandler(token: nil)
            return
        }
        
        guard let expiration = token.valueForKey(kQSExpires) as? NSDate else {
            completionhandler(token: nil)
            return
        }
        
        if (expiration.timeIntervalSinceDate(NSDate())>0) {
            completionhandler(token: token.valueForKey(kQSValue) as? String)
            return
        }
        
        // token is no longer valid - lets refresh them
        NSLog("Authentication Token found, have to refresh")
        self.refreshAuthenticationToken { (newToken, error) -> Void in
            if (error == nil) {
                completionhandler(token: newToken)
                return
            } else {
                completionhandler(token: nil)
                return
            }
        }
    }
    
    /**
     Deletes the current token Object in the Database
     */
    func deleteAuthenticationToken() {
        guard let token = self.getTokenObject(kQSAuthorizationToken) else {
            return
        }
        coreDataStore.deleteObject(token)
    }
    
    
    
    /**
     Refreshes the current Token agains the Netatmo API
     */
    func refreshAuthenticationToken(completionhandler:(newToken: String?, error:NSError?)->Void) {
        guard let refreshToken = self.getTokenObject("refresh_token") else {
            completionhandler(newToken: nil, error: NSError(domain: "airpolution.calit2.net.refreshtoken_notfound", code: 500, userInfo: nil))
            return
        }
        
        let networkStack = NetworkStack()
        let url = NSURL(string: kQSNetatmoTokenURL)
        let strToken = refreshToken.valueForKey(kQSValue) as! String
        
        let postData = ["grant_type":"refresh_token",
                        "client_id":kQSCNetatmoClientId,
                        "client_secret":kQSCNetatmoSecret,
                        "refresh_token":strToken]
        
        networkStack.callUrl(url!, method: .POST, arguments: postData) { (resultData, error) -> Void in
            
            if (error == nil) {
                do {
                    if let parsed = try NSJSONSerialization.JSONObjectWithData(resultData!, options: NSJSONReadingOptions.AllowFragments) as? NSDictionary {
                        let expireDate = NSDate().dateByAddingTimeInterval(parsed["expires_in"] as! Double)
                        let accessToken = parsed["access_token"] as! String
                        let refreshToken = parsed["refresh_token"] as! String
                        self.storeToken(kQSAuthorizationToken, tokenValue: accessToken, expiredAt: expireDate)
                        self.storeToken(kQSRefreshToken, tokenValue: refreshToken, expiredAt: expireDate)
                        completionhandler(newToken: accessToken, error: nil)
                    }
                    
                }catch let error as NSError {
                    print("A JSON parsing error occurred, here are the details:\n \(error)")
                    completionhandler(newToken: nil,error: error)
                }
            }
        }
    }
    
    
    private func storeToken(tokenName : String, tokenValue: String, expiredAt: NSDate) {
        // First check an old Token for updateing
        if let token = self.getTokenObject(tokenName) {
            token.setValue(tokenValue, forKey: "value")
            token.setValue(expiredAt, forKey: kQSExpires)
            try! coreDataStore.managedObjectContext.save()
        } else {
            // Create a new DB Object
            let newToken = NSManagedObject(entity: coreDataStore.managedObjectContext.persistentStoreCoordinator!.managedObjectModel.entitiesByName[kQSMetadata]!, insertIntoManagedObjectContext: coreDataStore.managedObjectContext)
            newToken.setValue(tokenName, forKey: "key")
            newToken.setValue(tokenValue, forKey: kQSValue)
            newToken.setValue(expiredAt, forKey: kQSExpires)
            try! coreDataStore.managedObjectContext.save()
        }
    }
    
    /**
     Make a full Login onto the Netatmo API
     */
    func authenticate(username: String, password: String, completionhandler:(newToken: String? , error : NSError?)->Void) {
        
        //do nothing if the token is still valid
        //todo Refresh the token
        self.getAuthenticationToken { (token) -> Void in
            
            if (token != nil) {
                NSLog("Use cached Token")
                completionhandler(newToken: token, error: nil)
                return
            }
            
            let networkStack = NetworkStack()
            let url = NSURL(string: kQSNetatmoTokenURL)
            
            let postData = ["grant_type":"password",
                "client_id":kQSCNetatmoClientId,
                "client_secret":kQSCNetatmoSecret,
                "username":username,
                "password":password]
            
            networkStack.callUrl(url!, method: .POST, arguments: postData) { (resultData, error) -> Void in
                
                if (error == nil) {
                    do {
                        if let parsed = try NSJSONSerialization.JSONObjectWithData(resultData!, options: NSJSONReadingOptions.AllowFragments) as? [String:AnyObject] {
                            
                            if parsed["error"] == nil{
                                let expireDate = NSDate().dateByAddingTimeInterval(parsed["expires_in"] as! Double)
                                let accessToken = parsed["access_token"] as! String
                                let refreshToken = parsed["refresh_token"] as! String
                                self.storeToken(kQSAuthorizationToken, tokenValue: accessToken, expiredAt: expireDate)
                                self.storeToken(kQSRefreshToken, tokenValue: refreshToken, expiredAt: expireDate)
                                completionhandler(newToken: accessToken , error: nil)
                            }else{
                                completionhandler(newToken: nil , error: NSError(domain: parsed["error"] as! String, code: 401, userInfo: nil))
                                
                            }
                            
                        }
                        
                    }catch let error as NSError {
                        print("A JSON parsing error occurred, here are the details:\n \(error)")
                        completionhandler(newToken: nil, error: error)
                    }
                } else {
                    completionhandler(newToken: nil, error: error)
                }
            }
        }
    }
    
}