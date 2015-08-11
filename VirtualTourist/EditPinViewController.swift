//
//  EditPinViewController.swift
//  VirtualTourist
//
//  Created by Oleksandr Iaroshenko on 28.07.15.
//  Copyright (c) 2015 Oleksandr Iaroshenko. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class EditPinViewController: UIViewController {

    // MARK: - Magic values

    private struct Defaults {
        static let PredicateFormat = "pin == %@"

        static let SwitchDuration: NSTimeInterval = 1.0

        static let EditCollection = "Edit Collection"
        static let DoneEditing = "Done Editing"
        static let AddPhotos = "Add Photos"
        static let RemovePhotos = "Remove Photos"
        static let GoBack = "Go Back"

        static let UnwindSegue = "Unwind Segue"
    }

    private struct Layout {
        static let NumberOfPhotosInRow: CGFloat = 5
    }

    // MARK: - Internal types

    private enum State {
        case Showing, Adding, Editing
    }

    // MARK: - Properties

    var pin: Pin! {
        didSet {
            temporaryPinCopy = Pin(context: CoreDataManager.sharedInstance.context, latitude: Double(pin.latitude), longitude: Double(pin.longitude))
        }
    }

    private var temporaryPinCopy: Pin!

    private var showImagesController: ShowImagesController!
    private var addImagesController: AddImagesController!

    private var showCollectionLayout: UICollectionViewFlowLayout!
    private var addCollectionLayout: UICollectionViewFlowLayout!

    private var state = State.Showing

    // MARK: - Actions and Outlets

    @IBOutlet weak var topBar: UINavigationItem!

    @IBOutlet weak var mapView: MKMapView! {
        didSet {
            if pin != nil {
                addPinToMapView()
            }
        }
    }

    @IBOutlet weak var embeddingView: UIView!
    @IBOutlet weak var showCollectionView: UICollectionView!
    @IBOutlet weak var addCollectionView: UICollectionView!

    @IBAction func deletePin() {
        CoreDataManager.sharedInstance.context.deleteObject(pin)
        performSegueWithIdentifier(Defaults.UnwindSegue, sender: self)
    }

    @IBOutlet weak var editButton: UIButton!
    @IBAction func editPhotos(sender: UIButton) {
        switch state {
        case .Showing:
            state = .Editing
            editButton.setTitle(Defaults.DoneEditing, forState: UIControlState.Normal)
            addButton.setTitle(Defaults.RemovePhotos, forState: UIControlState.Normal)
            showImagesController.canSelectPhotos = true
        case .Editing:
            resetState()
        case .Adding:
            switchCollections()
            resetState()
        }
    }

    @IBOutlet weak var addButton: UIButton!
    @IBAction func addPhotos(sender: UIButton) {
        switch state {
        case .Showing:
            state = .Adding
            editButton.setTitle(Defaults.GoBack, forState: UIControlState.Normal)
            addButton.setTitle(Defaults.AddPhotos, forState: UIControlState.Normal)
            switchCollections()
            fetchPhotosFromFlickr()
        case .Editing:
            removePhotos()
        case .Adding:
            addPhotos()
            switchCollections()
            resetState()
        }
    }

    // MARK: - Auxiliary methods

    private func resetState() {
        state = .Showing
        showImagesController.canSelectPhotos = false
        editButton.setTitle(Defaults.EditCollection, forState: UIControlState.Normal)
        addButton.setTitle(Defaults.AddPhotos, forState: UIControlState.Normal)
    }

    private func createLayout() -> UICollectionViewFlowLayout {
        var layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0

        return layout
    }

    private func getPhotosControllerForPin(pin: Pin) -> NSFetchedResultsController {
        let fetchRequest = NSFetchRequest(entityName: Photo.Entity.Name)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: Photo.Entity.SortingField, ascending: true)]
        fetchRequest.predicate = NSPredicate(format: Defaults.PredicateFormat, pin)

        var controller =  NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataManager.sharedInstance.context, sectionNameKeyPath: nil, cacheName: nil)

        return controller
    }

    private func addPinToMapView() {
        mapView?.addAnnotation(pin)
        mapView?.showAnnotations([pin], animated: false)
    }

    private func fetchPhotosFromFlickr() {
        FlickrAPI.sharedInstance.searchPhotosByCoordinates(latitude: pin.latitude.doubleValue, longitude: pin.longitude.doubleValue) { photos in
            dispatch_async(dispatch_get_main_queue()) {
                for photo in photos {
                    let temporaryPhoto = Photo(context: CoreDataManager.sharedInstance.context, id: photo.id, title: photo.title, url: photo.url)
                    temporaryPhoto.pin = self.temporaryPinCopy
                }
                CoreDataManager.sharedInstance.saveContext()
            }
        }
    }

    private func addPhotos() {
        for photo in addImagesController.selectedPhotos() {
            let persistentPhoto = Photo(context: CoreDataManager.sharedInstance.context, id: photo.id, title: photo.title, url: photo.url)
            persistentPhoto.pin = pin
        }
        CoreDataManager.sharedInstance.saveContext()
    }

    private func removePhotos() {
        for photo in showImagesController.selectedPhotos() {
            CoreDataManager.sharedInstance.context.deleteObject(photo)
        }
        CoreDataManager.sharedInstance.saveContext()
    }

    private func switchCollections() {
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationTransition(UIViewAnimationTransition.FlipFromLeft, forView: embeddingView, cache: true)
        UIView.setAnimationCurve(UIViewAnimationCurve.EaseInOut)
        UIView.setAnimationDuration(Defaults.SwitchDuration)
        showImagesController.unselectAll()
        addImagesController.unselectAll()
        embeddingView.exchangeSubviewAtIndex(0, withSubviewAtIndex: 1)
        UIView.commitAnimations()
    }

    // MARK: - Lifecycle methods

    override func viewDidLoad() {
        super.viewDidLoad()

        showCollectionLayout = createLayout()
        showCollectionView.collectionViewLayout = showCollectionLayout
        addCollectionLayout = createLayout()
        addCollectionView.collectionViewLayout = addCollectionLayout

        if pin != nil {
            let showPhotosFetchedResultsController = getPhotosControllerForPin(pin)
            showImagesController = ShowImagesController(collectionView: showCollectionView, photosController: showPhotosFetchedResultsController)

            let addPhotosFetchedResultsController = getPhotosControllerForPin(temporaryPinCopy)
            addImagesController = AddImagesController(collectionView: addCollectionView, photosController: addPhotosFetchedResultsController)
            addImagesController.canSelectPhotos = true

            addPinToMapView()
            resetState()
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let width = floor(showCollectionView.frame.size.width / Layout.NumberOfPhotosInRow)
        showCollectionLayout.itemSize = CGSize(width: width, height: width)
        addCollectionLayout.itemSize = CGSize(width: width, height: width)
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        CoreDataManager.sharedInstance.context.deleteObject(temporaryPinCopy)
    }
}