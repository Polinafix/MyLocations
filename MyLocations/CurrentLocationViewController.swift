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
    //perform the geocoding
    let geocoder = CLGeocoder()
    //object that contains the address results
    var placemark: CLPlacemark?
    var performingReverseGeocoding = false
    var lastGeocodingError: Error?
    var timer: Timer?

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
        //If the button is pressed while the app is already doing the location fetching, you stop the location manager
        if updatingLocation {
            stopLocationManager()
        }else {
            //start over with a clean state
            location = nil
            lastLocationError = nil
            placemark = nil
            lastGeocodingError = nil
             startLocationManager()
        }
       
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
            //set up a timer object that sends a didTimeOut message after 60 sec
            timer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(didTimeOut), userInfo: nil, repeats: false)
        }
    }
    
    func stopLocationManager() {
        if updatingLocation {
            locationManager.stopUpdatingLocation()
            locationManager.delegate = nil
            updatingLocation = false
            //You have to cancel the timer in case the location manager is stopped before the timeout fires
            if let timer = timer {
                timer.invalidate()
            }
        }
    }
    
    @objc func didTimeOut() {
        print("*** Time out")
        if location == nil {
            if location == nil {
                stopLocationManager()
                lastLocationError = NSError(domain: "MyLocationsErrorDomain", code: 1, userInfo: nil)
                updateLabels()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let newLocation = locations.last!
        print("didUpdateLocations \(newLocation)")
        //
        if newLocation.timestamp.timeIntervalSinceNow < -5 {
            return
        }
        //ignore if less than 0
        if newLocation.horizontalAccuracy < 0 {
            return
        }
        /*This calculates the distance between the new reading and the previous reading, if there was one.We can use this distance to measure if our location updates are still
        improving.*/
        var distance = CLLocationDistance(Double.greatestFiniteMagnitude)
        if let location = location {
            distance = newLocation.distance(from: location)
        }
        
        //if this is the very first location reading (== nil) or the new location is more accurate than the previous reading, continue
        if location == nil || location!.horizontalAccuracy > newLocation.horizontalAccuracy {
            //clear out any previous error and stores the new CLLocation object into the location variable.
            lastLocationError = nil
            location = newLocation
            /*If the new location’s accuracy is equal to or better than the desired accuracy(which we previously set to 10), you can call it a day and stop asking the location manager for updates*/
            if newLocation.horizontalAccuracy <= locationManager.desiredAccuracy {
                print("*** We're done!")
                stopLocationManager()
                //This forces a reverse geocoding for the final location, even if the app is already currently performing another geocoding request
                
                if distance > 0 {
                    performingReverseGeocoding = false
                }
            }
            updateLabels()
            
            //geocoding
            if !performingReverseGeocoding {
                print("***Going to geocode")
                performingReverseGeocoding = true
                /*
                 telling the CLGeocoder object that you want to reverse geocode the location, and that the code in the block following completionHandler: should be executed as soon as the geocoding is completed. */
                geocoder.reverseGeocodeLocation(newLocation, completionHandler: { (placemarks, error) in
                    self.lastGeocodingError = error
                    if error == nil,let p = placemarks, !p.isEmpty {
                        self.placemark = p.last!
                    }else {
                        self.placemark = nil
                    }
                    self.performingReverseGeocoding = false
                    self.updateLabels()
                 
                })
                /* If the coordinate from this reading is not significantly different from the previous reading and it has been more than 10 seconds since you’ve received that original reading, then it’s a good point to hang up your hat and stop. */
            }else if distance < 1 {
                let timeInterval = newLocation.timestamp.timeIntervalSince(location!.timestamp)
                if timeInterval > 10 {
                    print("*** Force done!")
                    stopLocationManager()
                    updateLabels()
                }
            }
        }

    }
    
    func updateLabels() {
        if let location = location {
            latitudeLabel.text = String(format: "%.8f",location.coordinate.latitude)
            longitudeLabel.text = String(format: "%.8f",location.coordinate.longitude)
            tagButton.isHidden = false
            messageLabel.text = ""
            
            if let placemark = placemark {
                addressLabel.text = string(from:placemark)
            }else if performingReverseGeocoding {
                addressLabel.text = "Searching for Address..."
            }else if lastGeocodingError != nil {
                addressLabel.text = "Error finding address"
            }else{
                addressLabel.text = "No Address Found"
            }
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
        configureGetButton()
    }
    //method for formatting the CLPlacemark object into a string
    func string(from placemark: CLPlacemark) -> String {
        var line1 = ""
        //house number
        if let s = placemark.subThoroughfare {
            line1 += s + " "
        }
        //street name
        if let s = placemark.thoroughfare {
            line1 += s
        }
        var line2 = ""
        
    //the city
        if let s = placemark.locality {
            line2 += s + " "
        }
        //state
        if let s = placemark.administrativeArea {
            line2 += s + " "
        }
        //zip code
        if let s = placemark.postalCode {
            line2 += s
        }
        // 5
        return line1 + "\n" + line2
    }
    
    func configureGetButton() {
        if updatingLocation {
            getButton.setTitle("Stop", for: .normal)
        }else {
            getButton.setTitle("Get My Location", for: .normal)
        }
    }


}

