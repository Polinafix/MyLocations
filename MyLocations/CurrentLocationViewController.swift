//
//  CurrentLocationViewController.swift
//  MyLocations
//
//  Created by Polina Fiksson on 09/10/2017.
//  Copyright © 2017 PolinaFiksson. All rights reserved.
//

import UIKit
import CoreLocation

class CurrentLocationViewController: UIViewController,CLLocationManagerDelegate {
    
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var tagButton: UIButton!
    @IBOutlet weak var getButton: UIButton!
    
    //the object that will give the GPS coordinates
    let locationManager = CLLocationManager()
    var location: CLLocation?
    var updatingLocation = false
    var lastLocationError: Error?

    override func viewDidLoad() {
        super.viewDidLoad()
        updateLabels()
    }
    //if location services are disabled
    func showLocationServicesDeniedAlert() {
        let alert = UIAlertController(title: "Location Services Disabled", message: "Please enable location services for this app in Settings.", preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated:true, completion: nil)
    }
    
    @IBAction func getLocation() {
        //ask for permission
        let authStatus = CLLocationManager.authorizationStatus()
        if authStatus == .notDetermined {
            //get location updates while app  is open and the user is interacting with it
            locationManager.requestWhenInUseAuthorization()
            return
        }
        //shows the alert if the authorization status is denied or restricted.
        if authStatus == .denied || authStatus == .restricted {
            showLocationServicesDeniedAlert()
            return
        }
        //
        startLocationManager()
        updateLabels()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("didFailWithError \(error)")
        //the location manager was unable to obtain a location right now
        if(error as NSError).code == CLError.locationUnknown.rawValue {
            return
        }
        //In the case of a more serious error, you store the error object       
        lastLocationError = error
        stopLocationManager()
        updateLabels()
    }
    func startLocationManager() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy =
            kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
            updatingLocation = true
        }
    }
    
    func stopLocationManager() {
        if updatingLocation {
            locationManager.stopUpdatingLocation()
            locationManager.delegate = nil
            updatingLocation = false
        }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let newLocation = locations.last!
        print("didUpdateLocations \(newLocation)")
        
        location = newLocation
        //After receiving a valid coordinate, any previous error you may have encountered is no longer applicable
        lastLocationError = nil
        updateLabels()
    }
    
    func updateLabels() {
        if let location = location {
            latitudeLabel.text = String(format: "%.8f",location.coordinate.latitude)
            longitudeLabel.text = String(format: "%.8f",location.coordinate.longitude)
            tagButton.isHidden = false
            messageLabel.text = ""
        } else {
            latitudeLabel.text = ""
            longitudeLabel.text = ""
            addressLabel.text = ""
            tagButton.isHidden = true
            //messageLabel.text = "Tap 'Get My Location' to Start"
            let statusMessage:String
            //If the location manager gave an error
            if let error = lastLocationError as NSError? {
                if error.domain == kCLErrorDomain && error.code == CLError.denied.rawValue {
                    statusMessage = "Location Services Disabled"
                }else{
                    statusMessage = "Error Getting Location"
                }
                //disabled Location Services completely on the device - not only for this app
            }else if !CLLocationManager.locationServicesEnabled() {
                    statusMessage = "Location Services Disabled"
            }else if updatingLocation {
                statusMessage = "Searching..."
            }else {
                statusMessage = "Tap 'Get My Location' to Start"
            }
            messageLabel.text = statusMessage
            
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

