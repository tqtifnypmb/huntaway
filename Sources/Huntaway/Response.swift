//
//  Response.swift
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

public class Response {
    
    typealias onCompleteHandler = (resp : Response, error: NSError?) -> Void
    typealias onBeginHandler = () -> Void
    typealias onProcessHandler = (progress: Progress) -> Void
    typealias onDownloadCompleteHandler = (url: NSURL) -> Void
    

    private let session: Session
    private var resumeData: NSData? = nil
    private var completed: Int32 = 0
    private let condition: NSCondition
    
    //FIXME: thread-safe issue ??
    private var ticked = false
    
    let task: NSURLSessionTask
    let request: Request
    var HTTPHeaders: [String: String]? = nil
    var HTTPCookies: [String: String]? = nil
    var HTTPStatusCode: Int = 0
    var errorDescription: NSError? = nil
    var receivedData: [UInt8]? = nil
    var HTTPRedirectHistory: [NSURL]? = nil
    var authTriedUsername: [String]? = nil
    
    var completeHandler: onCompleteHandler? = nil
    var beginHandler: onBeginHandler? = nil
    var processHandler: onProcessHandler? = nil
    var downloadHandler: onDownloadCompleteHandler? = nil
    
    
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
        guard self.ticked else { return 0 }
        
        waitForComplete()
        return self.HTTPStatusCode
    }
    
    /// string description of statusCode
    /// Block if response is not ready
    public var reason: String {
        guard self.ticked else { return "" }
        
        return NSHTTPURLResponse.localizedStringForStatusCode(self.statusCode)
    }
    
    /// HTTP request's URL
    public var requestURL: NSURL {
        return self.request.URL
    }
    
    /// HTTP response's URL
    /// Block if response is not ready
    public var URL: NSURL? {
        guard self.ticked else { return nil }
        
        waitForComplete()
        return self.task.response!.URL
    }
    
    /// Network error
    /// Block if response is not ready
    public var error: NSError? {
        guard self.ticked else { return nil }
        
        waitForComplete()
        return self.errorDescription
    }
    
    /// HTTP cookies
    /// Block if response is not ready
    public var cookies: [String: String]? {
        guard self.ticked else { return nil }
        
        waitForComplete()
        return self.HTTPCookies
    }
    
    /// HTTP response's headers
    /// Block if response is not ready
    public var headers: [String: String]? {
        guard self.ticked else { return nil }
        
        waitForComplete()
        return self.HTTPHeaders
    }
    
    /// Raw data of HTTP response's body.
    /// Block if response is not ready
    public var body: [UInt8]? {
        guard self.ticked else { return nil }
        
        waitForComplete()
        return self.receivedData
    }
    
    public var bodyJson: AnyObject? {
        guard self.ticked else { return nil }
        guard var body = self.body else { return nil }
        
        let data = NSData(bytes: &body, length: body.count)
        do {
            return try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
        } catch {
            return nil
        }
    }
    
    /// String representatino of HTTP response's body
    public var text: String? {
        guard self.ticked else { return nil }
        
        waitForComplete()
        
        guard let data = self.receivedData else { return nil }
        
        return String(bytes: data, encoding: NSUTF8StringEncoding)
    }
    
    public var redirectHistory: [NSURL]? {
        if !self.request.rememberRedirectHistory && self.ticked { return nil }
        
        waitForComplete()
        return self.HTTPRedirectHistory
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
        guard !self.ticked else { return }
        self.beginHandler = beginHandler
    }
    
    /// Set onProcess callback.
    /// This hook will be called everytime when data sent or data received
    ///
    /// **Note** This hook should be set before response get ticked.
    /// Hooks set after response tick might not be called
    public func onProcess(processHandler: (progress: Progress) -> Void) {
        guard !self.ticked else { return }
        self.processHandler = processHandler
    }
    
    /// This hook will be called when download is completed.
    public func onDownloadComplete(downloadHandler: ((url: NSURL) -> Void)) {
        guard !self.ticked else { return }
        self.downloadHandler = downloadHandler
    }
    
    /// Tick to let things happen
    public func tick(completeHandler: ((resp : Response, error: NSError?) -> Void)? = nil) -> Response {
        guard !self.ticked else { return self }
        
        if let completeHandler = completeHandler {
            self.onComplete(completeHandler)
        }
        
        return self.do_tick()
    }
    
    /// Tick to start download
    public func tick(downloadCompleteHandler: ((url: NSURL) -> Void)) -> Response {
        guard !self.ticked else { return self }
        
        self.onDownloadComplete(downloadCompleteHandler)
        return self.do_tick()
    }
    
    private func do_tick() -> Response {
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