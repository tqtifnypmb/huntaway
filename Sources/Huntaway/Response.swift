//
//  Response.swift
//  XcodeProject
//
//  Created by Tqtifnypmb on 3/9/16.
//  Copyright © 2016 Tqtifnypmb. All rights reserved.
//

import Foundation

public class Response {
    
    typealias onCompleteHandler = (resp : Response, error: NSError?) -> Void
    typealias onBeginHandler = () -> Void
    typealias onProcessHandler = (progress: Progress, error: NSError?) -> Void
    
    private var completeHandler: onCompleteHandler? = nil
    private var beginHandler: onBeginHandler? = nil
    private var processHandler: onProcessHandler? = nil
    private let session: Session
    
    private var resumeData: NSData? = nil
    private var completed: Int32 = 0
    private let condition: NSCondition
    private var ticked = false
    
    let task: NSURLSessionTask
    let request: Request
    var HTTPHeaders: [String: String]? = nil
    var HTTPCookies: [String: String]? = nil
    var HTTPStatusCode: Int = 0
    var errorDescription: NSError? = nil
    var receivedData: [UInt8]? = nil
    var downloadedFilePath: NSURL? = nil
    var HTTPredirectHistory: [NSURL]? = nil
    
    var waked_up_by_system_completion_handler: (() -> Void)? = nil
   
    init(task: NSURLSessionTask, request: Request, session: Session) {
        self.task = task
        self.request = request
        self.condition = NSCondition()
        self.session = session
    }
    
    /// Status code
    /// Block if response is not ready
    public var statusCode: Int {
        guard self.ticked else {
            return 0
        }
        waitForComplete()
        return self.HTTPStatusCode
    }
    
    /// string description of statusCode
    /// Block if response is not ready
    public var reason: String {
        guard self.ticked else {
            return ""
        }
        return NSHTTPURLResponse.localizedStringForStatusCode(self.statusCode)
    }
    
    /// Path of the downloaded file. 
    /// This file maybe located in temporary
    /// directory, you should move it out
    /// if you need it.
    ///
    /// - Returns: nil, if you didn't download anything
    public var downloadedFile: NSURL? {
        guard self.ticked else {
            return nil
        }
        self.waitForComplete()
        return self.downloadedFilePath
    }
    
    /// HTTP request's URL
    public var requestURL: NSURL {
        return self.request.URL
    }
    
    /// HTTP response's URL
    /// Block if response is not ready
    public var URL: NSURL {
        guard self.ticked else {
            return NSURL()
        }
        waitForComplete()
        return self.task.response!.URL!
    }
    
    /// Network error
    /// Block if response is not ready
    public var error: NSError? {
        guard self.ticked else {
            return nil
        }
        waitForComplete()
        return self.errorDescription
    }
    
    /// HTTP cookies
    /// Block if response is not ready
    public var cookies: [String: String]? {
        guard self.ticked else {
            return nil
        }
        waitForComplete()
        return self.HTTPCookies
    }
    
    /// HTTP response's headers
    /// Block if response is not ready
    public var headers: [String: String]? {
        guard self.ticked else {
            return nil
        }
        waitForComplete()
        return self.HTTPHeaders
    }
    
    /// Raw data of HTTP response's body.
    /// Block if response is not ready
    public var body: [UInt8]? {
        guard self.ticked else {
            return nil
        }
        waitForComplete()
        
        return self.receivedData
    }
    
    public var bodyJson: AnyObject? {
        guard self.ticked else {
            return nil
        }
        guard var body = self.body else {
            return nil
        }
        
        let data = NSData(bytes: &body, length: body.count)
        do {
            return try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
        } catch {
            return nil
        }
    }
    
    /// String representatino of HTTP response's body
    public var text: String? {
        guard self.ticked else {
            return nil
        }
        waitForComplete()
        
        guard let data = self.receivedData else {
            return nil
        }
        return String(bytes: data, encoding: NSUTF8StringEncoding)
    }
    
    public var redirectHistory: [NSURL]? {
        if !self.request.rememberRedirectHistory {
            return nil
        }
        
        guard self.ticked else {
            return nil
        }
        waitForComplete()
        return self.HTTPredirectHistory
    }
    
    /// Close this response.
    /// After called, this response is no
    /// longer valid. You should always
    /// call this method when you're done with
    /// response
    public func close() {
        self.session.removeResponse(self)
    }
    
    /// Set onComplete callback.
    /// This hook will be called as soon as response get ready
    ///
    /// **Note** This hook should be set before response get ticked.
    /// Hooks set after response tick might not be called
    public func onComplete(completeHandler: (resp : Response, error: NSError?) -> Void) {
        if !self.ticked {
            self.completeHandler = completeHandler
        } else {
            self.condition.lock()
            self.completeHandler = completeHandler
            self.condition.unlock()
        }
    }
    
    /// Set onBegin callback.
    /// This hook will be called as soon as request get sent
    ///
    /// **Note** This hook should be set before response get ticked.
    /// Hooks set after response tick might not be called
    public func onBegin(beginHandler: () -> Void) {
        guard !self.ticked else {
            return
        }
        self.beginHandler = beginHandler
    }
    
    /// Set onProcess callback.
    /// This hook will be called everytime when data sent or data received
    ///
    /// **Note** This hook should be set before response get ticked.
    /// Hooks set after response tick might not be called
    public func onProcess(processHandler: (progress: Progress, error: NSError?) -> Void) {
        if !self.ticked {
            self.processHandler = processHandler
        } else {
            self.condition.lock()
            self.processHandler = processHandler
            self.condition.unlock()
        }
    }
    
    /// Tick to get response
    public func tick(completeHandler: ((resp : Response, error: NSError?) -> Void)? = nil) -> Response {
        if let completeHandler = completeHandler {
            self.onComplete(completeHandler)
        }
        
        self.ticked = true
        self.task.resume()
        
        if let handler = self.beginHandler {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) { handler() }
        }
        
        return self
    }
    
    /// Test whether response is ready to use.
    /// This function *Never* block
    public func isReady() -> Bool {
        return OSAtomicCompareAndSwap32(1, 1, &self.completed)
    }
    
    /// Suspend the ongoing task.
    /// A task, while suspended, produces no network traffic and is not subject to timeouts.
    /// A download task can continue transferring data at a later time.
    ///All other tasks must start over when resumed.
    public func suspend() {
        self.task.suspend()
    }
    
    /// Cancels the task.
    public func cancel() {
        self.task.cancel()
    }
    
    /// Resumes the task, if it is suspended.
    public func resume() {
        self.task.resume()
    }
    
    func markCompleted() {
        OSAtomicCompareAndSwap32(0, 1, &self.completed)
        self.condition.broadcast()
    }
    
    var process_handler: onProcessHandler? {
        self.condition.lock()
        let handler = self.processHandler
        self.condition.unlock()
        return handler
    }
    
    var complete_handler: onCompleteHandler? {
        self.condition.lock()
        let handler = self.completeHandler
        self.condition.unlock()
        return handler
    }
    
    private func waitForComplete() {
        if OSAtomicCompareAndSwap32(1, 1, &self.completed) {
            return
        }
        
        self.condition.lock()
        while !OSAtomicCompareAndSwap32(1, 1, &self.completed) {
            self.condition.wait()
        }
        self.condition.unlock()
    }
}