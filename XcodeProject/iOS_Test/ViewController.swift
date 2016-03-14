//
//  ViewController.swift
//  iOS_Test
//
//  Created by Tqtifnypmb on 3/13/16.
//  Copyright © 2016 Tqtifnypmb. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var _get_url_field: UITextField!
    @IBOutlet weak var _post_url_field: UITextField!
    @IBOutlet weak var _download_url_field: UITextField!
    @IBOutlet weak var _download_progress: UIProgressView!
    @IBOutlet weak var _download_progress_field: UILabel!
    @IBOutlet weak var _wake_up_field: UILabel!
    @IBOutlet weak var _post_data_field: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleBackgroundTask", name: background_download_finish_notification, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    @IBAction func getClicked(sender: AnyObject) {
        guard let url = self._get_url_field.text else { return }
        guard let validURL = NSURL(string: url) else { return }
        HTTPClient.sharedHTTPClient().get(validURL)?.tick() { (resp, error) in
            guard error == nil else { print(error?.localizedDescription) ; return }
            print(resp.statusCode)
            print(resp.text)
            
            resp.close()
        }
    }
    
    @IBAction func postClicked(sender: AnyObject) {
        guard let url = self._post_url_field.text else { return }
        guard let validURL = NSURL(string: url) else { return }
        guard let data = self._post_data_field.text else { return }
        HTTPClient.sharedHTTPClient().post(validURL, data: data)?.tick() { (resp, error) in
            guard error == nil else { print(error?.localizedDescription) ; return }
            print(resp.statusCode)
            print(resp.text)
            
            resp.close()
        }
    }
    
    @IBAction func downloadClicked(sender: AnyObject) {
        guard let url = self._download_url_field.text else { return }
        guard let validURL = NSURL(string: url) else { return }
        guard let resp = HTTPClient.sharedHTTPClient().download(validURL) else { return}
        
        resp.onBegin() {
            dispatch_async(dispatch_get_main_queue()) {
                self._download_progress.hidden = false
                self._wake_up_field.hidden = true
            }
        }
        
        resp.onProcess() { (progress) in
            dispatch_async(dispatch_get_main_queue()) {
                self._download_progress_field.hidden = false
                self._download_progress_field.text = progress.description
                self._download_progress.setProgress(progress.progress, animated: true)
            }
        }
        
        resp.onDownloadComplete() { url in
            print(url)
        }
        
        resp.onComplete() { (resp, error) in
            guard error == nil else { print(error?.localizedDescription) ; return }
            
            dispatch_async(dispatch_get_main_queue()) {
                self._download_progress.hidden = true
                self._download_progress_field.hidden = true
                
                if is_wake_up_by_background_task {
                    self.handleBackgroundTask()
                }
            }
            
            print(resp.statusCode)
            print(resp.text)
            
            // Don't forget to close response
            resp.close()
        }
        
        resp.tick()
        
        // TODO: How to force system kill me???
    }
    
    func handleBackgroundTask() {
        self._download_progress.hidden = true
        self._download_progress_field.hidden = true
        self._wake_up_field.hidden = false
        self._wake_up_field.text = "Wake up by backgroud task"
    }
}

