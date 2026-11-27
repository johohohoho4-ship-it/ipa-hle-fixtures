//
//  Item.swift
//  Todoey
//
//  Created by Rajan Chauhan on 12/10/2019.
//  Copyright © 2019 Rajan Chauhan. All rights reserved.
//

import Foundation


final class Item: Encodable, Decodable {
    
    var title : String = ""
    var done : Bool = false
    
    init(title : String) {
        self.title = title
    }
    
}
