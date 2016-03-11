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
        client.printSessinoState()
        client.get("http://httpbin.org/get")?.tick() { (resp, error) in
            print("=====")
            resp.close()
        }
        
        sleep(5)
        client.printSessinoState()
    }
    
    func test_hook() {
        if let resp = HTTPClient.sharedHTTPClient().get("http://httpbin.org/get") {
            resp.onBegin() {
                print("request begins")
            }
            resp.onProcess() { (progress, error) in
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
        if let resp = HTTPClient.sharedHTTPClient().download("http://www.baidu.com") {
            resp.onComplete() { (respe, error) in
                print(respe.downloadedFile)
                do {
                    let url = try NSFileManager.defaultManager().URLForDirectory(.DesktopDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: false).URLByAppendingPathComponent("abc.txt")
                    try NSFileManager.defaultManager().copyItemAtPath(resp.downloadedFile!.path!, toPath: url.path!)
                } catch {
                    print(error)
                }
                
            }
            resp.tick()
            print(resp.statusCode)
            sleep(10)
        }
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
}
