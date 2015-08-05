//
//  ImageCollectionViewCell.swift
//  VirtualTourist
//
//  Created by Oleksandr Iaroshenko on 28.07.15.
//  Copyright (c) 2015 Oleksandr Iaroshenko. All rights reserved.
//

import UIKit

class ImageCollectionViewCell: UICollectionViewCell {

    // MARK: - Actions and Outlets

    @IBOutlet weak var imageView: UIImageView! {
        didSet {
            setImage()
        }
    }

    // MARK: - Properties

    var photo: Photo? {
        didSet {
            setImage()
        }
    }

    // MARK: - Auxiliary methods

    private func setImage() {
        if let imageView = imageView, photo = photo {
            photo.loadImage { image in
                if self.photo?.id == photo.id {
                    dispatch_async(dispatch_get_main_queue()) {
                        imageView.image = image
                    }
                }
            }
        }
    }
}