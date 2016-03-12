//
//  Auth.swift
//  XcodeProject
//
//  Created by Tqtifnypmb on 3/12/16.
//  Copyright © 2016 Tqtifnypmb. All rights reserved.
//

import Foundation

public class Auth {
    private unowned let config: Configuration
    private var authSettings: [NSURLCredential: NSURLProtectionSpace]? = nil
    init(config: Configuration) {
        self.config = config
    }
    
    public var storeInMemoryOnly = false
    
    /// Use HTTP basic authentication for *url*
    public func basic(user: String, passwd: String, url: NSURL, _ realm: String? = nil) -> Auth {
        guard let host = url.host else { return self }  // FIXME: Just ignore error silently??
        
        self.config.changed = true
        let space = NSURLProtectionSpace(host: host, port: url.port?.integerValue ?? 0, `protocol`: NSURLProtectionSpaceHTTP, realm: realm, authenticationMethod: NSURLAuthenticationMethodHTTPBasic)
        let credential = NSURLCredential(user: user, password: passwd, persistence: .ForSession)
        self.authSettings = self.authSettings ?? [:]
        self.authSettings?[credential] = space
        
        return self
    }
    
    /// Use HTTP digest authentication for *url*
    public func digest(user: String, passwd: String, url: NSURL, _ realm: String? = nil) -> Auth {
        guard let host = url.host else { return self }  // FIXME: Just ignore error silently??
        
        self.config.changed = true
        let space = NSURLProtectionSpace(host: host, port: url.port?.integerValue ?? 0, `protocol`: NSURLProtectionSpaceHTTP, realm: realm, authenticationMethod: NSURLAuthenticationMethodHTTPDigest)
        let credential = NSURLCredential(user: user, password: passwd, persistence: .ForSession)
        self.authSettings = self.authSettings ?? [:]
        self.authSettings?[credential] = space
        
        return self
    }
    
    /// Apply the configuration just set
    public func apply() {
        self.config.apply()
    }
    
    var auth: NSURLCredentialStorage? {
        guard let settings = self.authSettings else { return nil }
        
        var storage = NSURLCredentialStorage.sharedCredentialStorage()
        if self.storeInMemoryOnly {
            storage = NSURLCredentialStorage()
        }
        for (credential, protectSpace) in settings {
            storage.setCredential(credential, forProtectionSpace: protectSpace)
        }
        self.authSettings = nil
        return storage
    }
}