//
//  Observable.swift
//  SwiftyLocations
//
//  Created by Basem Emara on 3/12/17.
//  Copyright © 2017 Zamzam Inc. All rights reserved.
//

import Foundation

public struct Observable<T> {
    let id: UUID
    let handler: T
    
    public init(_ id: UUID = UUID(), handler: T) {
        self.id = id
        self.handler = handler
    }
}

extension Observable: Equatable {
     public static func ==(lhs: Observable, rhs: Observable) -> Bool {
        return lhs.id == rhs.id
    }
}
