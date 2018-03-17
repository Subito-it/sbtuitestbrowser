//
// Model.swift
//
// Copyright (C) 2016 Subito.it S.r.l (www.subito.it)
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.


import Foundation

protocol FailableItem {
    func hasFailure() -> Bool
    func hasCrashed() -> Bool
}

// Slightly lame solution, but simple and working enough

class ListItem {
    weak var previous: ListItem?
    weak var next: ListItem?
    
    weak var previousFailed: ListItem?
    weak var nextFailed: ListItem?
}

extension Sequence where Iterator.Element: ListItem, Iterator.Element: FailableItem {
    
    func listify() {
        var previousItem: Iterator.Element?
        var iterator = self.makeIterator()
        while let item = iterator.next() {
            previousItem?.next = item
            item.previous = previousItem
            previousItem = item
        }
        
        listifyFailed()
    }
    
    private func listifyFailed() {
        var lastFailedItem: Iterator.Element?
        var iterator = self.makeIterator()
        
        while let item = iterator.next() {
            item.previousFailed = lastFailedItem
            if item.hasFailure() {
                lastFailedItem = item
            }
            
            var iterator2 = iterator
            while let item2 = iterator2.next() {
                if item2.hasFailure() {
                    item.nextFailed = item2
                    break
                }
            }
        }
    }
}
