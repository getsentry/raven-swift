//
//  RavenClient.swift
//  Raven-Swift
//
//  Created by Tommy Mikalsen on 03.09.14.
//

import Foundation
import UIKit

let userDefaultsKey = "nl.mixedCase.RavenClient.Exceptions"
let sentryProtocol = "4"
let sentryClient = "raven-swift/0.1.0"

enum RavenLogLevel: String {
    case kRavenLogLevelDebug = "debug"
    case kRavenLogLevelDebugInfo = "info"
    case kRavenLogLevelDebugWarning = "warning"
    case kRavenLogLevelDebugError = "error"
    case kRavenLogLevelDebugFatal = "fatal"
}

private var _RavenClientSharedInstance : RavenClient?

class RavenClient : NSObject, NSURLConnectionDelegate, NSURLConnectionDataDelegate  {
    var extra : [String: AnyObject]
    var tags : [String : String]
    let logger : String?
    internal let config : RavenConfig
    private var receivedData : NSMutableData?
    private var dateFormatter : NSDateFormatter {
        var dateFormatter = NSDateFormatter()
        dateFormatter.timeZone = NSTimeZone(name: "UTC")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return dateFormatter
    }
    class var sharedClient : RavenClient? {
        return _RavenClientSharedInstance
    }
   
    init(config: RavenConfig, extra: [String : AnyObject], tags: [String: String], logger : String?)
    {
        self.config = config
        self.extra = extra
        self.tags = tags
        self.logger = logger
    }
    
    convenience init(config: RavenConfig, extra: [String: AnyObject], tags: [String: String])
    {
        self.init(config: config, extra: extra, tags: tags, logger: nil)
        
    }
    
    convenience init(config: RavenConfig, extra: [String: AnyObject])
    {
        self.init(config: config, extra: extra, tags: [:], logger: nil)
        
    }
    
    convenience init(config: RavenConfig)
    {
        self.init(config: config, extra: [:], tags: [:], logger: nil)
    }

    class func clientWithDSN(DSN: String, extra: [String: AnyObject], tags: [String: String], logger: String?) -> RavenClient?
    {
        var config = RavenConfig()
        if (!config.setDSN(DSN))
        {
            println("Invalid DSN \(DSN)!")
            return nil
        }
        
        var client = RavenClient(config: config, extra: extra, tags: tags, logger: logger)
        client.setDefaultTags()
        
        if (_RavenClientSharedInstance == nil) {
            _RavenClientSharedInstance = client
        }
        
        return client
    }
    
    class func clientWithDSN(DSN: String, extra: [String: AnyObject], tags: [String: String]) -> RavenClient?
    {
        return RavenClient.clientWithDSN(DSN, extra: extra, tags: tags, logger: nil)
    }
    
    class func clientWithDSN(DSN: String, extra: [String: AnyObject]) -> RavenClient?
    {
        return RavenClient.clientWithDSN(DSN, extra: extra, tags: [:])
    }
    
    class func clientWithDSN(DSN: String) -> RavenClient?
    {
        return RavenClient.clientWithDSN(DSN, extra: [:])
    }

    func setDefaultTags() {
        let build: String? = tags["Build version"]
        if (build == nil) {
            if let buildVersion: AnyObject = NSBundle.mainBundle().infoDictionary["CFBundleShortVersionString"]
            {
                tags["Build version"] = buildVersion as? String
            }
        }
        
        #if os(iOS)
            var osVersion = tags["OS version"] as String?
            if (osVersion == nil) {
                osVersion = UIDevice.currentDevice().systemVersion
                tags["OS version"] = osVersion
            }
            
            var deviceModel = tags["Device model"] as String?
            if (deviceModel == nil) {
                deviceModel = UIDevice.currentDevice().model
                tags["Device model"] = deviceModel
            }
        #endif

    }

    func captureMessage(message : String)
    {
        self.captureMessage(message, level: RavenLogLevel.kRavenLogLevelDebugInfo)
    }
    
    func captureMessage(message : String, level: RavenLogLevel)
    {
        self.captureMessage(message, level: level, method:nil, file:nil, line:0)
        
    }
    
    func captureMessage(message: String, level: RavenLogLevel, method: String?, file: String?, line: Int){
    
        self.captureMessage(message, level: level, additionalExtra:[:], additionalTags:[:], method:method, file:file, line:line)
    }
    
    func captureMessage(message: String, level:RavenLogLevel, additionalExtra: [String: AnyObject], additionalTags:[String: String]) {
        self.captureMessage(message,level: level, additionalExtra: additionalExtra, additionalTags: additionalTags, method:nil, file:nil, line:0)
    }
    
    func captureMessage(message: String, level: RavenLogLevel, additionalExtra:[String: AnyObject], additionalTags: [String: String], method:String?, file:String?, line:Int) {
        var stacktrace : [AnyObject] = []
        
        if (method != nil && file != nil && line > 0) {
            var frame = [String: NSObject]()
            frame = ["filename" : file!.lastPathComponent, "function" : method!, "lineno" : line]
            stacktrace = [frame]
        }
        
        let data = self.prepareDictionaryForMessage(message, level:level, additionalExtra:additionalExtra, additionalTags:additionalTags, culprit:file ?? "", stacktrace:stacktrace, exception:[:])
        
        self.sendDictionary(data)
    }
    
    func captureError(error : NSError, method: String?, file: String?, line: Int){
        RavenClient.sharedClient?.captureMessage("\(error)", level: .kRavenLogLevelDebugError, method: method, file: file, line: line )
    }
    
    func captureError(error : NSError){
        RavenClient.sharedClient?.captureMessage("\(error)", level: .kRavenLogLevelDebugError, method: nil, file: nil, line: 0 )
    }
    
    func captureException(exception :NSException) {
        self.captureException(exception, sendNow:true)
    }
    
    func captureException(exception: NSException, sendNow: Bool) {
        self.captureException(exception, additionalExtra:[:], additionalTags:[:], sendNow:sendNow)
    }
    
    func captureException(exception:NSException, additionalExtra:[String: AnyObject], additionalTags: [String: String], sendNow:Bool) {
        
        let message = "\(exception.name): \(exception.reason!)"
        let exceptionDict = ["type": exception.name, "value": exception.reason!]
        
        let callStack = exception.callStackSymbols
        
        var stacktrace = [[String:String]]()
        
        if (!callStack.isEmpty)
        {
            for call in callStack
            {
                stacktrace.append(["function": call as String])
            }
        }
        
        let data = self.prepareDictionaryForMessage(message, level: .kRavenLogLevelDebugFatal, additionalExtra: additionalExtra, additionalTags: additionalTags, culprit: nil, stacktrace: stacktrace, exception: exceptionDict)
        if let JSON = self.encodeJSON(data)
        {
            if (!sendNow) {
                // We can't send this exception to Sentry now, e.g. because the app is killed before the
                // connection can be made. So, save it into NSUserDefaults.
                let JSONString = NSString(data: JSON, encoding: NSUTF8StringEncoding)
                var reports = NSUserDefaults.standardUserDefaults().objectForKey(userDefaultsKey) as? [AnyObject]
                if (reports != nil) {
                    reports!.append(JSONString)
                } else {
                    reports = [JSONString]
                }
                
                NSUserDefaults.standardUserDefaults().setObject(reports, forKey:userDefaultsKey)
                NSUserDefaults.standardUserDefaults().synchronize()
                println(NSUserDefaults.standardUserDefaults().dictionaryRepresentation())
            } else {
                self.sendJSON(JSON)
            }
        }
        
    }
    
    func captureException(exception: NSException, method:String?, file:String?, line:Int, sendNow:Bool) {
        let message = "\(exception.name): \(exception.reason!)"
        let exceptionDict = ["type": exception.name, "value": exception.reason? ?? ""]
        
        
        var stacktrace = [[String:AnyObject]]()
        
        if (method != nil && file != nil && line > 0) {
            var frame = [String: AnyObject]()
            frame = ["filename" : file!.lastPathComponent, "function" : method!, "lineno" : line]
            stacktrace = [frame]
        }

        let callStack = exception.callStackSymbols

        for call in callStack {
            stacktrace.append(["function": call as String])
        }
        
        let data = self.prepareDictionaryForMessage(message, level: .kRavenLogLevelDebugFatal, additionalExtra: [:], additionalTags: [:], culprit: nil, stacktrace: stacktrace, exception: exceptionDict)
        
        if let JSON = self.encodeJSON(data)
        {
            if (!sendNow) {
                // We can't send this exception to Sentry now, e.g. because the app is killed before the
                // connection can be made. So, save it into NSUserDefaults.
                let JSONString = NSString(data: JSON, encoding: NSUTF8StringEncoding)
                var reports : [AnyObject]? = NSUserDefaults.standardUserDefaults().arrayForKey(userDefaultsKey)
                if (reports != nil) {
                    reports!.append(JSONString)
                } else {
                    reports = [JSONString]
                }
                NSUserDefaults.standardUserDefaults().setObject(reports, forKey:userDefaultsKey)
                NSUserDefaults.standardUserDefaults().synchronize()
                println(NSUserDefaults.standardUserDefaults().dictionaryRepresentation())
            } else {
                self.sendJSON(JSON)
            }
        }
    }

    func setupExceptionHandler() {
    
        NSSetUncaughtExceptionHandler(exceptionHandlerPtr)
        
        // Process saved crash reports
        var reports : [AnyObject]? = NSUserDefaults.standardUserDefaults().arrayForKey(userDefaultsKey)
        if (reports != nil && reports?.count > 0) {
            for data in reports! {
                let JSONString = data as String
                let JSON = JSONString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
                self.sendJSON(JSON)
            }
            NSUserDefaults.standardUserDefaults().setObject([], forKey: userDefaultsKey)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }

    func connection(connection: NSURLConnection, didFailWithError error: NSError) {
        let userInfo: [String: AnyObject] = error.userInfo as [String: AnyObject]
        let errorKey: AnyObject? = userInfo[NSURLErrorFailingURLStringErrorKey]
        println("Connection failed! Error - \(error.localizedDescription) \(errorKey)")
    }
    
    func connection(connection: NSURLConnection, didReceiveResponse response: NSURLResponse) {
        self.receivedData?.length = 0
    }
    
    func connection(connection: NSURLConnection, didReceiveData data: NSData) {
        self.receivedData?.appendData(data)
    }
    
    func connectionDidFinishLoading(connection: NSURLConnection) {
        println("JSON sent to Sentry")
    }
    
    internal func sendDictionary(dict: [String: AnyObject]) {
        var error : NSError? = nil;
        let JSON = self.encodeJSON(dict)
        self.sendJSON(JSON)
    }
    
    internal func generateUUID() -> String {
        let uuid = NSUUID.UUID().UUIDString
        let res = uuid.stringByReplacingOccurrencesOfString("-", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
        return res
    }
    
    private func prepareDictionaryForMessage(message: String,
        level: RavenLogLevel,
        additionalExtra: [String : AnyObject],
        additionalTags: [String : String],
        culprit:String?,
        stacktrace:[AnyObject],
        exception:[String : String]) -> [String: AnyObject]
    {
        
        let stacktraceDict : [String : [AnyObject]] = ["frames": stacktrace]
        
        var extra = self.extra
        for entry in additionalExtra {
            extra[entry.0] = entry.1
        }
        
        var tags = self.tags;
        for entry in additionalTags {
            tags[entry.0] = entry.1
        }
        
        var returnDict : [String: AnyObject] = ["event_id" : self.generateUUID(),
            "project" : self.config.projectId!,
            "timestamp" : self.dateFormatter.stringFromDate(NSDate()),
            "level" : level.toRaw(),
            "platform": "swift",
            "extra": extra,
            "tags" : tags,
            "logger" : self.logger ?? "",
            "message" : message,
            "culprit": culprit ?? "",
            "stacktrace": stacktraceDict,
            "exception" : exception]
        
        return returnDict
    }
    
    private func encodeJSON(obj: AnyObject) -> NSData? {
        let data = NSJSONSerialization.dataWithJSONObject(obj, options: nil , error:nil)
        return data
    }
    
    private func sendJSON(JSON: NSData?)
    {
        
        let header = "Sentry sentry_version=\(sentryProtocol), sentry_client=\(sentryClient), sentry_timestamp=\(NSDate.timeIntervalSinceReferenceDate()), sentry_key=\(self.config.publicKey!), sentry_secret=\(self.config.secretKey!)"
        
        println(header)
        
        var request = NSMutableURLRequest(URL: self.config.serverUrl!)
        request.HTTPMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("\(JSON?.length)", forHTTPHeaderField: "Content-Length")
        request.HTTPBody = JSON
        request.setValue("\(header)", forHTTPHeaderField:"X-Sentry-Auth")
        
        let connection = NSURLConnection(request: request, delegate: self)
        self.receivedData = NSMutableData()
        let debug = NSString(data: JSON!, encoding: NSUTF8StringEncoding)
        println(debug)
    }
}