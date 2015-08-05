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

class EditPinViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {

    // MARK: - Magic values

    private struct Defaults {
        static let ImageCellReuseIdentifier = "ImageCollectionViewCell"
        static let PredicateFormat = "pin == %@"

        static let StandardAlpha: CGFloat = 1.0
        static let RemovedAlpha: CGFloat = 0.1

        static let EditCollection = "Edit Collection"
        static let RemovePhotos = "Remove Photos"

        static let UnwindSegue = "Unwind Segue"
    }

    private struct Layout {
        static let NumberOfPhotosInRow: CGFloat = 5
    }

    // MARK: - Properties

    var pin: Pin!

    private var photosController: NSFetchedResultsController!

    private var selectedIndexes = [NSIndexPath]()

    private var insertedIndexes: [NSIndexPath]!
    private var updatedIndexes: [NSIndexPath]!
    private var deletedIndexes: [NSIndexPath]!

    private var isEditingPhotos = false

    // MARK: - Geomerty and layout

    private var layout: UICollectionViewFlowLayout = {
        var layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0

        return layout
    }()

    // MARK: - Actions and Outlets

    @IBOutlet weak var topBar: UINavigationItem!

    @IBOutlet weak var mapView: MKMapView! {
        didSet {
            if pin != nil {
                addPinToMapView()
            }
        }
    }

    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            collectionView.dataSource = self
            collectionView.delegate = self
        }
    }

    @IBAction func deletePin() {
        CoreDataManager.sharedInstance.context.deleteObject(pin)
        performSegueWithIdentifier(Defaults.UnwindSegue, sender: self)
    }

    @IBOutlet weak var editRemoveBottomButton: UIButton!
        {
        didSet {
            editRemoveBottomButton.setTitle(Defaults.EditCollection, forState: UIControlState.Normal)
        }
    }

    @IBAction func editRemovePhotos(sender: UIButton) {
        isEditingPhotos = !isEditingPhotos
        if isEditingPhotos {
            editRemoveBottomButton.setTitle(Defaults.RemovePhotos, forState: UIControlState.Normal)
        } else {
            editRemoveBottomButton.setTitle(Defaults.EditCollection, forState: UIControlState.Normal)
            removePhotos()
        }
    }

    // MARK: - NSFetchResultsControllerDelegate methods

    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        insertedIndexes = [NSIndexPath]()
        updatedIndexes = [NSIndexPath]()
        deletedIndexes = [NSIndexPath]()
    }

    func controller(controller: NSFetchedResultsController, didChangeObject object: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            insertedIndexes.append(newIndexPath!)
        case .Update:
            updatedIndexes.append(indexPath!)
        case .Delete:
            deletedIndexes.append(indexPath!)
        default:
            return
        }
    }

    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        collectionView.performBatchUpdates({
            for indexPath in self.insertedIndexes {
                self.collectionView.insertItemsAtIndexPaths([indexPath])
            }
            for indexPath in self.updatedIndexes {
                self.collectionView.reloadItemsAtIndexPaths([indexPath])
            }
            for indexPath in self.deletedIndexes {
                self.collectionView.deleteItemsAtIndexPaths([indexPath])
            }
        }, completion: nil)
    }

    // MARK: - UICollectionView data source

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.photosController?.sections?.count ?? 0
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = photosController?.sections?[section] as? NSFetchedResultsSectionInfo
        return sectionInfo?.numberOfObjects ?? 0
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(Defaults.ImageCellReuseIdentifier, forIndexPath: indexPath) as! ImageCollectionViewCell

        if let index = find(selectedIndexes, indexPath) {
            cell.imageView.alpha = Defaults.RemovedAlpha
        } else {
            cell.imageView.alpha = Defaults.StandardAlpha
        }
        let photo = photosController!.objectAtIndexPath(indexPath) as! Photo
        if cell.photo != photo {
            cell.imageView.image = nil
            cell.photo = photo
        }

        return cell
    }

    // MARK: - UICollectionView delegate

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if isEditingPhotos {
            let cell = collectionView.cellForItemAtIndexPath(indexPath) as! ImageCollectionViewCell

            if let index = find(selectedIndexes, indexPath) {
                selectedIndexes.removeAtIndex(index)
                cell.imageView.alpha = Defaults.StandardAlpha
            } else {
                selectedIndexes.append(indexPath)
                cell.imageView.alpha = Defaults.RemovedAlpha
            }
        }
    }

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
    return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
    return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
    return false
    }

    override func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
    return false
    }

    override func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {

    }
    */


    // MARK: - Auxiliary methods

    private func setPhotosController() {
        let fetchRequest = NSFetchRequest(entityName: Photo.Entity.Name)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: Photo.Entity.SortingField, ascending: false)]
        fetchRequest.predicate = NSPredicate(format: Defaults.PredicateFormat, pin!)

        photosController =  NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataManager.sharedInstance.context, sectionNameKeyPath: nil, cacheName: nil)
        photosController?.delegate = self
    }

    private func addPinToMapView() {
        mapView?.addAnnotation(pin!)
        mapView?.showAnnotations([pin!], animated: false)
    }

    private func fetchPhotosFromFlickr() {
        FlickrAPI.sharedInstance.searchPhotosByCoordinates(latitude: pin.latitude.doubleValue, longitude: pin.longitude.doubleValue) { photos in
            dispatch_async(dispatch_get_main_queue()) {
                for photo in photos {
                    let persistentPhoto = Photo(context: CoreDataManager.sharedInstance.context, id: photo.id, title: photo.title, url: photo.url)
                    persistentPhoto.pin = self.pin
                }
                CoreDataManager.sharedInstance.saveContext()

                self.collectionView.reloadData()
            }
        }
    }

    private func removePhotos() {
        for index in selectedIndexes {
            CoreDataManager.sharedInstance.context.deleteObject(photosController.objectAtIndexPath(index) as! Photo)
        }
        CoreDataManager.sharedInstance.saveContext()

        selectedIndexes = []
    }

    // MARK: - Lifecycle methods

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.collectionViewLayout = layout

        if pin != nil {
            setPhotosController()
            photosController?.performFetch(nil)
            addPinToMapView()
            if pin.photos.isEmpty {
                fetchPhotosFromFlickr()
            }
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let width = floor(collectionView.frame.size.width / Layout.NumberOfPhotosInRow)
        layout.itemSize = CGSize(width: width, height: width)
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

    }
}