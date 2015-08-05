//
//  Photo.swift
//  VirtualTourist
//
//  Created by Oleksandr Iaroshenko on 28.07.15.
//  Copyright (c) 2015 Oleksandr Iaroshenko. All rights reserved.
//

import Foundation
import UIKit
import CoreData

@objc(Photo)
class Photo: NSManagedObject {

    // MARK: - Magic values

    struct Entity {
        static let Name = "Photo"
        static let SortingField = "id"
    }

    // MARK: - Cache

    private static let imageCache = ImageCache()

    // MARK: - Properties

    @NSManaged var id: String
    @NSManaged var title: String
    @NSManaged var url: String

    @NSManaged var pin: Pin?

    // MARK: - Initializers

    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }

    convenience init(context: NSManagedObjectContext, id: String, title: String, url: String) {
        let entity =  NSEntityDescription.entityForName(Entity.Name, inManagedObjectContext: context)!
        self.init(entity: entity, insertIntoManagedObjectContext: context)

        self.id = id
        self.title = title
        self.url = url
    }

    // MARK: - Methods

    func loadImage(completion: (UIImage -> Void)?) {
        let qos = Int(QOS_CLASS_USER_INITIATED.value)
        let queue = dispatch_get_global_queue(qos, 0)
        dispatch_async(queue) {
            var loadedImage: UIImage?

            if let imageInCache = Photo.imageCache.getImageWithIdentifier(self.id) {
                loadedImage = imageInCache
            } else if let imageURL = NSURL(string: self.url), imageData = NSData(contentsOfURL: imageURL) {
                loadedImage = UIImage(data: imageData)
                Photo.imageCache.addImageWithIdentifier(loadedImage, identifier: self.id)
            }

            if loadedImage != nil {
                completion?(loadedImage!)
            }
        }
    }
}