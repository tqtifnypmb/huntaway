//
//  Configuration.swift
//  XcodeProject
//
//  Created by Tqtifnypmb on 3/11/16.
//  Copyright © 2016 Tqtifnypmb. All rights reserved.
//

import Foundation

public class Configuration {
    
    private var config: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
    private var changed = false
    private var proxySettings: Proxy = Proxy()
    private unowned let client: HTTPClient
    init(client: HTTPClient) {
        self.client = client
    }
    
    public var proxy: Proxy {
        return self.proxySettings
    }
    
    /// The timeout interval to use when waiting for additional data. 
    ///
    /// - Parameters:
    ///     - requestsTimeout:  The request timeout interval controls how long (in seconds) a task should wait for additional data to arrive before giving up
    ///     - resourcesTimeout: The resource timeout interval controls how long (in seconds) to wait for an entire resource to transfer before giving up
    public func setTimeout(requestsTimeout: NSTimeInterval?, resourcesTimeout: NSTimeInterval?) -> Configuration {
        self.changed = true
        self.config.timeoutIntervalForRequest = requestsTimeout ?? self.config.timeoutIntervalForRequest
        self.config.timeoutIntervalForResource = resourcesTimeout ?? self.config.timeoutIntervalForResource
        return self
    }
    
    /// A Boolean value that determines whether connections should be made over a cellular network.
    public func cellularAccess(allow: Bool) -> Configuration {
        self.changed = true
        self.config.allowsCellularAccess = allow
        return self
    }
    
    /// The network service type provides a hint to the operating system about what the underlying traffic is used for
    public func networkServiceType(type: NSURLRequestNetworkServiceType) -> Configuration {
        self.changed = true
        self.config.networkServiceType = type
        return self
    }
    
    /// Set policy
    /// - Parameters:
    ///     - cachePolicy:  Determines when to return a response from the cache
    ///     - cookieAcceptPolicy:  Determines the cookie accept policy for all tasks within sessions
    public func setPolicy(cachePolicy: NSURLRequestCachePolicy?, cookieAcceptPolicy: NSHTTPCookieAcceptPolicy?) -> Configuration {
        self.changed = true
        self.config.requestCachePolicy = cachePolicy ?? self.config.requestCachePolicy
        self.config.HTTPCookieAcceptPolicy = cookieAcceptPolicy ?? self.config.HTTPCookieAcceptPolicy
        return self
    }
    
    public func setSharedContainerIdeitifier(identifier: String) -> Configuration {
        self.changed = true
        self.config.sharedContainerIdentifier = identifier
        return self
    }
    
    /// Determines whether requests should contain cookies from the cookie store
    public func shouldSetCookies(allow: Bool) -> Configuration {
        self.changed = true
        self.config.HTTPShouldSetCookies = allow
        return self
    }
    
    public func usePipelining(allow: Bool) -> Configuration {
        self.changed = true
        self.config.HTTPShouldUsePipelining = allow
        return self
    }
    
    /// Additional headers that are added to all tasks within session
    public func additionalHeaders(headers: [String: String]) -> Configuration {
        self.changed = true
        self.config.HTTPAdditionalHeaders = headers
        return self
    }
    
    /// The cookie store for storing cookies within this session
    ///
    /// To disable cookie storage, set this property to nil
    public func setCookieStorage(cookieStorage: NSHTTPCookieStorage) -> Configuration {
        self.changed = true
        self.config.HTTPCookieStorage = cookieStorage
        return self
    }
    
    /// The TLS protocol version that the client should request when making connections in this session
    public func setSSLVersion(min: SSLProtocol?, max: SSLProtocol?) -> Configuration {
        self.changed = true
        self.config.TLSMinimumSupportedProtocol = min ?? self.config.TLSMinimumSupportedProtocol
        self.config.TLSMaximumSupportedProtocol = max ?? self.config.TLSMaximumSupportedProtocol
        return self
    }
    
    /// The maximum number of simultaneous connections to make to a given host
    public func setMaxConnectionPerHost(num: Int) -> Configuration {
        self.changed = true
        self.config.HTTPMaximumConnectionsPerHost = num
        return self
    }
    
    /// Apply the configuration just set
    public func apply() {
        guard self.changed || self.proxy.changed else {
            return
        }
        self.changed = false
        self.proxy.changed = false
        if let proxySettings = self.proxy.proxy {
            self.config.connectionProxyDictionary = proxySettings
        }
        self.client.applyConfig(self.config)
    }
    
    public class Proxy {
        var changed = false
        private var proxySettings: [NSObject: AnyObject] = [:]
        init() {
        }
        
        /// Set hostname or IP number of the proxy host
        public func setHost(name: String) -> Proxy {
            self.changed = true
            self.proxySettings[kCFProxyHostNameKey] = name
            return self
        }
        
        /// Set port that should be used to contact the proxy
        public func setPort(port: UInt16) -> Proxy {
            self.changed = true
            self.proxySettings[kCFProxyPortNumberKey] = NSNumber(unsignedShort: port)
            return self
        }
        
        /// Set the password to be used when contacting the proxy
        public func setPasswd(pwd: String) -> Proxy {
            self.changed = true
            self.proxySettings[kCFProxyPasswordKey] = pwd
            return self
        }
        
        /// Set the username to be used when contacting the proxy
        public func setUserName(user: String) -> Proxy {
            self.changed = true
            self.proxySettings[kCFProxyUsernameKey] = user
            return self
        }
        
        /// Specifies the type of proxy
        public func setProxyType(type: ProxyType) -> Proxy {
            self.changed = true
            switch type {
            case .FTP:
                self.proxySettings[kCFProxyTypeKey] = kCFProxyTypeFTP
            case .HTTP:
                self.proxySettings[kCFProxyTypeKey] = kCFProxyTypeHTTP
            case .HTTPS:
                self.proxySettings[kCFProxyTypeKey] = kCFProxyTypeHTTPS
            case .SOCKS:
                self.proxySettings[kCFProxyTypeKey] = kCFProxyTypeSOCKS
            }
            return self
        }
        
        var proxy: [NSObject: AnyObject]? {
            guard !self.proxySettings.isEmpty else {
                return nil
            }
            return self.proxySettings
        }
    }
    
    public enum ProxyType {
        case FTP
        case HTTP
        case HTTPS
        case SOCKS
    }
}