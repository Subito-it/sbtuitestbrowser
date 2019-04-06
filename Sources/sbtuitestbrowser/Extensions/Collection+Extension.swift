//
//  Collection+Extension.swift
//  sbtuitestbrowser
//
//  Created by tomas on 05/04/2019.
//

import Foundation

extension Collection {    
    // Returns the element at the specified index if it is within bounds, otherwise nil
    subscript (safe index: Index) -> Iterator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
