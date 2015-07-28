//
//  ImagesCache.swift
//  VirtualTourist
//
//  Created by Oleksandr Iaroshenko on 28.07.15.
//  Copyright (c) 2015 Oleksandr Iaroshenko. All rights reserved.
//

import Foundation

class ImagesCache {

    private var cache = NSCache()

    func addImageToCache(image: FlickrPhoto) {

    }

    func getImageFromCache(url: String) -> FlickrPhoto { // -> UIImage {

        return FlickrPhoto(title: "", urlString: "")
    }
}