//
//  Session.swift
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

final class Session: NSObject, NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate, NSURLSessionDownloadDelegate {
    private lazy var urlSession: NSURLSession = {
        return NSURLSession(configuration: self.config, delegate: self, delegateQueue: nil)
    }()
    
    private let handlerQueue = NSOperationQueue()
    private let taskQueue = dispatch_queue_create("huntaway.com.github", DISPATCH_QUEUE_SERIAL)
    private var responses: [Int: Response] = [:]
    private let config: NSURLSessionConfiguration
    private var decaying = false
    private unowned let httpClient: HTTPClient
    
    init(config: NSURLSessionConfiguration, client: HTTPClient) {
        self.config = config
        self.httpClient = client
    }
    
    deinit {
        self.handlerQueue.cancelAllOperations()
    }
    
    // This's for system-wake-up-handling only
    // Don't call this for other intentions
    private var waked_up_by_system_completion_handler: (() -> Void)? = nil
    private var waked_up_by_system_user_complettion_handler: ((downloadedFilePath: NSURL) -> Void)? = nil
    convenience init(config: NSURLSessionConfiguration, client: HTTPClient, wake_up_handler: () -> Void, onCompletionHandler: (downloadedFilePath: NSURL) -> Void) {
        self.init(config: config, client: client)
        waked_up_by_system_completion_handler = wake_up_handler
        waked_up_by_system_user_complettion_handler = onCompletionHandler
    }
    
    // Force lazy urlSession to instantiate
    func handle_wake_up() { let _ = self.urlSession.configuration.identifier }
    
    var identifier: String? {
        return self.urlSession.configuration.identifier
    }
    
    func send(request: Request) -> Response? {
        let req = Utils.createNSURLRequest(request, session: self.urlSession)
        switch request.HTTPMethod {
        case .HEAD:
            fallthrough
        case .GET:
            let task = self.urlSession.dataTaskWithRequest(req)
            let resp = Response(task: task, request: request, session: self)
            dispatch_sync(self.taskQueue) { self.responses[task.taskIdentifier] = resp }
            return resp
           
        case .PATCH:
            fallthrough
        case .DELETE:
            fallthrough
        case .PUT:
            fallthrough
        case .POST:
            var task: NSURLSessionTask
            if request.stream {
                task = self.urlSession.uploadTaskWithStreamedRequest(req)
            } else {
                if let data = request.data {
                    task = self.urlSession.uploadTaskWithRequest(req, fromData: data)
                } else if let file = request.filePath {
                    task = self.urlSession.uploadTaskWithRequest(req, fromFile: file)
                } else {
                    return nil
                }
            }
            let resp = Response(task: task, request: request, session: self)
            dispatch_sync(self.taskQueue) { self.responses[task.taskIdentifier] = resp }
            
            return resp
            
        case .DOWNLOAD:
            let task = self.urlSession.downloadTaskWithRequest(req)
            let resp = Response(task: task, request: request, session: self)
            dispatch_sync(self.taskQueue) { self.responses[task.taskIdentifier] = resp }
            
            return resp
        }
    }
    
    func removeResponse(resp: Response) {
        dispatch_sync(self.taskQueue) {
            self.responses.removeValueForKey(resp.task.taskIdentifier)
        }
        let responsesEmpty = responses.isEmpty
        
        if resp.request.outlast && responsesEmpty {
            self.urlSession.finishTasksAndInvalidate()
        } else if self.decaying && responsesEmpty {
            self.urlSession.finishTasksAndInvalidate()
        }
    }
    
    func decaySelf() {
        self.decaying = true
    }
    
    var isEmpty: Bool {
        var empty = false
        self.urlSession.getTasksWithCompletionHandler() { (dataTasks, uploadTasks, downloadTasks) in
            empty = dataTasks.isEmpty && uploadTasks.isEmpty && downloadTasks.isEmpty
        }
        return empty
    }
    
    func register_wake_up_completion_handler(handler: () -> Void) {
        // There should only be one response in a background session
        // Because we start a download task in a new background session
        // every single time.
        if let resp = self.responses[0] {
            resp.waked_up_by_system_completion_handler = handler
        }
    }
    
    // MARK: - Session Delegate
    //TODO:
    func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        completionHandler(.PerformDefaultHandling, nil)
    }
    
    func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
        if let resp = self.responses[0] {
            if let handler = resp.waked_up_by_system_completion_handler {
                dispatch_async(dispatch_get_main_queue()) { handler() }
                resp.waked_up_by_system_completion_handler = nil
            }
        } else {
            if let handler = self.waked_up_by_system_completion_handler {
                dispatch_async(dispatch_get_main_queue()) { handler() }
                self.waked_up_by_system_completion_handler = nil
            }
        }
    }
    
    func URLSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?) {
        self.httpClient.removeSession(self)
    }
    
    // MARK: - Session Task Delegate
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        var response: Response?
        dispatch_sync(self.taskQueue) { response = self.responses[task.taskIdentifier] }
        guard let resp = response else { return }
        
        resp.errorDescription = error
        
        // Set headers
        if let urlResponse = task.response as? NSHTTPURLResponse {
            resp.HTTPHeaders = [:]
            for (key, value) in urlResponse.allHeaderFields {
                guard let key = key as? String , let value = value as? String else { continue }
                resp.HTTPHeaders![key] = value
            }
            resp.HTTPStatusCode = urlResponse.statusCode
        }
        
        // Set cookies
        if let cookies = self.urlSession.configuration.HTTPCookieStorage?.cookiesForURL(resp.request.URL) {
            resp.HTTPCookies = [:]
            for cookie in cookies {
                resp.HTTPCookies![cookie.name] = cookie.value
            }
        }
        
        resp.markCompleted()
        if let handler = resp.completeHandler {
            self.handlerQueue.addOperationWithBlock() { handler(resp: resp, error: error) }
        }
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
  
        var response: Response?
        dispatch_sync(self.taskQueue) { response = self.responses[task.taskIdentifier] }
        guard let resp = response else { return completionHandler(.PerformDefaultHandling, nil) }
        
        // Try per request sepecific auth
        
        if let requestBasic = resp.request.basicAuthSettings {
            resp.request.basic = nil
            
            return completionHandler(.UseCredential, requestBasic)
        }
        
        if let requestDigest = resp.request.diegestAuthSettings {
            resp.request.digest = nil
            
            return completionHandler(.UseCredential, requestDigest)
        }
        
        // Try global auth 
        
        var credentials: [String: NSURLCredential] = [:]
        if session.configuration.URLCredentialStorage != nil {
            for (space, credential) in session.configuration.URLCredentialStorage!.allCredentials {
                guard challenge.protectionSpace.host == space.host else { continue }
                
                for (key, value) in credential {
                    credentials[key] = value
                }
            }
        }
        guard !credentials.isEmpty && challenge.previousFailureCount < credentials.count else { return completionHandler(.PerformDefaultHandling, nil) }
        
        if challenge.previousFailureCount == 0 {
            let (username, credential) = credentials.first!
            resp.authTriedUsername = []
            resp.authTriedUsername?.append(username)
            return completionHandler(.UseCredential, credential)
        } else {
            for (username, credential) in credentials {
                guard !resp.authTriedUsername!.contains(username) else { continue }
                resp.authTriedUsername?.append(username)
                return completionHandler(.UseCredential, credential)
            }
            assert(false, "Logic Error. This should never run")
        }
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        var resp: Response?
        dispatch_sync(self.taskQueue) { resp = self.responses[task.taskIdentifier] }
        
        guard let processHandler = resp?.processHandler else { return }
        
        let progress = Progress(type: .Sending, did: bytesSent, done: totalBytesSent, workload: totalBytesExpectedToSend)
        self.handlerQueue.addOperationWithBlock() { processHandler(progress: progress) }
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, needNewBodyStream completionHandler: (NSInputStream?) -> Void) {
        var response: Response?
        dispatch_sync(self.taskQueue) { response = self.responses[task.taskIdentifier] }
        guard let resp = response else { return }
        
        if let filePath = resp.request.filePath {
            completionHandler(NSInputStream(URL: filePath))
        } else if let data = resp.request.data {
            completionHandler(NSInputStream(data: data))
        }
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, willPerformHTTPRedirection response: NSHTTPURLResponse, newRequest request: NSURLRequest, completionHandler: (NSURLRequest?) -> Void) {
        var response: Response?
        dispatch_sync(self.taskQueue) { response = self.responses[task.taskIdentifier] }
        if let resp = response {
            if !resp.request.allowRedirect || resp.request.current_redirect_count > resp.request.maxRedirect {
                completionHandler(nil)
                return
            }
            
            if resp.request.rememberRedirectHistory {
                if let url = request.URL {
                    resp.HTTPRedirectHistory = resp.HTTPRedirectHistory ?? []
                    resp.HTTPRedirectHistory?.append(url)
                }
            }
        }
        completionHandler(request)
    }
    
    // MARK: - Session Data Delegate
    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        var response: Response?
        dispatch_sync(self.taskQueue) { response = self.responses[dataTask.taskIdentifier] }
        guard let resp = response else { return }
        
        resp.receivedData = resp.receivedData ?? []
        data.enumerateByteRangesUsingBlock { (bytes , range , stop) -> Void in
            var ptr = UnsafePointer<UInt8>(bytes)
            for _ in 0 ..< range.length {
                resp.receivedData!.append(ptr.memory)
                ptr = ptr.advancedBy(1)
            }
        }
        
        if let handler = resp.dataReceivedHandler {
            self.handlerQueue.addOperationWithBlock() { handler() }
        }
    }
    
    // MARK: - Session Download Delegate
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        var response: Response?
        dispatch_sync(self.taskQueue) { response = self.responses[downloadTask.taskIdentifier] }
        guard let resp = response else {
            //  A download finish event sent to an empty session. I guess
            //  that's because we're just waked up by system.
            if let handler = self.waked_up_by_system_user_complettion_handler {
                handler(downloadedFilePath: location)
                self.waked_up_by_system_user_complettion_handler = nil
            }
            return
        }
        
        resp.markCompleted()
        if let handler = resp.downloadHandler {
            self.handlerQueue.addOperationWithBlock() { handler(url: location) }
        }
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        var resp: Response?
        dispatch_sync(self.taskQueue) { resp = self.responses[downloadTask.taskIdentifier] }
        guard let processHandler = resp?.processHandler else { return }
        
        let progress = Progress(type: .Receiving, did: 0, done: fileOffset, workload: expectedTotalBytes)
        self.handlerQueue.addOperationWithBlock() { processHandler(progress: progress) }
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        var resp: Response?
        dispatch_sync(self.taskQueue) { resp = self.responses[downloadTask.taskIdentifier] }
        guard let processHandler = resp?.processHandler else { return }
        
        let progress = Progress(type: .Receiving, did: bytesWritten, done: totalBytesWritten, workload: totalBytesExpectedToWrite)
        self.handlerQueue.addOperationWithBlock() { processHandler(progress: progress) }
    }
}