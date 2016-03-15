//
//  Utils.swift
//  Huntaway
//
//  The MIT License (MIT)
//
//  Copyright (c) 2016 tqtifnypmb
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:

//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.

//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

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
            guard let toAdd = NSHTTPCookie(properties: properties) else { continue }
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