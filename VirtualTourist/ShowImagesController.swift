//
//  ShowImagesController.swift
//  VirtualTourist
//
//  Created by Oleksandr Iaroshenko on 07.08.15.
//  Copyright (c) 2015 theconquerorkh. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class ShowImagesController: ImagesController {

    // MARK: - Magic values

    private struct Defaults {
        static let StandardAlpha: CGFloat = 1.0
        static let SelectedAlpha: CGFloat = 0.1
    }

    // MARK: - Auxiliary methods

    override func markCell(cell: ImageCollectionViewCell, selected: Bool) {
        cell.imageView.alpha = selected ? Defaults.SelectedAlpha : Defaults.StandardAlpha
    }
}