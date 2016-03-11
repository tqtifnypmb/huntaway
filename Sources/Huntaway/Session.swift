//
//  Session.swift
//  XcodeProject
//
//  Created by Tqtifnypmb on 3/9/16.
//  Copyright © 2016 Tqtifnypmb. All rights reserved.
//

import Foundation

final class Session: NSObject, NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate, NSURLSessionDownloadDelegate {
    private lazy var urlSession: NSURLSession = {
        return NSURLSession(configuration: self.config, delegate: self, delegateQueue: nil)
    }()
    
    private var responses: [Int: Response] = [:]
    private let responsesLock = NSLock()
    private let config: NSURLSessionConfiguration
    private var decaying = false
    private unowned let httpClient: HTTPClient
    
    init(config: NSURLSessionConfiguration, client: HTTPClient) {
        self.config = config
        self.httpClient = client
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
            
            self.responsesLock.lock()
            responses[task.taskIdentifier] = resp
            self.responsesLock.unlock()
        
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
            
            self.responsesLock.lock()
            responses[task.taskIdentifier] = resp
            self.responsesLock.unlock()
            
            return resp
            
        case .DOWNLOAD:
            let task = self.urlSession.downloadTaskWithRequest(req)
            let resp = Response(task: task, request: request, session: self)
            self.responsesLock.lock()
            responses[task.taskIdentifier] = resp
            self.responsesLock.unlock()
            
            return resp
        }
    }
    
    func removeResponse(resp: Response) {
        self.responsesLock.lock()
        responses.removeValueForKey(resp.task.taskIdentifier)
        let responsesEmpty = responses.isEmpty
        self.responsesLock.unlock()
        
        if resp.request.outlast && responsesEmpty {
            self.urlSession.finishTasksAndInvalidate()
            self.httpClient.removeSession(self)
        } else if self.decaying && responsesEmpty {
            self.urlSession.finishTasksAndInvalidate()
            self.httpClient.removeSession(self)
        }
    }
    
    func decaySelf() {
        self.decaying = true
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
    
    // MARK: - Session Task Delegate
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        self.responsesLock.lock()
        let response = self.responses[task.taskIdentifier]
        self.responsesLock.unlock()
        
        guard let resp = response else {
            return
        }
        
        guard !(resp.task is NSURLSessionDownloadTask) else {
            return
        }
        
        resp.errorDescription = error
        
        // Set headers
        if let urlResponse = task.response as? NSHTTPURLResponse {
            resp.HTTPHeaders = [:]
            for (key, value) in urlResponse.allHeaderFields {
                guard let key = key as? String , let value = value as? String else {
                    continue
                }
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
        if let completeHandler = resp.complete_handler {
            completeHandler(resp: resp, error: error)
        }
        
        // If we're waked up by system
        if let completionHandler = resp.waked_up_by_system_completion_handler {
            completionHandler()
        }
    }
    
    //TODO:
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        completionHandler(.PerformDefaultHandling, nil)
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        self.responsesLock.lock()
        let resp = self.responses[task.taskIdentifier]
        self.responsesLock.unlock()
        
        guard let processHandler = resp?.process_handler else {
            return
        }
        
        let progress = Progress(type: .Sending, did: bytesSent, done: totalBytesSent, workload: totalBytesExpectedToSend)
        processHandler(progress: progress, error: task.error)
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, needNewBodyStream completionHandler: (NSInputStream?) -> Void) {
        self.responsesLock.lock()
        let response = self.responses[task.taskIdentifier]
        self.responsesLock.unlock()
        
        guard let resp = response else {
            return
        }
        if let filePath = resp.request.filePath {
            completionHandler(NSInputStream(URL: filePath))
        } else if let data = resp.request.data {
            completionHandler(NSInputStream(data: data))
        }
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, willPerformHTTPRedirection response: NSHTTPURLResponse, newRequest request: NSURLRequest, completionHandler: (NSURLRequest?) -> Void) {
        self.responsesLock.lock()
        let resp = self.responses[task.taskIdentifier]
        self.responsesLock.unlock()
        
        if let resp = resp {
            if !resp.request.allowRedirect {
                completionHandler(nil)
                return
            }
            
            if resp.request.rememberRedirectHistory {
                if let url = request.URL {
                    resp.HTTPredirectHistory = resp.HTTPredirectHistory ?? []
                    resp.HTTPredirectHistory?.append(url)
                }
            }
        }
        completionHandler(request)
    }
    
    // MARK: - Session Data Delegate
    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        self.responsesLock.lock()
        let response = self.responses[dataTask.taskIdentifier]
        self.responsesLock.unlock()
        
        guard let resp = response else {
            return
        }
        
        resp.receivedData = resp.receivedData ?? []
        data.enumerateByteRangesUsingBlock { (bytes , range , stop) -> Void in
            var ptr = UnsafePointer<UInt8>(bytes)
            for _ in 0 ..< range.length {
                resp.receivedData!.append(ptr.memory)
                ptr = ptr.advancedBy(1)
            }
        }
    }
    
    // MARK: - Session Download Delegate
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        self.responsesLock.lock()
        let response = self.responses[downloadTask.taskIdentifier]
        self.responsesLock.unlock()
        
        guard let resp = response else {
            //  A task finish event sent to an empty session. I guess
            //  that's because we're just waked up by system.
            if let handler = self.waked_up_by_system_user_complettion_handler {
                handler(downloadedFilePath: location)
                self.waked_up_by_system_user_complettion_handler = nil
            }
            return
        }
        resp.downloadedFilePath = location
        
        resp.markCompleted()
        if let completeHandler = resp.complete_handler {
            completeHandler(resp: resp, error: nil)
        }
        
        // If we're waked up by the system.
        // we need to call systems hook
        if let completionHandler = resp.waked_up_by_system_completion_handler {
            completionHandler()
        }
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        self.responsesLock.lock()
        let resp = self.responses[downloadTask.taskIdentifier]
        self.responsesLock.unlock()
        
        guard let processHandler = resp?.process_handler else {
            return
        }
        let progress = Progress(type: .Receiving, did: 0, done: fileOffset, workload: expectedTotalBytes)
        processHandler(progress: progress, error: downloadTask.error)
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        self.responsesLock.lock()
        let resp = self.responses[downloadTask.taskIdentifier]
        self.responsesLock.unlock()
        
        guard let processHandler = resp?.process_handler else {
            return
        }
        
        let progress = Progress(type: .Receiving, did: bytesWritten, done: totalBytesWritten, workload: totalBytesExpectedToWrite)
        processHandler(progress: progress, error: downloadTask.error)
    }
}