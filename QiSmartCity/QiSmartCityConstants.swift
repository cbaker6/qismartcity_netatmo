//
//  SmartCityConstants.swift
//  QiSmartCity
//
//  Created by Corey Baker on 5/11/16.
//  Copyright © 2016 University of California San Diego. All rights reserved.
//

import Foundation

// MARK: - HTTP Basic Authintication Info
let kQSCNetatmoClientId             = ""
let kQSCNetatmoSecret               = ""
let kQSNetatmoTokenURL              = "https://api.netatmo.net/oauth2/token"
let kQSNetatmoGetMeasureURL         = "https://api.netatmo.net/api/getmeasure"
let kQSNetatmoGetDeviceListURL      = "https://api.netatmo.net/api/devicelist"
let kQSNetatmoGetPublicDataURL      = "https://api.netatmo.com/api/getpublicdata"

// MARK: - Coredata keys
let kQSAuthorizationToken = "authToken"
let kQSRefreshToken = "refreshToken"
let kQSMetadata = "Metadata"
let kQSExpires = "expires"
let kQSValue = "value"
let kQSTimeStamp = "timestamp"
let kQSType = "type"
let kQSMeasurement = "Measurement"
let kQSStation = "Station"
let kQSStationId = "stationid"
let kQSStationName = "stationname"
let kQSStationType = "stationtype"
let kQSStationLocationLat = "stationlocationlat"
let kQSStationLocationLon = "stationlocationlon"
let kQSModule = "Module"
let kQSModuleId = "moduleid"
let kQSModuleName = "modulename"
let kQSModuleType = "moduletype"
let kQSParentStationId = "parentstationid"

enum NetatmoMeasureType: String {
    
    case Temperature = "Temperature"
    case Humidity = "Humidity"
    case Pressure = "Pressure"
    case CO2 = "CO2"
    case min_temp = "min_temp"
    case max_temp = "max_temp"
    
    case Noise = "Noise"
    case Rain = "Rain"
    
    case sum_rain = "sum_rain"
    case WindStrength = "WindStrength"
    case WindAngle = "WindAngle"
    case GustStrength = "GustStrength"
    case GustAngle = "GustAngle"

}

enum NetatmoDataType: String {
    case Temperature = "temperature"
    case Humidity = "humidity"
    case Pressure = "pressure"
    case CO2 = "co2"
    case Count = "The amount of values for the enum" //Hack to get total amount
}

enum ChartType: String {
    case Line = "Line"
    case Scatter = "Scatter"
    case Bar = "Bar"
    case Pie = "Pie"
    case Count = "The amount of values for the enum" //Hack to get total amount
}


