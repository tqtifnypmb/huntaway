//
//  Unitests.swift
//  Unitests
//
//  Created by Tqtifnypmb on 3/10/16.
//  Copyright © 2016 Tqtifnypmb. All rights reserved.
//

import XCTest

class Unitests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func test_get() {
        if let resp = HTTPClient.sharedHTTPClient().get("http://httpbin.org/get", ["username": "abasbaba", "passwd": "dsgdsg"])?.tick() {
            if let data = resp.text {
                print(data)
            }
            XCTAssertEqual(resp.statusCode, 200)
        }
    }
    
    func test_post_string() {
        if let resp = HTTPClient.sharedHTTPClient().post("http://requestb.in/1743q801", data: "Hello world_你好世界") {
            print(resp.statusCode)
            if let data = resp.body {
                print(data)
            }
        }
    }
    
    func test_post_file_without_stream() {
        if let resp = HTTPClient.sharedHTTPClient().post("http://requestb.in/1f6gh8p1", file: NSURL(fileURLWithPath: "/Users/tqtifnypmb/local_sender.cpp")) {
            print(resp.statusCode)
            if let data = resp.body {
               print(data)
            }
        }
    }
    
    func test_post_file_with_stream() {
        if let resp = HTTPClient.sharedHTTPClient().post("http://requestb.in/qe82b4qe", file: NSURL(fileURLWithPath: "/Users/tqtifnypmb/local_sender.cpp"), true, false) {
            print(resp.statusCode)
            if let data = resp.body {
                print(data)
            }
        }
    }
    
    func test_ssl() {
        if let resp = HTTPClient.sharedHTTPClient().get("https://httpbin.org/get", ["username": "abasbaba", "passwd": "dsgdsg"]) {
            if let data = resp.body {
                print(data)
            }
        }
    }
    
    func test_redirect_allow() {
        if let resp = HTTPClient.sharedHTTPClient().get("https://httpbin.org/redirect/2", ["username": "abasbaba", "passwd": "dsgdsg"]) {
            if let data = resp.body {
                print(data)
            }
            resp.tick()
            XCTAssertEqual(resp.statusCode, 200)
        }
    }
    
    func test_redirect_disallow() {
        if let req = HTTPClient.sharedHTTPClient().prepareRequest("https://httpbin.org/redirect/2", method: .GET) {
            req.allowRedirect = false
            if let resp = HTTPClient.sharedHTTPClient().send(req) {
                if let data = resp.body {
                    print(data)
                }
                resp.onBegin() {error in
                }
                XCTAssertEqual(resp.statusCode, 302)
            }
        }
    }
    
    func test_cookies() {
        if let req = HTTPClient.sharedHTTPClient().prepareRequest("https://httpbin.org/cookies", method: .GET) {
            let cookies = ["username": "babababab", "passwd": "fsfsdf"]
            req.setCookies(cookies)
            if let resp = HTTPClient.sharedHTTPClient().send(req) {
                if let data = resp.body {
                    print(data)
                }
                XCTAssertEqual(resp.cookies!, cookies)
            }
        }
    }
    
    func test_headers() {
        if let req = HTTPClient.sharedHTTPClient().prepareRequest("https://httpbin.org/headers", method: .GET) {
            let headers = ["username": "babababab", "passwd": "fsfsdf"]
            req.setHeaders(headers)
            if let resp = HTTPClient.sharedHTTPClient().send(req) {
                if let data = resp.body {
                    print(data)
                }
            }
        }
    }
    
    func test_put_string() {
        if let resp = HTTPClient.sharedHTTPClient().put("http://httpbin.org/put", data: "Hello world_你好世界", true) {
            print(resp.statusCode)
            if let data = resp.body {
                print(data)
            }
        }
    }
    
    func test_put_file() {
        if let resp = HTTPClient.sharedHTTPClient().put("http://httpbin.org/put", file: NSURL(fileURLWithPath: "/Users/tqtifnypmb/local_sender.cpp"), false) {
            print(resp.statusCode)
            if let data = resp.body {
                print(data)
            }
        }
    }
    
    func test_put_file_nonexist() {
        if let resp = HTTPClient.sharedHTTPClient().put("http://httpbin.org/put", file: NSURL(fileURLWithPath: "/Users/tqtifnypmb/local_sender.cppxxx"), false) {
            print(resp.statusCode)
            if let data = resp.body {
                print(data)
            }
        }
    }
    
    func test_delete() {
        if let resp = HTTPClient.sharedHTTPClient().delete("http://httpbin.org/delete", data: "/Users/tqtifnypmb/local_sender.cppxxx") {
            print(resp.statusCode)
            if let data = resp.body {
                print(data)
            }
        }
    }
    
    func test_patch() {
        if let resp = HTTPClient.sharedHTTPClient().patch("http://httpbin.org/patch", data: "/Users/tqtifnypmb/local_sender.cppxxx") {
            print(resp.statusCode)
            if let data = resp.body {
                print(data)
            }
        }
    }
    
    func test_configure() {
        let client = HTTPClient()
        client.get("http://httpbin.org/get")?.tick() { (resp, error) in
            print(resp.text)
            resp.close()
        }
        
        client.config.shouldSetCookies(true).apply()
        client.get("http://httpbin.org/get")?.tick() { (resp, error) in
            print("=====")
            resp.close()
        }
        
        sleep(5)
    }
    
    func test_hook() {
        if let resp = HTTPClient.sharedHTTPClient().get("http://httpbin.org/get") {
            resp.onBegin() {
                print("request begins")
            }
            resp.onProcess() { progress in
                print("Workload ==> \(progress.workload)")
                print("Done ==> \(progress.done)")
                print("Did ==> \(progress.did)")
            }
            resp.onComplete() { (resp, error) in
                print(resp.text)
                resp.close()
            }
            resp.tick()
            sleep(5)
        }
    }
    
    func test_download() {
        guard let resp = HTTPClient.sharedHTTPClient().download("http://speedtest.dal01.softlayer.com/downloads/test10.zip") else { return }
        
        resp.onDownloadComplete() { (url) in
            print(url)
            do {
                let url2 = try NSFileManager.defaultManager().URLForDirectory(.DesktopDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: false).URLByAppendingPathComponent("abc.txt")
                try NSFileManager.defaultManager().copyItemAtPath(url.path!, toPath: url2.path!)
            } catch {
                print(error)
            }
            
        }
        
        resp.onProcess() { progress in
            print(progress.description)
        }
        
        resp.tick()
        print(resp.statusCode)
        sleep(10)
    }

    func test_json() {
        if let resp = HTTPClient.sharedHTTPClient().get("http://httpbin.org/get", ["username": "abasbaba", "passwd": "dsgdsg"])?.tick() {
            if let data = resp.text {
                print(data)
            }
            if let json = resp.bodyJson {
                print(json)
            }
            XCTAssertEqual(resp.statusCode, 200)
        }
    }
    
    func test_multi_thread() {
        let client = HTTPClient()
        let queue = NSOperationQueue()

        for _ in 0 ..< 60 {
            queue.addOperationWithBlock() {
                if let resp = client.get("http://www.baidu.com")?.tick() {
                    print(resp.statusCode)
                    resp.close()
                }
            }
        }
        queue.waitUntilAllOperationsAreFinished()
    }
    
    func test_redirect_history() {
        if let req = HTTPClient.sharedHTTPClient().prepareRequest("https://httpbin.org/redirect/2", method: .GET) {
            req.rememberRedirectHistory = true
            let resp = HTTPClient.sharedHTTPClient().send(req)?.tick()
            print(resp?.redirectHistory)
        }
    }
    
    func test_proxy() {
        let client = HTTPClient()
        client.config.proxy.setHost("202.100.100.1").setPort(8080).apply()
        if let resp = client.get("http://httpbin.org/get", ["username": "abasbaba", "passwd": "dsgdsg"])?.tick() {
            if let data = resp.text {
                print(data)
            }
            if let json = resp.bodyJson {
                print(json)
            }
            XCTAssertEqual(resp.statusCode, 200)
        }
    }
    
    func test_auth_basic() {
        let client = HTTPClient()
        client.config.auth.basic(user: "abcabc", passwd: "123456", url: NSURL(string: "https://httpbin.org/")!, "Fake Realm").apply()
        if let resp = client.get("https://httpbin.org/basic-auth/abcabc/123456")?.tick() {
            if let data = resp.text {
                print(data)
            }
            if let json = resp.bodyJson {
                print(json)
            }
            XCTAssertEqual(resp.statusCode, 200)
        }
    }
    
    func test_auth_basic_2() {
        let client = HTTPClient()
        client.config.auth.basic(user: "abcabc", passwd: "123456", url: NSURL(string: "http://httpbin.org/")!, "Fake Realm")
            .basic(user: "123", passwd: "123", url: NSURL(string: "https://httpbin.org/")!, "Fake Realm")
            .basic(user: "1234", passwd: "1234", url: NSURL(string: "https://httpbin.org/")!, "Fake Realm")
            .apply()
        if let resp = client.get("http://httpbin.org/basic-auth/1234/1234")?.tick() {
            if let data = resp.text {
                print(data)
            }
            if let json = resp.bodyJson {
                print(json)
            }
            XCTAssertEqual(resp.statusCode, 200)
        }
    }
    
    func test_auth_digest() {
        let client = HTTPClient()
        client.config.auth.digest(user: "abcabc", passwd: "123456", url: NSURL(string: "https://httpbin.org/")!).apply()
        if let resp = client.get("https://httpbin.org/digest-auth/auth/abcabc/123456")?.tick() {
            if let data = resp.text {
                print(data)
            }
            if let json = resp.bodyJson {
                print(json)
            }
            XCTAssertEqual(resp.statusCode, 200)
        }
    }
    
    func test_per_request_auth() {
        if let req = HTTPClient.sharedHTTPClient().prepareRequest("https://httpbin.org/basic-auth/abcabc/123456", method: .GET) {
            req.basicAuth(user: "abcabc", passwd: "123456")
            if let resp = HTTPClient.sharedHTTPClient().send(req)?.tick() {
                if let data = resp.body {
                    print(data)
                }
                XCTAssertEqual(resp.statusCode, 200)
            }
        }
    }
}
