//
//  QiSmartCityTests.swift
//  QiSmartCityTests
//
//  Created by Corey Baker on 5/10/16.
//  Copyright © 2016 University of California San Diego. All rights reserved.
//
//  Original code by: Thomas Kluge, https://github.com/thkl/NetatmoSwift

import XCTest
@testable import QiSmartCity

class QiSmartCityTests: XCTestCase {
    
    //If you are trying to unit test, need to add the info below
    let kQSCNetatmoUserName             = ""
    let kQSCNetatmoPassword             = ""
    
    let provider = NetatmoNetworkProvider()
    
    let stationProvider = NetatmoStationProvider(coreDataStore: nil)
    let moduleProvider = NetadmoModuleProvider(coreDataStore: nil)
    let measurementProvider = NetatmoMeasureProvider(coreDataStore: nil)
    
    override func setUp() {
        super.setUp()
        
        let readyExpectation = expectationWithDescription("ready")
        
        provider.loginWithUser(kQSCNetatmoUserName, password: kQSCNetatmoPassword) { (token, error) -> Void in
            XCTAssertNotNil(token)
            readyExpectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(60, handler: { error in
            XCTAssertNil(error, "Error")
        })
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    //This is the main test and should pass
    func testLoadPublicDataFromNetwork() {
        let readyExpectation = expectationWithDescription("ready")
        
        //Need to figure out how to use the global struct LatitudeLongitude inside of a testcase
        let sanDiego = LatitudeLongitude(lat_ne: 32.963163, lon_ne: -117.096405, lat_sw: 32.836616, lon_sw: -117.233047)
        
        provider.getPublicData(sanDiego, completionHandler: {(stations, error) -> Void in
            XCTAssertNotNil(stations)
            readyExpectation.fulfill()
            
        })
        
        waitForExpectationsWithTimeout(60, handler: { error in
            XCTAssertNil(error, "Error")
        })
    }
    
    //These have not been tested
    func testLoadElements() {
        let readyExpectation = expectationWithDescription("ready")
        provider.getStationData { (stations, error) -> Void in
            XCTAssertNotNil(stations)
            readyExpectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(60, handler: { error in
            XCTAssertNil(error, "Error")
        })
    }
    
    func testFetchStationMeasurements() {
        let readyExpectation = expectationWithDescription("ready")
        let station = stationProvider.stations().first
        provider.fetchMeasurements(station!, module: nil) { (error) -> Void in
            XCTAssertNil(error)
            readyExpectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(60, handler: { error in
            XCTAssertNil(error, "Error")
        })
    }
    
    func testFetchModuleMeasurements() {
        let readyExpectation = expectationWithDescription("ready")
        let station = stationProvider.stations().first
        let module = moduleProvider.modules().first
        
        provider.fetchMeasurements(station!, module: module) { (error) -> Void in
            XCTAssertNil(error)
            readyExpectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(60, handler: { error in
            XCTAssertNil(error, "Error")
        })
    }
    
    func testFetchLastMeasurementFromDatabase() {
        
        let station = stationProvider.stations().first
        let module = moduleProvider.modules().first
        let startDate = measurementProvider.getLastMeasureDate(station, forModule: module)
        let result = measurementProvider.getMeasurementfor(station!, module: nil, withTypes: [.CO2] , betweenStartDate: startDate, andEndDate: NSDate())
        
        XCTAssertNotEqual(result.count, 0)
        let lr = result.last
        //let strResult = "Last Measurement in Database is \(lr!.timestamp) - \(lr!.value)\(lr!.unit)"
        let strResult = "Last Measurement in Database is \(lr!.timestamp) - \(lr!.value)"
        print(strResult)
    }
}
