//
//  ImagesController.swift
//  VirtualTourist
//
//  Created by Oleksandr Iaroshenko on 07.08.15.
//  Copyright (c) 2015 Oleksandr Iaroshenko. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class ImagesController: NSObject, UICollectionViewDataSource, UICollectionViewDelegate,NSFetchedResultsControllerDelegate {

    // MARK: - Internal structure

    private var collectionView: UICollectionView
    private var photosController: NSFetchedResultsController

    private var insertedIndexes = [NSIndexPath]()
    private var updatedIndexes = [NSIndexPath]()
    private var deletedIndexes = [NSIndexPath]()

    private var selectedIndexes = [NSIndexPath]()

    // MARK: - Initializer

    init(collectionView: UICollectionView, photosController: NSFetchedResultsController) {
        self.collectionView = collectionView
        self.photosController = photosController

        super.init()

        self.collectionView.dataSource = self
        self.collectionView.delegate = self

        self.photosController.delegate = self
        self.photosController.performFetch(nil)
    }

    // MARK: - Interface

    var canSelectPhotos = false

    func selectedPhotos() -> [Photo] {
        var result = [Photo]()

        for index in selectedIndexes {
            let photo = photosController.objectAtIndexPath(index) as! Photo
            result.append(photo)
        }

        return result
    }

    func unselectAll() {
        selectedIndexes = []
        collectionView.reloadData()
    }

    // MARK: - UICollectionView data source

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
//        collectionView.collectionViewLayout.invalidateLayout()
        return photosController.sections?.count ?? 0
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = photosController.sections?[section] as? NSFetchedResultsSectionInfo
        let numberOfItems = sectionInfo?.numberOfObjects ?? 0

        return numberOfItems
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(ImageCollectionViewCell.ReuseIdentifier, forIndexPath: indexPath) as! ImageCollectionViewCell

        let selected = find(selectedIndexes, indexPath) != nil
        markCell(cell, selected: selected)

        if let photo = photosController.objectAtIndexPath(indexPath) as? Photo {
            if cell.photo != photo {
                cell.imageView.image = nil
                cell.photo = photo
            }
        }

        return cell
    }

    // MARK: - UICollectionView delegate

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if canSelectPhotos {
            let cell = collectionView.cellForItemAtIndexPath(indexPath) as! ImageCollectionViewCell

            if let index = find(selectedIndexes, indexPath) {
                selectedIndexes.removeAtIndex(index)
                markCell(cell, selected: false)
            } else {
                selectedIndexes.append(indexPath)
                markCell(cell, selected: true)
            }

        }
    }

    // MARK: - NSFetchedResultsController delegate

    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        resetChanges()
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
        collectionView.performBatchUpdates({ () -> Void in
            for indexPath in self.insertedIndexes {
                self.collectionView.insertItemsAtIndexPaths([indexPath])
            }
            for indexPath in self.updatedIndexes {
                self.collectionView.reloadItemsAtIndexPaths([indexPath])
            }
            for indexPath in self.deletedIndexes {
                self.collectionView.deleteItemsAtIndexPaths([indexPath])
            }
            self.resetChanges()
        }, completion: nil)
    }

    // MARK: - Auxiliary methods

    private func resetChanges() {
        insertedIndexes = []
        updatedIndexes = []
        deletedIndexes = []
    }

    func markCell(cell: ImageCollectionViewCell, selected: Bool) {
    }
}