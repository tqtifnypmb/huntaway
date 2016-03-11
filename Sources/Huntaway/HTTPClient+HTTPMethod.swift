//
//  HTTPClient+HTTPMethod.swift
//  XcodeProject
//
//  Created by Tqtifnypmb on 3/10/16.
//  Copyright © 2016 Tqtifnypmb. All rights reserved.
//

import Foundation

extension HTTPClient {
    public enum Method{
        case GET
        case PUT
        case POST
        case DELETE
        case DOWNLOAD
        case HEAD
        case PATCH
    }
    
    static private var sharedInstance: HTTPClient? = nil
    static public func sharedHTTPClient() -> HTTPClient {
        guard let instance = sharedInstance else {
            self.sharedInstance = HTTPClient()
            return self.sharedInstance!
        }
        return instance
    }
}