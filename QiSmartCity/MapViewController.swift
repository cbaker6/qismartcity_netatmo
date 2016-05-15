//
//  ViewController.swift
//  QiSmartCity
//
//  Created by Corey Baker on 5/10/16.
//  Copyright © 2016 University of California San Diego. All rights reserved.
//
//  For MapKit see: https://www.raywenderlich.com/90971/introduction-mapkit-swift-tutorial
//  For Charts see: http://www.appcoda.com/ios-charts-api-tutorial/

import UIKit
import MapKit
import Charts

class MapViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {

    @IBOutlet weak var scMapView: MKMapView!
    @IBOutlet weak var scChartView: LineChartView!
    @IBOutlet weak var locationPicker: UIPickerView!
    
    //Store all cities in this dictionary
    var cities = [String:LatitudeLongitude]()
    var citiesArray = [String]()
    
    var validToken = false
    var dataTypeUserInteresedIn = NetatmoDataType.Temperature //default to temperature
    var cityUserInterestedIn = 0 //default city interested in
    
    var stations : [StationAnnotation] = []
    let regionRadius: CLLocationDistance = 1000
    let networkLoginProvider = NetatmoLoginProvider()
    
    let provider = NetatmoNetworkProvider()
    var netatmoStationInfo:[String:AnyObject]?
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.locationPicker.dataSource = self
        self.locationPicker.delegate = self
        self.scMapView.delegate = self
        
        //Clear all data
        self.cities.removeAll()
        self.citiesArray.removeAll()
        self.scMapView.removeAnnotations(self.stations)
        self.stations.removeAll()
        self.netatmoStationInfo?.removeAll()
        
        self.validToken = false
        
        networkLoginProvider.getAuthenticationToken({(token) -> Void in
            
            if token != nil{
                
                self.validToken = true
            
                //Add a city like like this
                self.citiesArray.append("San Diego")
                self.cities[self.citiesArray[0]] = LatitudeLongitude(lat_ne: 32.963163, lon_ne: -117.096405, lat_sw: 32.836616, lon_sw: -117.233047)
                
                self.citiesArray.append("Los Angeles")
                self.cities[self.citiesArray[1]] = LatitudeLongitude(lat_ne: 34.0522, lon_ne: -118.096405, lat_sw: 33.5522, lon_sw: -118.143047)
                
                self.citiesArray.append("San Francisco")
                self.cities[self.citiesArray[2]] = LatitudeLongitude(lat_ne: 37.963163, lon_ne: -122.096405, lat_sw: 37.836616, lon_sw: -122.233047)
                
                self.citiesArray.append("New York")
                self.cities[self.citiesArray[3]] = LatitudeLongitude(lat_ne: 40.7128, lon_ne: -74.096405, lat_sw: 40.6000, lon_sw: -74.233047)
                
                self.provider.getPublicData(self.cities[self.citiesArray[self.cityUserInterestedIn]]!, completionHandler: {(netatmoStations, error) -> Void in
                    
                    if error == nil{
                        //Store station information gathered from web locally if any is available
                        if netatmoStations != nil{
                            self.netatmoStationInfo = netatmoStations!
                        }
                    }else{
                        print(error)
                    }
                    
                    self.createStationAnnotations()
                    self.setChart()
                    
                })
                
            }else{
                self.validToken = false
            }
            
        })
        
    }
    @IBAction func logoutButtonTapped(sender: AnyObject) {
        networkLoginProvider.deleteAuthenticationToken()
        self.dismissViewControllerAnimated(false, completion: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        //If session is expired, go to login screen
        if validToken == false{
            self.dismissViewControllerAnimated(false, completion: nil)
        }
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        
        return 2
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == 0{
            return self.citiesArray.count
        }else{
            return 4 //This should be the same as the number of NetatmoDataType
        }
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if component == 0{
            return self.citiesArray[row]
        }else if component == 1{
            
            switch row {
            case 0:
                return NetatmoDataType.Temperature.rawValue
            case 1:
                return NetatmoDataType.Humidity.rawValue
            case 2:
                return NetatmoDataType.Pressure.rawValue
            case 3:
                return NetatmoDataType.CO2.rawValue
            default:
                return "Error, not implemented"
            }
        }
        
        return nil
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        if component == 0 {
            self.cityUserInterestedIn = row
            self.viewDidLoad()
        }else{
            
            switch row {
            case 0:
                self.dataTypeUserInteresedIn = NetatmoDataType.Temperature
                self.viewDidLoad()
            case 1:
                self.dataTypeUserInteresedIn = NetatmoDataType.Humidity
                self.viewDidLoad()
            case 2:
                self.dataTypeUserInteresedIn = NetatmoDataType.Pressure
                self.viewDidLoad()
            case 3:
                self.dataTypeUserInteresedIn = NetatmoDataType.CO2
                self.viewDidLoad()
            default:
                print("Error, not implemented")
            }
            
        }
    }
    
    @IBAction func refreshBarItemTapped(sender: AnyObject) {
        
        self.viewDidLoad()
    }
    
    
    func createStationAnnotations ()-> Void{
        
        if self.netatmoStationInfo != nil{
            
            //Clear all annotations on screen
            self.scMapView.removeAnnotations(self.stations)
            self.stations.removeAll()
            
            var last_latitude :Double?
            var last_longitude:Double?
            var stationCounter = 0;
            
            //Iterate through all statioins, checking for data type
            //First item is Station Mac Address
            for (_, stationData) in self.netatmoStationInfo!{
              
                if let module = stationData["modules"] as? [String:AnyObject] {
                    //First item is Module ID
                    for (_, moduleData) in module{
                        
                        var moduleData = moduleData as! [String:AnyObject]
                        
                        if let dataInterestedIn = moduleData[self.dataTypeUserInteresedIn.rawValue] as? Double{
                         
                            //Get staiton locaiton
                            let stationLocation = stationData["s_location"] as! [Double]
                            
                            //Create new annotation for the station and it's module
                            //Note, for some reason, Netatmo is returning the location as [longitute,latitude] as opposed to vice-versa
                            let newStation = StationAnnotation(title:  String(stationCounter), locationName: String(format: "%f", dataInterestedIn), discipline: self.dataTypeUserInteresedIn.rawValue, coordinate: CLLocationCoordinate2D(latitude: stationLocation[1], longitude: stationLocation[0]))
                            
                            //Add the station and it's module for annotations
                            self.stations.append(newStation)
                            
                            //Weak hack to center on the last point
                            if stationCounter == 0{
                            last_latitude = stationLocation[1]
                            last_longitude = stationLocation[0]
                            }
                            stationCounter += 1
                            
                            //Once a module is found with the data we are interested in, no need to search the modules on this particular station
                            break
                        }
                    }
                    
                }
            }
            
            //Initialize the center of the map to some locaiton
            if last_longitude != nil{
                let initialLocation = CLLocation(latitude: last_latitude!, longitude: last_longitude!)
                //Always initialize MapKit in main queue or it will crash
                //dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.centerMapOnLocation(initialLocation)
                //})
            }
            //Add all new annotations
            self.scMapView.addAnnotations(self.stations)
        }
        
        
    }

    
    func centerMapOnLocation(location: CLLocation){
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, regionRadius * 2.0, regionRadius * 2.0)
        scMapView.setRegion(coordinateRegion, animated: true)
    }
    
    func setChart()->Void{
    
        var dataEntries: [ChartDataEntry] = []
        var xVariables = [String]()
        
        for i in 0..<stations.count{
            xVariables.append(stations[i].title!)
            let dataEntry = ChartDataEntry(value: Double(stations[i].locationName)!, xIndex: i)
            dataEntries.append(dataEntry)
        }
        
        let chartDataSet = LineChartDataSet(yVals: dataEntries, label: self.dataTypeUserInteresedIn.rawValue)
        let chartData = LineChartData(xVals: xVariables, dataSet: chartDataSet)
        
        scChartView.data = chartData
        scChartView.animate(xAxisDuration: 2.0, yAxisDuration: 2.0)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

