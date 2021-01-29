//
//  File.swift
//  
//
//  Created by basalaev on 29.01.2021.
//

import Foundation

public protocol RequestBuilderPlugin {
    func prepare(requestHolder: URLRequestHolder)
}
