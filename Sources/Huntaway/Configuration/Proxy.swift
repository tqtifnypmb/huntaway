//
//  Proxy.swift
//  XcodeProject
//
//  Created by Tqtifnypmb on 3/12/16.
//  Copyright © 2016 Tqtifnypmb. All rights reserved.
//

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