## Introduction

Huntaway is a Swift HTTP client inspired by *How complex it is to make a simple http request using NSURLSession*.
Huntaway's goal is: 
- Make a HTTP request is as simple as calling a function.
- No complex configuration needed
- Thread safe

## Badges
[![PRs Welcome](https://img.shields.io/badge/prs-welcome-brightgreen.svg?style=flat-square)](http://makeapullrequest.com)

## Documentation

###HTTPClient

HTTPClient is centra of Huntaway. Reqeusts are constructed by HTTPClient, sent through HTTPClient. Responses are
generated by HTTPClient.

You can use shared instance of HTTPClient
```
    let client = HTTPClient.sharedHTTPClient()
```

Or, you can create a new instance
```
    let client = HTTPClient()
```

###Request

Request represent a HTTP request which is going to be sent. You need this only when you want to do some configurations
before the request's sent.

```
    let request = client.prepareRequest(url, method)

    // Set headers for this request
    request.setHeaders(headers)

    // Set cookies for this request
    request.setCookies(cookies)

```

###Response

Response represent a HTTP response.

You get a response by sending a request
```
    let resp = HTTPClient.sharedHTTPClient().send(request)

    // or

    let resp = HTTPClient.sharedHTTPClient().get(url)
```

Set hook for response data
```

    // Called when response begin. This can be called once
    resp.onBegin() {
    }
    
    // Called everytime new data is received or sent. 
    resp.onProcess() { progress in
    }

    // Called once download complete
    resp.onDownloadComplete() { url in 
    }

    // Called once response complete
    resp.onComplete() { (resp, error) in
    }

```

Finally, you have to tick the response to let things actually happen
```
    resp.tick()
```

When you're done with response you have to close it.
```
    resp.close()
```

**NOTE** Once ticked respones behave like a [future](https://en.wikipedia.org/wiki/Futures_and_promises) object. Any
accesses before response is ready will block the accessing thread.

### Auth

Huntaway currently supports *HTTP Basic Auth* and *HTTP Digest Auth*. You can use it in two ways, *globally* or *per request*.
```
    // globally

    let client = HTTPClient()
    client.config.auth.basic(user: xxx, passwd: xxx, url: xxx).apply()

    // per request

    let request = HTTPClient.sharedHTTPClient().prepareRequest(url, method)
    request.basicAuth(user: xxx, passwd: xxx)

    // or
    request.digestAuth(user: xxx, passwd: xxx)
```

### Thread safety
- Response is thread-safe
- HTTPClient is thread-safe, unless you're using *singleton* mode
- Request is **not** thread-safe
- Proxy, Auth, Configuration are all not thread-safe


## Usage

- Basic Pattern
```
    // GET
    HTTPClient.sharedHTTPClient().get(url)?.tick() { (response, error) in
        // do something with the response
    }

    // POST
    HTTPClient.sharedHTTPClient().post(url, data)?.tick() { (response, error) in
        //...
    }

    // DOWNLOAD
    HTTPClient.sharedHTTPClient().download(url)?.tick() { (resp, error) in
        //...
    }
    // so on
    ...
```

- Configuration Pattern

```

    let client = HTTPClient()
    
    // proxy
    client.config.proxy.setHost(xxx).setPasswd(xxx).setPort(xxx).apply()
    
    // config
    client.config.shouldSetCookies(true).additonalHeaders(xxx).apply()
    
```

- Stream Upload

If you want to upload a file, which is too big to be read into memory, you can use streamed upload.
All you need to do is turn stream option on :)

```
    HTTPClient.sharedHTTPClient().upload(url, file, true)?.tick() { (resp, error) in
    }

```

- Background Task

If you want to upload a file or download a file even when your app is not in the foreground, you can use background task.
Again, All you need to do is turn outlast option on :>

```
    // Background post
    client.post(url, file, false, true)?.tick() { (resp, error) in
    }

    // Background download
    client.download(url, true)?.tick() { (resp, error) in
    }
```
*BTW, for download task outlast is default to be true*


And in order to finish background task when your app is running in the background, you need to :

In your AppDelegate file

```
    func application(application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: () -> Void) 
    {
        client.download(identifier, wake_up_handler: completionHandler, onCompleteHandler: { url in
            })
    }
```
