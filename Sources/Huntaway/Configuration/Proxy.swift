//
//  Proxy.swift
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

public class Proxy {
    private unowned let config: Configuration
    private var proxySettings: [NSObject: AnyObject]?
    init(config: Configuration) {
        self.config = config
    }
    
    /// Apply changed
    public func apply() {
        self.config.apply()
    }
    
    /// Set hostname or IP number of the proxy host
    public func setHost(name: String) -> Proxy {
        self.proxySettings = self.proxySettings ?? [:]
        self.config.changed = true
        self.proxySettings?[kCFProxyHostNameKey] = name
        return self
    }
    
    /// Set port that should be used to contact the proxy
    public func setPort(port: UInt16) -> Proxy {
        self.proxySettings = self.proxySettings ?? [:]
        self.config.changed = true
        self.proxySettings?[kCFProxyPortNumberKey] = NSNumber(unsignedShort: port)
        return self
    }
    
    /// Set the password to be used when contacting the proxy
    public func setPasswd(pwd: String) -> Proxy {
        self.proxySettings = self.proxySettings ?? [:]
        self.config.changed = true
        self.proxySettings?[kCFProxyPasswordKey] = pwd
        return self
    }
    
    /// Set the username to be used when contacting the proxy
    public func setUserName(user: String) -> Proxy {
        self.proxySettings = self.proxySettings ?? [:]
        self.config.changed = true
        self.proxySettings?[kCFProxyUsernameKey] = user
        return self
    }
    
    /// Specifies the type of proxy
    public func setProxyType(type: ProxyType) -> Proxy {
        self.proxySettings = self.proxySettings ?? [:]
        self.config.changed = true
        switch type {
        case .FTP:
            self.proxySettings?[kCFProxyTypeKey] = kCFProxyTypeFTP
        case .HTTP:
            self.proxySettings?[kCFProxyTypeKey] = kCFProxyTypeHTTP
        case .HTTPS:
            self.proxySettings?[kCFProxyTypeKey] = kCFProxyTypeHTTPS
        case .SOCKS:
            self.proxySettings?[kCFProxyTypeKey] = kCFProxyTypeSOCKS
        }
        return self
    }
    
    var proxy: [NSObject: AnyObject]? {
        guard let settings = self.proxySettings else { return nil }
        self.proxySettings = nil
        return settings
    }
}

public enum ProxyType {
    case FTP
    case HTTP
    case HTTPS
    case SOCKS
}