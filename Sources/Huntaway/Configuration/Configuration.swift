//
//  Configuration.swift
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

public class Configuration {
    
    private var config: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
    var changed = false
    private lazy var proxySettings: Proxy = { return Proxy(config: self) }()
    private lazy var authSettings: Auth = { return Auth(config: self) }()
    private unowned let client: HTTPClient
    init(client: HTTPClient) {
        self.client = client
    }
    
    public var proxy: Proxy {
        return self.proxySettings
    }
    
    public var auth: Auth {
        return self.authSettings
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
        guard self.changed else { return }
        self.changed = false
        if let proxySettings = self.proxy.proxy {
            self.config.connectionProxyDictionary = proxySettings
        }
        
        if let authSettings = self.auth.auth {
            self.config.URLCredentialStorage = authSettings
        }
        self.client.applyConfig(self.config)
    }
}