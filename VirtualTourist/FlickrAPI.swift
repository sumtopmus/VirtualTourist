//
//  FlickrAPI.swift
//  VirtualTourist
//
//  Created by Oleksandr Iaroshenko on 28.07.15.
//  Copyright (c) 2015 Oleksandr Iaroshenko. All rights reserved.
//

import Foundation

class FlickrAPI {

    // MARK: - Singleton

    static let sharedInstance = FlickrAPI()

    private init() {
    }

    // MARK: - Public API Access

    // Returns random page (<=100 photos)
    func searchPhotosByCoordinates(#latitude: Double, longitude: Double, completion: ((photos: [FlickrPhoto]) -> Void)?) {
        var parameters = Defaults.GetPhotosParameters
        parameters[HTTPKeys.BoundingBox] = constructBoundingBoxParameterFromLatitude(latitude, andLongitude: longitude)

        searchPhotosAndPickRandomPage(parameters: parameters, completion: completion)
    }

    // MARK: - Internal API Access (HTTP Requests)

    // Create request
    private func createRequest(parameters: [String : String]) -> NSMutableURLRequest {
        let url = HTTP.constructHTTPCall(Defaults.BaseURL, parameters: parameters)

        return NSMutableURLRequest(URL: url)
    }

    // Perform request to HTTP server
    private func performRequest(request: NSMutableURLRequest, completion: ((parsedJSONData: AnyObject?) -> Void)?) {
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {data, response, requestError in
            if let error = requestError {
                println("Error: Could not complete the request \(error)")
            } else {
                let parsedData: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: nil)

                completion?(parsedJSONData: parsedData)
            }
        }

        task.resume()
    }

    // MARK: - JSON Parsing

    private func parsePhotosArrayMetadataWithJSONData(data: AnyObject?) -> (pagesCount: Int, photosCount: Int) {
        var result = (pagesCount: 0, photosCount: 0)

        if let dataDictionary = data as? [String : AnyObject],
            photos = dataDictionary[JSONKeys.Photos] as? [String : AnyObject],
            pagesCount = photos[JSONKeys.PagesCount] as? Int,
            photosCount = photos[JSONKeys.PhotosCount] as? Int {
                result.pagesCount = pagesCount
                result.photosCount = photosCount
        }
        
        return result
    }

    private func parsePhotosWithJSONData(data: AnyObject?) -> [FlickrPhoto] {
        var result = [FlickrPhoto]()

        if let dataDictionary = data as? [String : AnyObject],
            photos = dataDictionary[JSONKeys.Photos] as? [String : AnyObject],
            photoArray = photos[JSONKeys.PhotoArray] as? [[String : AnyObject]] {
            for photo in photoArray {
                if let title = photo[JSONKeys.Title] as? String,
                    url = photo[JSONKeys.URL] as? String {
                        result.append(FlickrPhoto(title: title, urlString: url))
                }
            }
        }

        return result
    }

    // MARK: - Auxiliary methods

    private func searchPhotosAndPickRandomPage(var #parameters: [String : String], completion: ((photos: [FlickrPhoto]) -> Void)?) {
        let request = createRequest(parameters)
        performRequest(request) { jsonData in
            let count = self.parsePhotosArrayMetadataWithJSONData(jsonData)
            let maximalPhoto = min(Defaults.MaxPhotosCount, count.photosCount)
            let randomPageindex = (Int(arc4random_uniform(UInt32(maximalPhoto))) + Defaults.PhotosOnPage) / Defaults.PhotosOnPage

            parameters[HTTPKeys.Page] = "\(randomPageindex)"

            self.performRequest(self.createRequest(parameters)) { jsonData in
                println("Log: In searchPhotosAndPickRandomPage method, jsonData is obtained.")

                let photos = self.parsePhotosWithJSONData(jsonData)
                completion?(photos: photos)
            }
        }
    }

    private func constructBoundingBoxParameterFromLatitude(latitude: Double, andLongitude longitude: Double) -> String {
        let boundingBoxCorners = [
            "\(longitude - Defaults.BoundingBoxHalfSize)",
            "\(latitude - Defaults.BoundingBoxHalfSize)",
            "\(longitude + Defaults.BoundingBoxHalfSize)",
            "\(latitude + Defaults.BoundingBoxHalfSize)"]

        return join(",", boundingBoxCorners)
    }
}

// MARK: - Magic values

extension FlickrAPI {

    // Keys for Flickr API HTTP calls
    private struct HTTPKeys {
        static let Method = "method"
        static let APIKey = "api_key"
        static let Text = "text"
        static let BoundingBox = "bbox"
        static let Page = "page"
        static let GalleryID = "gallery_id"
        static let Extras = "extras"
        static let SafeSearch = "safe_search"
        static let Format = "format"
        static let NoJSONCallback = "nojsoncallback"
    }

    // Flickr API Methods
    private struct APIMethods {
        static let GetPhotos = "flickr.photos.search"
        static let GetPhotosFromGallery = "flickr.galleries.getPhotos"
    }

    // Dictionary keys for JSON results
    private struct JSONKeys {
        static let Photos = "photos"
        static let PagesCount = "pages"
        static let PhotosCount = "total"
        static let PhotoArray = "photo"
        static let Title = "title"
        static let URL = "url_m"
    }

    // General constants
    private struct Defaults {
        static let BaseURL = "https://api.flickr.com/services/rest/"
        static let APIKey = "b95f2030b0216710e7357e1b912cdb22"

        static let GetPhotosParameters = [
            HTTPKeys.Method : APIMethods.GetPhotos,
            HTTPKeys.APIKey : Defaults.APIKey,
            HTTPKeys.SafeSearch : Defaults.SafeSearch,
            HTTPKeys.Extras : Defaults.Extras,
            HTTPKeys.Format : Defaults.Format,
            HTTPKeys.NoJSONCallback : Defaults.NoJSONCallback
        ]

        static let SafeSearch = "1"
        static let Extras = "url_m"
        static let Format = "json"
        static let NoJSONCallback = "1"

        static let BoundingBoxHalfSize = 0.1

        static let MaxPhotosCount = 4000
        static let MaxPagesCount = 40
        static let PhotosOnPage = 100
    }
}