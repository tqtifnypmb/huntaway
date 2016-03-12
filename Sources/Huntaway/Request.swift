//
//  Request.swift
//  XcodeProject
//
//  Created by Tqtifnypmb on 3/9/16.
//  Copyright © 2016 Tqtifnypmb. All rights reserved.
//

import Foundation

public class Request {
    
    private let url: NSURL
    private let method: HTTPClient.Method
    
    // auth
    var basic: (String, String)?
    var digest: (String, String)?
    
    var HTTPCookies: [String: String]? = nil
    var HTTPHeaders: [String: String]? = nil
    
    init(url: NSURL, method: HTTPClient.Method) {
        self.url = url
        self.method = method
    }
    
    public var allowRedirect: Bool = true
    public var timeoutInterval: NSTimeInterval = 240.0
    public var cachePolicy: NSURLRequestCachePolicy = .UseProtocolCachePolicy
    public var cellularAccess = true
    public var networkServiceType: NSURLRequestNetworkServiceType = .NetworkServiceTypeDefault
    public var shouldHandleCookies = true
    public var rememberRedirectHistory = false
    public var maxRedirect = Int.max
    
    var current_redirect_count = 0
    var basicAuthSettings: NSURLCredential? {
        guard let basicSettings = self.basic else { return nil }
        
        let credential = NSURLCredential(user: basicSettings.0, password: basicSettings.1, persistence: .None)
        return credential
    }
    
    var diegestAuthSettings: NSURLCredential? {
        guard let digestSettings = self.digest else { return nil }
        
        let credential = NSURLCredential(user: digestSettings.0, password: digestSettings.1, persistence: .None)
        return credential
    }
    
    /// Indicate whether data of this request send in stream mode.
    /// If you want to send a file that's too big to be read into memory
    /// you should turn this on.
    public var stream: Bool = false
    
    /// Indicate whether this request should be handled by a session that
    /// outlast this life.
    public var outlast: Bool = false
    
    /// Data that's going to be sent.
    public var data: NSData? = nil
    
    /// File that's going to be sent
    public var filePath: NSURL? = nil
    
    public var URL: NSURL {
        return self.url
    }

    public var HTTPMethod: HTTPClient.Method {
        return self.method
    }
    
    public func setCookies(cookies: [String: String]) {
        self.HTTPCookies = self.HTTPCookies ?? [:]
        for (key, value) in cookies {
            self.HTTPCookies![key] = value
        }
    }
    
    public func setHeaders(headers: [String: String]) {
        self.HTTPHeaders = self.HTTPHeaders ?? [:]
        for (key, value) in headers {
            
            // Users're not allow to set these headers
            // see [NSURLSessionConfiguration]
            switch key.uppercaseString {
            case "AUTHORIZATION":
                continue
            case "CONNECTION":
                continue
            case "HOST":
                continue
            case "WWW-AUTHENTICATE":
                continue
                
            default:
                self.HTTPHeaders![key] = value
            }
        }
    }
    
    public func basicAuth(user user: String, passwd: String) {
        self.basic = (user, passwd)
    }
    
    public func digestAuth(user user: String, passwd: String) {
        self.digest = (user, passwd)
    }
}

