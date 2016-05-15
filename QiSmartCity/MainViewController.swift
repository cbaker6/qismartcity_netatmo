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

class MainViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var lineChartView: LineChartView!
    @IBOutlet weak var scatterChartView: ScatterChartView!
    @IBOutlet weak var barChartView: BarChartView!
    @IBOutlet weak var pieChartView: PieChartView!
    
    @IBOutlet weak var locationPicker: UIPickerView!
    
    //Store all cities in this dictionary
    var cities = [String:LatitudeLongitude]()
    var citiesArray = [String]()
    
    var validToken = false
    var dataTypeUserInteresedIn : NetatmoDataType = .Temperature //default to temperature
    var cityUserInterestedIn = 0 //default city interested in
    var chartUserInterestedIn : ChartType = .Line //default line
    
    var stations : [StationAnnotation] = []
    let regionRadius: CLLocationDistance = 1000
    let networkLoginProvider = NetatmoLoginProvider()
    
    let provider = NetatmoNetworkProvider()
    var netatmoStationInfo:[String:AnyObject]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.locationPicker.dataSource = self
        self.locationPicker.delegate = self
        self.mapView.delegate = self
        
        //These should be white, just set to different colors to tell the difference between them in storyboard
        self.lineChartView.backgroundColor = .whiteColor()
        self.scatterChartView.backgroundColor = .whiteColor()
        self.barChartView.backgroundColor = .whiteColor()
        self.pieChartView.backgroundColor = .whiteColor()
        
        //Clear all data
        self.cities.removeAll()
        self.citiesArray.removeAll()
        self.mapView.removeAnnotations(self.stations)
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
                
                //Get the the station data from Netatmo using the cityUserInterestedIn
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
                    
                    switch self.chartUserInterestedIn{
                    case .Line, .Scatter, .Pie:
                        self.setChart()
                    case .Bar:
                        self.setBarChart()
                    default:
                        print("Error in viewDidLoad for chart type. The current type is not a valid chart type")
                    }
                    
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
        
        return 3
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        switch component {
        case 0:
            return self.citiesArray.count
            
        case 1:
            return NetatmoDataType.Count.hashValue
            
        case 2:
            return ChartType.Count.hashValue
            
        default:
            print("Error in pickerView. The 'compoenent' \(component) has not been implemented yet")
            return 1
        }
        
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        switch component {
        case 0:
            return self.citiesArray[row]
            
        case 1:
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
            
        case 2:
            switch row {
            case 0:
                return ChartType.Line.rawValue
            case 1:
                return ChartType.Scatter.rawValue
            case 2:
                return ChartType.Bar.rawValue
            case 3:
                return ChartType.Pie.rawValue
            default:
                return "Error, not implemented"
            }
        default:
            print("Error, component type not implemented")
            return nil
        }
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        switch component {
        case 0:
            self.cityUserInterestedIn = row
            self.viewDidLoad()
            
        case 1:
            switch row {
            case 0:
                self.dataTypeUserInteresedIn = .Temperature
                self.viewDidLoad()
            case 1:
                self.dataTypeUserInteresedIn = .Humidity
                self.viewDidLoad()
            case 2:
                self.dataTypeUserInteresedIn = .Pressure
                self.viewDidLoad()
            case 3:
                self.dataTypeUserInteresedIn = .CO2
                self.viewDidLoad()
            default:
                print("Error, data not implemented")
            }
            
        case 2:
            switch row {
            case 0:
                self.chartUserInterestedIn = .Line
                self.setChart()
            case 1:
                self.chartUserInterestedIn = .Scatter
                self.setChart()
            case 2:
                self.chartUserInterestedIn = .Bar
                self.setBarChart()
            case 3:
                self.chartUserInterestedIn = .Pie
                self.setChart()
            default:
                print("Error, chart not implemented")
            }
            
        default:
            print("Error, picker selection not implemented")
        }
    }
    
    func createStationAnnotations ()-> Void{
        
        if self.netatmoStationInfo != nil{
            
            //Clear all annotations on screen
            self.mapView.removeAnnotations(self.stations)
            self.stations.removeAll()
            
            var first_latitude :Double?
            var first_longitude:Double?
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
                            //Note: for some reason, Netatmo is returning the location as [longitute,latitude] as opposed to vice-versa
                            let newStation = StationAnnotation(title:  String(stationCounter), locationName: String(format: "%f", dataInterestedIn), discipline: self.dataTypeUserInteresedIn.rawValue, coordinate: CLLocationCoordinate2D(latitude: stationLocation[1], longitude: stationLocation[0]))
                            
                            //Add the station and it's module for annotations
                            self.stations.append(newStation)
                            
                            //Weak hack to center on the last point
                            if stationCounter == 0{
                                first_latitude = stationLocation[1]
                                first_longitude = stationLocation[0]
                            }
                            stationCounter += 1
                            
                            //Once a module is found with the data we are interested in, no need to search the rest of the modules on this particular station
                            break
                        }
                    }
                    
                }
            }
            
            //Center of the map to the locaiton of the first station
            if first_longitude != nil{
                let initialLocation = CLLocation(latitude: first_latitude!, longitude: first_longitude!)
                self.centerMapOnLocation(initialLocation)
            }
            
            //Add all new annotations
            self.mapView.addAnnotations(self.stations)
        }
        
        
    }
    
    func centerMapOnLocation(location: CLLocation){
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    func enableCorrectChartView ()->Void{
        switch self.chartUserInterestedIn {
        case .Line:
            lineChartView.hidden = false
            scatterChartView.hidden = true
            barChartView.hidden = true
            pieChartView.hidden = true
        case .Scatter:
            lineChartView.hidden = true
            scatterChartView.hidden = false
            barChartView.hidden = true
            pieChartView.hidden = true
        case .Bar:
            lineChartView.hidden = true
            scatterChartView.hidden = true
            barChartView.hidden = false
            pieChartView.hidden = true
        case .Pie:
            lineChartView.hidden = true
            scatterChartView.hidden = true
            barChartView.hidden = true
            pieChartView.hidden = false
        default:
            print("Error in enableCorrectChartView(). chartUserInterestedIn = \(self.chartUserInterestedIn) is not a currect chart type")
            lineChartView.hidden = true
            scatterChartView.hidden = true
            barChartView.hidden = true
            pieChartView.hidden = true
        }
    }
    
    func setChart()->Void{
    
        var dataEntries: [ChartDataEntry] = []
        var xVariables = [String]()
        
        for i in 0..<stations.count{
            xVariables.append(stations[i].title!)
            let dataEntry = ChartDataEntry(value: Double(stations[i].locationName)!, xIndex: i)
            dataEntries.append(dataEntry)
        }
        
        self.enableCorrectChartView()
        
        switch chartUserInterestedIn {
        
        case .Line:
            let chartDataSet = LineChartDataSet(yVals: dataEntries, label: self.dataTypeUserInteresedIn.rawValue)
            let chartData = LineChartData(xVals: xVariables, dataSet: chartDataSet)
            lineChartView.data = chartData
            lineChartView.descriptionText = ""
            lineChartView.animate(xAxisDuration: 2.0, yAxisDuration: 2.0)
            
        case .Scatter:
            let chartDataSet = ScatterChartDataSet(yVals: dataEntries, label: self.dataTypeUserInteresedIn.rawValue)
            let chartData = ScatterChartData(xVals: xVariables, dataSet: chartDataSet)
            scatterChartView.data = chartData
            scatterChartView.descriptionText = ""
            scatterChartView.animate(xAxisDuration: 2.0, yAxisDuration: 2.0)
            
        case .Bar:
            print("Error in setChart. Should have called setBarChart instead")
            
        case .Pie:
            let chartDataSet = PieChartDataSet(yVals: dataEntries, label: self.dataTypeUserInteresedIn.rawValue)
            let chartData = PieChartData(xVals: xVariables, dataSet: chartDataSet)
            pieChartView.data = chartData
            pieChartView.descriptionText = ""
            pieChartView.animate(xAxisDuration: 2.0, yAxisDuration: 2.0)
            
        default:
            print("Error in setChart. chartUserInterestedIn \(chartUserInterestedIn.rawValue) is not implemented")
        }
        
    }
    
    func setBarChart()->Void{
        
        var dataEntries: [BarChartDataEntry] = []
        var xVariables = [String]()
        
        for i in 0..<self.stations.count{
            xVariables.append(self.stations[i].title!)
            
            let dataEntry = BarChartDataEntry(value: Double(self.stations[i].locationName)!, xIndex: i)
            dataEntries.append(dataEntry)
        }
        self.enableCorrectChartView()
        let chartDataSet = BarChartDataSet(yVals: dataEntries, label: self.dataTypeUserInteresedIn.rawValue)
        let chartData = BarChartData(xVals: xVariables, dataSet: chartDataSet)
        barChartView.data = chartData
        barChartView.descriptionText = ""
        barChartView.animate(xAxisDuration: 2.0, yAxisDuration: 2.0)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

