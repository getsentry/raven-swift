//
//  ViewController.swift
//  Raven-Swift
//
//  Created by Tommy Mikalsen on 03.09.14.
//

import UIKit
import Raven

class ViewController: UIViewController {
                            
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func sendMessage() {
        RavenClient.sharedClient?.captureMessage("Raven message test")
    }

    
    @IBAction func raiseUnhandledException() {
        NSException(name: "Raven test exception", reason: "No reason", userInfo: nil).raise()
    }
}

