//
//  Pin.swift
//  VirtualTourist
//
//  Created by Oleksandr Iaroshenko on 28.07.15.
//  Copyright (c) 2015 Oleksandr Iaroshenko. All rights reserved.
//

import Foundation
import CoreData
import MapKit

@objc(Pin)
class Pin: NSManagedObject {

    // MARK: - Magic values

    struct Entity {
        static let Name = "Pin"
        static let SortingField = "timeStamp"
    }

    private struct Defaults {
        static let Title = "Pin"
    }

    // MARK: - Properties

    @NSManaged var title: String

    @NSManaged var latitude: NSNumber
    @NSManaged var longitude: NSNumber

    @NSManaged var timeStamp: NSDate

    @NSManaged var photos: [Photo]

    // MARK: - Initializers

    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }

    convenience init(context: NSManagedObjectContext, latitude: Double, longitude: Double) {
        let entity =  NSEntityDescription.entityForName(Pin.Entity.Name, inManagedObjectContext: context)!
        self.init(entity: entity, insertIntoManagedObjectContext: context)

        self.title = Defaults.Title

        self.latitude = latitude
        self.longitude = longitude

        self.timeStamp = NSDate()
    }
}

// MARK: - MKAnnotation protocol conforming

extension Pin: MKAnnotation {

    var coordinate: CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2D(latitude: CLLocationDegrees(latitude.doubleValue), longitude: CLLocationDegrees(longitude.doubleValue))
        }
    }

    var subtitle: String! {
        get {
            return ""
        }
    }
}