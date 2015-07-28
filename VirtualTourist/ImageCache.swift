//
//  ImageCache.swift
//  VirtualTourist
//
//  Created by Oleksandr Iaroshenko on 28.07.15.
//  Copyright (c) 2015 Oleksandr Iaroshenko. All rights reserved.
//

import Foundation
import UIKit

class ImageCache {

    // MARK: - Magic values

    private struct Defaults {
        // Simple magic values

        static let ImageExtension = ".png"
        static let CachesRelativeDirectory = "Images"

        // Computed magic values

        static let CachesAbsolutePath: String = {
            let cachesMainDirectory = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true).first as! String
            let absolutePath = cachesMainDirectory.stringByAppendingPathComponent(Defaults.CachesRelativeDirectory)

            return absolutePath
        }()
    }

    // MARK: - Internal structure

    private var cache = NSCache()

    // MARK: - Public methods

    func addImageWithIdentifier(image: UIImage?, identifier: String) {
        let path = pathForIdentifier(identifier)

        if let image = image {
            cache.setObject(image, forKey: identifier)
            UIImagePNGRepresentation(image).writeToFile(path, atomically: true)
        } else {
            cache.removeObjectForKey(path)
            NSFileManager.defaultManager().removeItemAtPath(path, error: nil)
        }
    }

    func getImageWithIdentifier(identifier: String) -> UIImage? {
        var result: UIImage?

        if identifier != "" {
            if let image = cache.objectForKey(identifier) as? UIImage {
                result = image
            } else {
                let path = pathForIdentifier(identifier)
                if let data = NSData(contentsOfFile: path) {
                    result = UIImage(data: data)
                }
            }
        }

        return result
    }

    // MARK: - Auxiliary private methods

    func pathForIdentifier(identifier: String) -> String {
        return Defaults.CachesAbsolutePath.stringByAppendingPathComponent(identifier)
    }
}