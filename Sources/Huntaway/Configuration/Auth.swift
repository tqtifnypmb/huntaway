//
//  Auth.swift
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