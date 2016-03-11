//
//  Utils.swift
//  XcodeProject
//
//  Created by Tqtifnypmb on 3/10/16.
//  Copyright © 2016 Tqtifnypmb. All rights reserved.
//

import Foundation

final class Utils {
    static func createNSURLRequest(request: Request, session: NSURLSession) -> NSURLRequest {
        let req = NSMutableURLRequest(URL: request.URL, cachePolicy: request.cachePolicy, timeoutInterval: request.timeoutInterval)
        req.networkServiceType = request.networkServiceType
        req.allowsCellularAccess = request.cellularAccess
        
        switch request.HTTPMethod {
        case .GET:
            req.HTTPMethod = "GET"
            
        case .POST:
            req.HTTPMethod = "POST"
            
        case .DOWNLOAD:
            req.HTTPMethod = "GET"
            
        case .PUT:
            req.HTTPMethod = "PUT"
            
        case .DELETE:
            req.HTTPMethod = "DELETE"
            
        case .HEAD:
            req.HTTPMethod = "HEAD"
            
        case .PATCH:
            req.HTTPMethod = "PATCH"
        }
        
        if let headers = request.HTTPHeaders {
            if req.allHTTPHeaderFields == nil {
                req.allHTTPHeaderFields = headers
            } else {
                for (key, value) in headers {
                    req.allHTTPHeaderFields![key] = value
                }
            }
        }
        
        if let cookies = request.HTTPCookies {
            let cookies = Utils.createNSHTTPCookies(cookies, url: request.URL)
            session.configuration.HTTPCookieStorage?.setCookies(cookies, forURL: request.URL, mainDocumentURL: nil)
        }
        
        return req
    }
    
    private static func createNSHTTPCookies(cookies: [String: String], url: NSURL) -> [NSHTTPCookie] {
        var ret: [NSHTTPCookie] = []
        for (key, value) in cookies {
            let properties = [
                NSHTTPCookieName: key,
                NSHTTPCookieValue: value,
                NSHTTPCookieOriginURL: url,
                NSHTTPCookiePath: url.path ?? "/"
            ]
            guard let toAdd = NSHTTPCookie(properties: properties) else {
                continue
            }
            ret.append(toAdd)
        }
        return ret
    }
    
    static private var once = dispatch_once_t()
    static func randomIdentifier() -> String {
        dispatch_once(&once) {
            srandom(UInt32(time(nil)))
        }
        
        let table = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let idLen = 15
        var ret = ""
        ret.reserveCapacity(idLen)
        for _ in 0 ..< idLen {
            let index = random() % 62
            ret +=  String(table[table.startIndex.advancedBy(index)])
        }
        
        return ret
    }
    
    static func validScheme(url: NSURL) -> Bool {
        let scheme = url.scheme.uppercaseString
        return scheme == "HTTP" || scheme == "HTTPS"
    }
}