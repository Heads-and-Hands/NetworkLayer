//
//  File.swift
//  
//
//  Created by basalaev on 29.01.2021.
//

import Foundation

protocol RequestBuilderPlugin {
    func prepare(requestHolder: URLRequestHolder)
}
