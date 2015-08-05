//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Oleksandr Iaroshenko on 28.07.15.
//  Copyright (c) 2015 Oleksandr Iaroshenko. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {

    // MARK: - Magic values

    private struct Defaults {
        static let EditPinSegue = "Edit Pin Segue"
    }

    // MARK: - Properties

    var pinToEdit: Pin?

    // MARK: - CoreData access

    var pinsController: NSFetchedResultsController? = {
        let fetchRequest = NSFetchRequest(entityName: Pin.Entity.Name)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: Pin.Entity.SortingField, ascending: true)]

        var controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataManager.sharedInstance.context, sectionNameKeyPath: nil, cacheName: nil)

        return controller
    }()

    // MARK: - Actions and Outlets

    @IBOutlet weak var mapView: MKMapView! {
        didSet {
            mapView.delegate = self
        }
    }

    @IBAction func handleLongPress(gesture: UIGestureRecognizer) {
        if gesture.state == UIGestureRecognizerState.Began {
            let touchPoint = gesture.locationInView(mapView)
            let coordinate = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)

            let pin = Pin(context: CoreDataManager.sharedInstance.context, latitude: coordinate.latitude, longitude: coordinate.longitude)
            pinToEdit = pin
            CoreDataManager.sharedInstance.saveContext()

//            performSegueWithIdentifier(Defaults.EditPinSegue, sender: self)
        }
    }

    // MARK: - NSFetchResultsControllerDelegate methods

    func controller(controller: NSFetchedResultsController, didChangeObject object: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            putPinsOnMap([object as! Pin])
        case .Delete:
            mapView.removeAnnotation(object as! Pin)
        default:
            return
        }
    }

    // MARK: - MKMapView delegate

    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        pinToEdit = (view.annotation as! Pin)
        performSegueWithIdentifier(Defaults.EditPinSegue, sender: self)
    }

    // MARK: - Auxiliary methods

    private func updatePins() {
        mapView.removeAnnotations(mapView.annotations)
        if let pins = pinsController?.fetchedObjects as? [Pin] {
            putPinsOnMap(pins)
        }
    }

    private func putPinsOnMap(pins: [Pin]) {
        if pins.count > 0 {
            mapView.addAnnotations(pins)
        }
    }

    // MARK: - Lifecycle methods

    override func viewDidLoad() {
        super.viewDidLoad()

        // Load all pins
        pinsController?.delegate = self
        pinsController?.performFetch(nil)
        updatePins()
    }
    
    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Defaults.EditPinSegue {
            if let navVC = segue.destinationViewController as? UINavigationController,
                destination = navVC.visibleViewController as? EditPinViewController {
                destination.pin = pinToEdit
            }
        }
    }

    @IBAction func pinDoneEditing(segue: UIStoryboardSegue) {

    }
}