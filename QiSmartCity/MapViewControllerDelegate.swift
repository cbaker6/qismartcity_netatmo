//
//  MapViewControllerDelegate.swift
//  QiSmartCity
//
//  Created by Corey Baker on 5/12/16.
//  Copyright © 2016 University of California San Diego. All rights reserved.
//

import Foundation
import MapKit

extension MapViewController: MKMapViewDelegate{
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? StationAnnotation{
            let identifier = "pin"
            var view: MKPinAnnotationView
            
            if let dequedView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier) as? MKPinAnnotationView{
                dequedView.annotation = annotation
                view = dequedView
            }else{
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.canShowCallout = true
                view.calloutOffset = CGPoint(x: -5, y: 5)
                view.rightCalloutAccessoryView = UIButton.init(type: .DetailDisclosure) as UIView
            }
            return view
        }
        
        return nil
    }
}