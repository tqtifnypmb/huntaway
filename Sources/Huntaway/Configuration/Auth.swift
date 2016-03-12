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
    
    // FIXME: Is this really necessary??
    private var memoryOnly = false
    
    // Determin whether the auth information is only store in memory
    public func storeInMemoryOnly(s: Bool) -> Auth {
        self.memoryOnly = s
        return self
    }
    
    /// Use HTTP basic authentication for *url*
    public func basic(user user: String, passwd: String, url: NSURL, _ realm: String? = nil) -> Auth {
        guard let host = url.host else { return self }  // FIXME: Just ignore error silently??
        
        self.config.changed = true
        let space = NSURLProtectionSpace(host: host, port: url.port?.integerValue ?? 0, `protocol`: NSURLProtectionSpaceHTTP, realm: realm, authenticationMethod: NSURLAuthenticationMethodHTTPBasic)
        let credential = NSURLCredential(user: user, password: passwd, persistence: .ForSession)
        self.authSettings = self.authSettings ?? [:]
        self.authSettings?[credential] = space
        
        return self
    }
    
    /// Use HTTP digest authentication for *url*
    public func digest(user user: String, passwd: String, url: NSURL, _ realm: String? = nil) -> Auth {
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
        
        let storage = NSURLCredentialStorage.sharedCredentialStorage()
        for (credential, protectSpace) in settings {
            storage.setCredential(credential, forProtectionSpace: protectSpace)
        }
        self.authSettings = nil
        return storage
    }
}