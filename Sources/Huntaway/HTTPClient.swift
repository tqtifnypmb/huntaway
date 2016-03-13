//
//  HTTPClient.swift
//  XcodeProject
//
//  Created by Tqtifnypmb on 3/9/16.
//  Copyright © 2016 Tqtifnypmb. All rights reserved.
//

import Foundation

public final class HTTPClient {

    private lazy var defaultSession: Session = {
        return Session(config: NSURLSessionConfiguration.defaultSessionConfiguration(), client: self)
    }()
    private var outlastSession: [Session] = []
    private var decaySession: [Session] = []
    public init() {
    }
    
    private lazy var configuration: Configuration = { return Configuration(client: self) }()
    public var config: Configuration {
        return self.configuration
    }
    
    /// Send a *get* requst
    ///
    /// - Parameters:
    ///     - url:  the *url* address
    ///     - params:  query string
    ///
    /// - Returns: *nil* if *url* is not a valid URL, otherwise return a *response*
    public func get(url: String, _ params: [String: String]? = nil) -> Response? {
        var copy = url
        if let params = params {
            copy += "?"
            for (key, name) in params {
                copy += key + "=" + name
                copy += "&"
            }
            copy.removeAtIndex(copy.endIndex.predecessor())
        }
        guard let encodedURL = NSURL(string: copy, relativeToURL: nil) else { return nil }
        return self.get(encodedURL)
    }
    
    /// Send a *get* requst
    ///
    /// - Parameters:
    ///     - url:  the *url* address
    ///
    /// - Returns: *nil* if *url* is not a valid URL, otherwise return a *response*
    public func get(url: NSURL) -> Response? {
        guard let request = self.prepareRequest(url, method: .GET) else { return nil }
        return self.send(request)
    }
    
    /// Send a *head* requst
    ///
    /// - Parameters:
    ///     - url:  the *url* address
    ///     - params:  query string
    ///
    /// - Returns: *nil* if *url* is not a valid URL, otherwise return a *response*
    public func head(url: String, _ params: [String: String]? = nil) -> Response? {
        var copy = url
        if let params = params {
            copy += "?"
            for (key, name) in params {
                copy += key + "=" + name
                copy += "&"
            }
            copy.removeAtIndex(copy.endIndex.predecessor())
        }
        guard let encodedURL = NSURL(string: copy, relativeToURL: nil) else { return nil }
        return self.get(encodedURL)
    }
    
    /// Send a *head* requst
    ///
    /// - Parameters:
    ///     - url:  the *url* address
    ///
    /// - Returns: *nil* if *url* is not a valid URL, otherwise return a *response*
    public func head(url: NSURL) -> Response? {
        guard let request = self.prepareRequest(url, method: .GET) else { return nil }
        return self.send(request)
    }
    
    /// Send a *post* requst
    ///
    /// - Parameters:
    ///     - url:      the *url* address
    ///     - data:     data to post
    ///     - stream:   whether data be sent in stream mode or not
    ///
    /// - Returns: *nil* if *url* is not a valid URL, otherwise return a *response*
    public func post(url: String, data: NSData, _ stream: Bool = false) -> Response? {
        guard let encodedURL = NSURL(string: url, relativeToURL: nil) else { return nil }
        return self.post(encodedURL, data: data, stream)
    }
    
    /// Send a *post* requst
    ///
    /// - Parameters:
    ///     - url:      the *url* address
    ///     - data:     data to post
    ///     - stream:   whether data be sent in stream mode or not
    ///
    /// - Returns: *nil* if *url* is not a valid URL, otherwise return a *response*
    public func post(url: NSURL, data: NSData, _ stream: Bool = false) -> Response? {
        guard let request = self.prepareRequest(url, method: .POST) else { return nil }
        request.stream = stream
        request.data = data
        return self.send(request)
    }
    
    /// Send a *post* requst.
    ///
    /// - Parameters:
    ///     - url:      the *url* address
    ///     - file:     file to post
    ///     - stream:   whether file be sent in stream mode or not
    ///     - outlast:  request is sent through background session or not
    ///
    /// - Returns: *nil* if *url* is not a valid URL or *file* is not exist, otherwise return a *response*
    public func post(url: String, file: NSURL, _ stream: Bool = false, _ outlast: Bool = false) -> Response? {
        guard let encodedURL = NSURL(string: url, relativeToURL: nil) else { return nil }
        return self.post(encodedURL, file: file, outlast, stream)
    }
    
    /// Send a *post* requst
    ///
    /// - Parameters:
    ///     - url:      the *url* address
    ///     - file:     file to post
    ///     - stream:   whether file be sent in stream mode or not
    ///     - outlast:  indicate whether request is sent through background session or not
    ///
    /// - Returns: *nil* if *url* is not a valid URL or *file* is not exist, otherwise return a *response*
    public func post(url: NSURL, file: NSURL, _ stream: Bool = false, _ outlast: Bool = false) -> Response? {
        guard NSFileManager.defaultManager().fileExistsAtPath(file.absoluteString) else { return nil }
        guard let request = self.prepareRequest(url, method: .POST) else { return nil }
        
        request.outlast = outlast
        request.stream = stream
        request.filePath = file
        return self.send(request)
    }
    
    /// Send a *post* requst
    ///
    /// - Parameters:
    ///     - url:      the *url* address
    ///     - data:     data to post
    ///     - stream:   whether data be sent in stream mode or not
    ///
    /// - Returns: *nil* if *url* is not a valid URL, otherwise return a *response*
    public func post(url: String, data: String, _ stream: Bool = false) -> Response? {
        guard let encodedURL = NSURL(string: url, relativeToURL: nil) else { return nil }
        return self.post(encodedURL, data: data, stream)
    }
    
    /// Send a *post* requst
    ///
    /// - Parameters:
    ///     - url:      the *url* address
    ///     - data:     data to post
    ///     - stream:   whether data be sent in stream mode or not
    ///
    /// - Returns: *nil* if *url* is not a valid URL, otherwise return a *response*
    public func post(url: NSURL, data: String, _ stream: Bool = false) -> Response? {
        guard let request = self.prepareRequest(url, method: .POST) else { return nil }
        request.stream = stream
        request.data = data.dataUsingEncoding(NSUTF8StringEncoding)

        return self.send(request)
    }
    
    /// Send a *put* requst
    ///
    /// - Parameters:
    ///     - url:      the *url* address
    ///     - data:     data to post
    ///     - stream:   whether data be sent in stream mode or not
    ///
    /// - Returns: *nil* if *url* is not a valid URL, otherwise return a *response*
    public func put(url: String, data: NSData, _ stream: Bool = false) -> Response? {
        guard let encodedURL = NSURL(string: url, relativeToURL: nil) else { return nil }
        return self.put(encodedURL, data: data, stream)
    }
    
    /// Send a *put* requst
    ///
    /// - Parameters:
    ///     - url:      the *url* address
    ///     - data:     data to post
    ///     - stream:   whether data be sent in stream mode or not
    ///
    /// - Returns: *nil* if *url* is not a valid URL, otherwise return a *response*
    public func put(url: NSURL, data: NSData, _ stream: Bool = false) -> Response? {
        guard let request = self.prepareRequest(url, method: .PUT) else { return nil }
        request.stream = stream
        request.data = data
        return self.send(request)
    }
    
    /// Send a *put* requst.
    ///
    /// - Parameters:
    ///     - url:      the *url* address
    ///     - data:     data to post
    ///     - stream:   whether data be sent in stream mode or not
    ///
    /// - Returns: *nil* if *url* is not a valid URL, otherwise return a *response*
    public func put(url: String, data: String, _ stream: Bool = false) -> Response? {
        guard let encodedURL = NSURL(string: url, relativeToURL: nil) else { return nil }
        return self.put(encodedURL, data: data, stream)
    }
    
    /// Send a *put* requst.
    ///
    /// - Parameters:
    ///     - url:      the *url* address
    ///     - data:     data to post
    ///     - stream:   whether data be sent in stream mode or not
    /// - Returns: *nil* if *url* is not a valid URL, otherwise return a *response*
    public func put(url: NSURL, data: String, _ stream: Bool = false) -> Response? {
        guard let request = self.prepareRequest(url, method: .PUT) else { return nil }
        request.stream = stream
        request.data = data.dataUsingEncoding(NSUTF8StringEncoding)
        return self.send(request)
    }
    
    /// Send a *post* requst.
    ///
    /// - Parameters:
    ///     - url:      the *url* address
    ///     - file:     file to post
    ///     - stream:   whether file be sent in stream mode or not
    ///     - outlast:  indicate whether request is sent through background session or not
    ///
    /// - Returns: *nil* if *url* is not a valid URL or file is not exist, otherwise return a *response*
    public func put(url: String, file: NSURL, _ stream: Bool = false, _ outlast: Bool = false) -> Response? {
        guard let encodedURL = NSURL(string: url, relativeToURL: nil) else { return nil }
        return self.put(encodedURL, file: file, stream, outlast)
    }
    
    /// Send a *post* requst.
    ///
    /// - Parameters:
    ///     - url:      the *url* address
    ///     - file:     file to post
    ///     - stream:   whether file be sent in stream mode or not
    ///     - outlast:  indicate whether request is sent through background session or not
    ///
    /// - Returns: *nil* if *url* is not a valid URL or *file* is not exist, otherwise return a *response*
    public func put(url: NSURL, file: NSURL, _ stream: Bool = false, _ outlast: Bool = false) -> Response? {
        guard NSFileManager.defaultManager().fileExistsAtPath(file.absoluteString) else { return nil }
        guard let request = self.prepareRequest(url, method: .PUT) else { return nil }
        
        request.stream = stream
        request.filePath = file
        request.outlast = outlast
        return self.send(request)
    }
    
    /// Send a *delete* requst.
    ///
    /// - Parameters:
    ///     - url:      the *url* address
    ///     - data:     data to post
    ///
    /// - Returns: *nil* if *url* is not a valid URL, otherwise return a *response*
    public func delete(url: String, data: String) -> Response? {
        guard let encodedURL = NSURL(string: url, relativeToURL: nil) else { return nil }
        return self.delete(encodedURL, data: data)
    }
    
    /// Send a *delete* requst.
    ///
    /// - Parameters:
    ///     - url:      the *url* address
    ///     - data:     data to post
    ///
    /// - Returns: *nil* if *url* is not a valid URL, otherwise return a *response*
    public func delete(url: NSURL, data: String) -> Response? {
        guard let request = self.prepareRequest(url, method: .DELETE) else { return nil }
        request.data = data.dataUsingEncoding(NSUTF8StringEncoding)
        return self.send(request)
    }
    
    /// Send a *patch* requst.
    ///
    /// - Parameters:
    ///     - url:      the *url* address
    ///     - data:     data to post
    ///     - stream:   whether data be sent in stream mode or not 
    /// - Returns: *nil* if *url* is not a valid URL, otherwise return a *response*
    public func patch(url: String, data: NSData, _ stream: Bool = false) -> Response? {
        guard let encodedURL = NSURL(string: url, relativeToURL: nil) else { return nil }
        return self.patch(encodedURL, data: data, stream)
    }
    
    /// Send a *patch* requst.
    ///
    /// - Parameters:
    ///     - url:      the *url* address
    ///     - data:     data to post
    ///     - stream:   whether data be sent in stream mode or not
    ///                 **default**= false
    /// - Returns: *nil* if *url* is not a valid URL, otherwise return a *response*
    public func patch(url: NSURL, data: NSData, _ stream: Bool = false) -> Response? {
        guard let request = self.prepareRequest(url, method: .PATCH) else { return nil }
        request.stream = stream
        request.data = data
        return self.send(request)
    }
    
    /// Send a *patch* requst.
    ///
    /// - Parameters:
    ///     - url:      the *url* address
    ///     - data:     data to post
    ///     - stream:   whether data be sent in stream mode or not
    ///                 **default**= false
    /// - Returns: *nil* if *url* is not a valid URL, otherwise return a *response*
    public func patch(url: String, data: String, _ stream: Bool = false) -> Response? {
        guard let encodedURL = NSURL(string: url, relativeToURL: nil) else { return nil }
        return self.patch(encodedURL, data: data, stream)
    }
    
    /// Send a *patch* requst.
    ///
    /// - Parameters:
    ///     - url:      the *url* address
    ///     - data:     data to post
    ///     - stream:   whether data be sent in stream mode or not
    ///                 **default**= false
    /// - Returns: *nil* if *url* is not a valid URL, otherwise return a *response*
    public func patch(url: NSURL, data: String, _ stream: Bool = false) -> Response? {
        guard let request = self.prepareRequest(url, method: .PATCH) else { return nil }
        request.stream = stream
        request.data = data.dataUsingEncoding(NSUTF8StringEncoding)
        return self.send(request)
    }
    
    /// Send a *patch* requst.
    ///
    /// - Parameters:
    ///     - url:      the *url* address
    ///     - file:     file to post
    ///     - stream:   whether file be sent in stream mode or not
    ///                 **default**= false
    ///     - outlast:  indicate whether request is sent through background session or not
    ///
    /// - Returns: *nil* if *url* is not a valid URL or *file* is not exist, otherwise return a *response*
    public func patch(url: String, file: NSURL, _ stream: Bool = false, _ outlast: Bool = false) -> Response? {
        guard let encodedURL = NSURL(string: url, relativeToURL: nil) else { return nil }
        return self.patch(encodedURL, file: file, stream, outlast)
    }
    
    /// Send a *patch* requst.
    ///
    /// - Parameters:
    ///     - url:      the *url* address
    ///     - file:     file to post
    ///     - stream:   whether file be sent in stream mode or not.
    ///                 **default**= false
    ///     - outlast:  indicate whether request is sent through background session or not
    ///
    /// - Returns: *nil* if *url* is not a valid URL or *file* is not exist, otherwise return a *response*
    public func patch(url: NSURL, file: NSURL, _ stream: Bool = false, _ outlast: Bool = false) -> Response? {
        guard NSFileManager.defaultManager().fileExistsAtPath(file.absoluteString) else { return nil }
        guard let request = self.prepareRequest(url, method: .PATCH) else { return nil }
        
        request.stream = stream
        request.filePath = file
        request.outlast = outlast
        return self.send(request)
    }
   
    /// Download from url.
    ///
    /// - Parameters:
    ///     - url:      the *url* address
    ///     - params:   query string
    ///     - outlast:  indicate whether request is sent through background session or not
    ///
    /// - Returns: *nil* if *url* is not a valid URL, otherwise return a *response*
    public func download(url: String, _ params: [String: String]? = nil, _ outlast: Bool = true) -> Response? {
        var copy = url
        if let params = params {
            copy += "?"
            for (key, name) in params {
                copy += key + "=" + name
                copy += "&"
            }
            copy.removeAtIndex(copy.endIndex.predecessor())
        }
        
        guard let encodedURL = NSURL(string: copy, relativeToURL: nil) else {
            return nil
        }
        return self.download(encodedURL, outlast)
    }
    
    /// Download from url.
    ///
    /// - Parameters:
    ///     - url:      the *url* address
    ///     - outlast:  indicate whether request is sent through background session or not
    ///
    /// - Returns: *nil* if *url* is not a valid URL, otherwise return a *response*
    public func download(url: NSURL, _ outlast: Bool = true) -> Response? {
        guard let request = self.prepareRequest(url, method: .DOWNLOAD) else { return nil }
        request.outlast = outlast
        return self.send(request)
    }
    
    /// Handle background download session completion when application isn't in foreground.
    /// Only call this inside `application:handleEventsForBackgroundURLSession:completionHandler:`
    ///
    /// **NOTE** that the *onCompleteHandler* may not be called, if it's not necessary.
    public func download(identifier: String, wake_up_handler: () -> Void, onCompleteHandler: (url: NSURL) -> Void) {
        for session in self.outlastSession {
            if identifier == session.identifier! {
                // If there's already a session with identifier, we
                // don't need to create another one, but wake_up_handler 
                // still need to be called.
                // see [https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIApplicationDelegate_Protocol/index.html#//apple_ref/occ/intfm/UIApplicationDelegate/application:handleEventsForBackgroundURLSession:completionHandler:]
                session.register_wake_up_completion_handler(wake_up_handler)
                return
            }
        }
        
        // Create a brand new session with the given identifier
        let config = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(identifier)
        let s = Session(config: config, client: self, wake_up_handler: wake_up_handler, onCompletionHandler: onCompleteHandler)
        s.handle_wake_up()
        s.decaySelf()
        self.outlastSession.append(s)
    }
    
    /// Send the *request*
    ///
    /// - Parameters:
    ///     - a request to send
    ///
    /// - Returns: *nil* if *request* is not correctly configured
    public func send(request: Request) -> Response? {
        request.current_redirect_count = 0
        if request.outlast == true {
            guard (request.filePath != nil && request.HTTPMethod == .POST) || (request.HTTPMethod == .DOWNLOAD) else { return nil }
            
            let config = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(Utils.randomIdentifier())
            let session = Session(config: config, client: self)
            self.outlastSession.append(session)
            return session.send(request)
        } else {
            return self.defaultSession.send(request)
        }
    }
    
    /// Create a request that's prepared to send.
    ///
    /// - Parameters:
    ///     - url:      host address
    ///     - method:   HTTP method
    ///
    /// - Returns: *nil* if *url* is not a valid URL, otherwise return a *request*
    public func prepareRequest(url: String, method: Method) -> Request? {
        guard let encodedURL = NSURL(string: url, relativeToURL: nil) else { return nil }
        return self.prepareRequest(encodedURL, method: method)
    }
    
    /// Create a request that's prepared to send.
    ///
    /// - Parameters:
    ///     - url:      host address
    ///     - method:   HTTP method
    ///
    /// - Returns: *nil* if *url* is not a valid URL, otherwise return a *request*
    public func prepareRequest(url: NSURL, method: Method) -> Request? {
        guard Utils.validScheme(url) else { return nil }
        return Request(url: url, method: method)
    }
    
    // Session callback
    // Sessions call this to clean up when they're done
    func removeSession(session: Session) {
        if let index = self.outlastSession.indexOf(session) {
            self.outlastSession.removeAtIndex(index)
        } else if let index = self.decaySession.indexOf(session) {
            self.decaySession.removeAtIndex(index)
        }
    }
    
    // Apply new configuration
    func applyConfig(config: NSURLSessionConfiguration) {
        if !self.defaultSession.isEmpty {
            self.defaultSession.decaySelf()
            self.decaySession.append(self.defaultSession)
        }
        self.defaultSession = Session(config: config, client: self)
    }
}
