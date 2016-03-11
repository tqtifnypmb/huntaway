## Introduction

Huntaway is a Swift HTTP client inspired by *How complex it is to make a simple http request using NSURLSession*.
Huntaway's goal is: 
- Make a HTTP request is as simple as calling a function.
- No complex configuration needed

## Badges
[![PRs Welcome](https://img.shields.io/badge/prs-welcome-brightgreen.svg?style=flat-square)](http://makeapullreque    st.com)

## Usage

- Basic Pattern
```
    // GET
    HTTPClient.sharedHTTPClient().get("https://www.google.com")?.tick() { (response, error) in
        // do something with the response
    }

    // POST
    HTTPClient.sharedHTTPClient().post("https://www.google.com", "data_to_post")?.tick() { (response, error) in
        //...
    }

    // DOWNLOAD
    HTTPClient.sharedHTTPClient().download("https://www.google.com")?.tick() { (resp, error) in
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

- More Control

  *Response Side*
```
    let response = HTTPClient.sharedHTTPClient().post("https://www.google.com")?
    response.onBegin() {
        // do somthing when request begin
    }

    response.onProcess() { (progress, error) in
        // do something when request's processing
    }

    response.onComplete() { (resp, error) in
        // do something when request completed
    }

    response.tick()
```

  *Request Side*
    
```
  let request = HTTPClient.sharedHTTPClient().prepareRequest("https://www.google.com", .GET)
  request.setHeaders(xxx)
  request.rememberRedirectHistory = true
  
  // more setting
  
  HTTPClient.sharedHTTPClient().send(request)?.tick() { (resp, error) in
        // do simething with resp
  }

```
