//
//  UserCD+CoreDataProperties.swift
//  KerdoIndexTRAINER
//
//  Created by Вячеслав Переяслов on 30.07.2023.
//
//

import Foundation
import CoreData


extension UserCD {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserCD> {
        return NSFetchRequest<UserCD>(entityName: "UserCD")
    }

    @NSManaged public var pass: String?

}

extension UserCD : Identifiable {

}
