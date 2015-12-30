//
//  RavenClient.swift
//  Raven-Swift
//
//  Created by Tommy Mikalsen on 03.09.14.
//

import Foundation

#if os(iOS) || os(tvOS)
    import UIKit
#endif

let userDefaultsKey = "nl.mixedCase.RavenClient.Exceptions"
let sentryProtocol = "4"
let sentryClient = "raven-swift/0.4.0"

public enum RavenLogLevel: String {
    case Debug = "debug"
    case Info = "info"
    case Warning = "warning"
    case Error = "error"
    case Fatal = "fatal"
}

private var _RavenClientSharedInstance : RavenClient?

public class RavenClient : NSObject {
    //MARK: - Properties
    public var extra: [String: AnyObject]
    public var tags: [String: AnyObject]
    public var user: [String: AnyObject]?
    public let logger: String?

    internal let config: RavenConfig

    private var dateFormatter : NSDateFormatter {
        let dateFormatter = NSDateFormatter()
        dateFormatter.timeZone = NSTimeZone(name: "UTC")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return dateFormatter
    }


    //MARK: - Init


    /**
    Get the shared RavenClient instance
    */
    public class var sharedClient: RavenClient? {
        return _RavenClientSharedInstance
    }


    /**
    Initialize the RavenClient

    :param: config  RavenConfig object
    :param: extra  extra data that will be sent with logs
    :param: tags  extra tags that will be added to logs
    :param: logger  Name of the logger
    */
    public init(config: RavenConfig, extra: [String : AnyObject], tags: [String: AnyObject], logger: String?) {
        self.config = config
        self.extra = extra
        self.tags = tags
        self.logger = logger

        super.init()
        setDefaultTags()
    }


    /**
    Initialize the RavenClient

    :param: config  RavenConfig object
    :param: extra  extra data that will be sent with logs
    :param: tags  extra tags that will be added to logs
    */
    public convenience init(config: RavenConfig, extra: [String: AnyObject], tags: [String: AnyObject]) {
        self.init(config: config, extra: extra, tags: tags, logger: nil)
    }


    /**
    Initialize the RavenClient

    :param: config  RavenConfig object
    :param: extra  extra data that will be sent with logs
    */
    public convenience init(config: RavenConfig, extra: [String: AnyObject]) {
        self.init(config: config, extra: extra, tags: [:], logger: nil)
    }


    /**
    Initialize the RavenClient

    :param: config  RavenConfig object
    */
    public convenience init(config: RavenConfig) {
        self.init(config: config, extra: [:], tags: [:], logger: nil)
    }


    /**
    Initialize a RavenClient from the DSN string

    :param: extra  extra data that will be sent with logs
    :param: tags  extra tags that will be added to logs
    :param: logger  Name of the logger

    :returns: The RavenClient instance
    */
    public class func clientWithDSN(DSN: String, extra: [String: AnyObject], tags: [String: AnyObject], logger: String?) -> RavenClient? {
        if let config = RavenConfig(DSN: DSN) {
            let client = RavenClient(config: config, extra: extra, tags: tags, logger: logger)

            if (_RavenClientSharedInstance == nil) {
                _RavenClientSharedInstance = client
            }

            return client
        }
        else {
            print("Invalid DSN: \(DSN)!")
            return nil
        }
    }


    /**
    Initialize a RavenClient from the DSN string

    :param: extra  extra data that will be sent with logs
    :param: tags  extra tags that will be added to logs

    :returns: The RavenClient instance
    */
    public class func clientWithDSN(DSN: String, extra: [String: AnyObject], tags: [String: AnyObject]) -> RavenClient? {
        return RavenClient.clientWithDSN(DSN, extra: extra, tags: tags, logger: nil)
    }


    /**
    Initialize a RavenClient from the DSN string

    :param: extra  extra data that will be sent with logs

    :returns: The RavenClient instance
    */
    public class func clientWithDSN(DSN: String, extra: [String: AnyObject]) -> RavenClient? {
        return RavenClient.clientWithDSN(DSN, extra: extra, tags: [:])
    }


    /**
    Initialize a RavenClient from the DSN string

    :returns: The RavenClient instance
    */
    public class func clientWithDSN(DSN: String) -> RavenClient? {
        return RavenClient.clientWithDSN(DSN, extra: [:])
    }


    //MARK: - Messages


    /**
    Capture a message

    :param: message  The message to be logged
    */
    public func captureMessage(message : String, method: String? = __FUNCTION__ , file: String? = __FILE__, line: Int = __LINE__) {
        self.captureMessage(message, level: .Info, additionalExtra:[:], additionalTags:[:], method:method, file:file, line:line)
    }


    /**
    Capture a message

    :param: message  The message to be logged
    :param: level  log level
    */
    public func captureMessage(message: String, level: RavenLogLevel, method: String? = __FUNCTION__ , file: String? = __FILE__, line: Int = __LINE__){
        self.captureMessage(message, level: level, additionalExtra:[:], additionalTags:[:], method:method, file:file, line:line)
    }


    /**
    Capture a message

    :param: message  The message to be logged
    :param: level  log level
    :param: additionalExtra  Additional data that will be sent with the log
    :param: additionalTags  Additional tags that will be sent with the log
    */
    public func captureMessage(message: String, level: RavenLogLevel, additionalExtra:[String: AnyObject], additionalTags: [String: AnyObject], method:String? = __FUNCTION__, file:String? = __FILE__, line:Int = __LINE__) {
        var stacktrace : [AnyObject] = []
        var culprit : String = ""

        if (method != nil && file != nil && line > 0) {
            let filename = (file! as NSString).lastPathComponent;
            let frame = ["filename" : filename, "function" : method!, "lineno" : line]
            stacktrace = [frame]
            culprit = "\(method!) in \(filename)"
        }

        let data = self.prepareDictionaryForMessage(message, level:level, additionalExtra:additionalExtra, additionalTags:additionalTags, culprit:culprit, stacktrace:stacktrace, exception:[:])

        self.sendDictionary(data)
    }


    //MARK: - Error

    /**
    Capture an error

    :param: error  The error to capture
    */
    public func captureError(error : NSError, method: String? = __FUNCTION__, file: String? = __FILE__, line: Int = __LINE__) {
        RavenClient.sharedClient?.captureMessage("\(error)", level: .Error, method: method, file: file, line: line )
    }


    //MARK: - ErrorType

    /**
    Capture an error that conforms the ErrorType protocol

    :param: error  The error to capture
    */
    public func captureError<E where E:ErrorType, E:StringLiteralConvertible>(error: E, method: String? = __FUNCTION__, file: String? = __FILE__, line: Int = __LINE__) {
        RavenClient.sharedClient?.captureMessage("\(error)", level: .Error, method: method, file: file, line: line )
    }


    //MARK: - Exception


    /**
    Capture an exception. Automatically sends to the server

    :param: exception  The exception to be captured.
    */
    public func captureException(exception: NSException) {
        self.captureException(exception, sendNow:true)
    }


    /**
    Capture an uncaught exception. Does not automatically send to the server

    :param: exception  The exception to be captured.
    */
    public func captureUncaughtException(exception: NSException) {
        self.captureException(exception, sendNow: false)
    }


    /**
    Capture an exception

    :param: exception  The exception to be captured.
    :param: additionalExtra  Additional data that will be sent with the log
    :param: additionalTags  Additional tags that will be sent with the log
    :param: sendNow  Control whether the exception is sent to the server now, or when the app is next opened
    */
    public func captureException(exception:NSException, additionalExtra:[String: AnyObject], additionalTags: [String: AnyObject], sendNow:Bool) {
        let message = "\(exception.name): \(exception.reason!)"
        let exceptionDict = ["type": exception.name, "value": exception.reason!]

        let callStack = exception.callStackSymbols

        var stacktrace = [[String:String]]()

        if (!callStack.isEmpty) {
            for call in callStack {
                stacktrace.append(["function": call])
            }
        }

        let data = self.prepareDictionaryForMessage(message, level: .Fatal, additionalExtra: additionalExtra, additionalTags: additionalTags, culprit: nil, stacktrace: stacktrace, exception: exceptionDict)

        if let JSON = self.encodeJSON(data) {
            if (!sendNow) {
                // We can't send this exception to Sentry now, e.g. because the app is killed before the
                // connection can be made. So, save it into NSUserDefaults.
                let JSONString = NSString(data: JSON, encoding: NSUTF8StringEncoding)
                var reports = NSUserDefaults.standardUserDefaults().objectForKey(userDefaultsKey) as? [AnyObject]
                if (reports != nil) {
                    reports!.append(JSONString!)
                } else {
                    reports = [JSONString!]
                }

                NSUserDefaults.standardUserDefaults().setObject(reports, forKey:userDefaultsKey)
                NSUserDefaults.standardUserDefaults().synchronize()
            } else {
                self.sendJSON(JSON)
            }
        }
    }


    /**
    Capture an exception

    :param: exception  The exception to be captured.
    :param: sendNow  Control whether the exception is sent to the server now, or when the app is next opened
    */
    public func captureException(exception: NSException, method:String? = __FUNCTION__, file:String? = __FILE__, line:Int = __LINE__, sendNow:Bool = false) {
        let message = "\(exception.name): \(exception.reason!)"
        let exceptionDict = ["type": exception.name, "value": exception.reason ?? ""]

        var stacktrace = [[String:AnyObject]]()

        if (method != nil && file != nil && line > 0) {
            var frame = [String: AnyObject]()
            frame = ["filename" : (file! as NSString).lastPathComponent, "function" : method!, "lineno" : line]
            stacktrace = [frame]
        }

        let callStack = exception.callStackSymbols

        for call in callStack {
            stacktrace.append(["function": call])
        }

        let data = self.prepareDictionaryForMessage(message, level: .Fatal, additionalExtra: [:], additionalTags: [:], culprit: nil, stacktrace: stacktrace, exception: exceptionDict)

        if let JSON = self.encodeJSON(data) {
            if (!sendNow) {
                // We can't send this exception to Sentry now, e.g. because the app is killed before the
                // connection can be made. So, save the JSON payload into NSUserDefaults.
                let JSONString = NSString(data: JSON, encoding: NSUTF8StringEncoding)
                var reports : [AnyObject]? = NSUserDefaults.standardUserDefaults().arrayForKey(userDefaultsKey)
                if (reports != nil) {
                    reports!.append(JSONString!)
                } else {
                    reports = [JSONString!]
                }
                NSUserDefaults.standardUserDefaults().setObject(reports, forKey:userDefaultsKey)
                NSUserDefaults.standardUserDefaults().synchronize()
            } else {
                self.sendJSON(JSON)
            }
        }
    }


    /**
    Automatically capture any uncaught exceptions
    */
    public func setupExceptionHandler() {
        UncaughtExceptionHandler.registerHandler(self)
        NSSetUncaughtExceptionHandler(exceptionHandlerPtr)

        // Process saved crash reports
        let reports : [AnyObject]? = NSUserDefaults.standardUserDefaults().arrayForKey(userDefaultsKey)
        if (reports != nil && reports?.count > 0) {
            for data in reports! {
                let JSONString = data as! String
                let JSON = JSONString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
                self.sendJSON(JSON)
            }
            NSUserDefaults.standardUserDefaults().setObject([], forKey: userDefaultsKey)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }


    //MARK: - Internal methods
    internal func setDefaultTags() {
        if tags["Build version"] == nil {
            if let buildVersion: AnyObject = NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"]
            {
                tags["Build version"] = buildVersion as? String
            }
        }

        #if os(iOS) || os(tvOS)
            if (tags["OS version"] == nil) {
                tags["OS version"] = UIDevice.currentDevice().systemVersion
            }

            if (tags["Device model"] == nil) {
                tags["Device model"] = UIDevice.currentDevice().model
            }
        #endif

    }

    internal func sendDictionary(dict: [String: AnyObject]) {
        let JSON = self.encodeJSON(dict)
        self.sendJSON(JSON)
    }

    internal func generateUUID() -> String {
        let uuid = NSUUID().UUIDString
        let res = uuid.stringByReplacingOccurrencesOfString("-", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
        return res
    }

    private func prepareDictionaryForMessage(message: String,
        level: RavenLogLevel,
        additionalExtra: [String : AnyObject],
        additionalTags: [String : AnyObject],
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

        let returnDict : [String: AnyObject] = ["event_id" : self.generateUUID(),
            "project"   : self.config.projectId!,
            "timestamp" : self.dateFormatter.stringFromDate(NSDate()),
            "level"     : level.rawValue,
            "platform"  : "swift",
            "extra"     : extra,
            "tags"      : tags,
            "logger"    : self.logger ?? "",
            "message"   : message,
            "culprit"   : culprit ?? "",
            "stacktrace": stacktraceDict,
            "exception" : exception,
            "user"      : user ?? ""]

        return returnDict
    }

    private func encodeJSON(obj: AnyObject) -> NSData? {
        do {
            return try NSJSONSerialization.dataWithJSONObject(obj, options: [])
        } catch _ {
            return nil
        }
    }

    private func sendJSON(JSON: NSData?) {
        let header = "Sentry sentry_version=\(sentryProtocol), sentry_client=\(sentryClient), sentry_timestamp=\(NSDate.timeIntervalSinceReferenceDate()), sentry_key=\(self.config.publicKey), sentry_secret=\(self.config.secretKey)"

        #if DEBUG
        println(header)
        #endif

        let request = NSMutableURLRequest(URL: self.config.serverUrl)
        request.HTTPMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("\(JSON?.length)", forHTTPHeaderField: "Content-Length")
        request.HTTPBody = JSON
        request.setValue("\(header)", forHTTPHeaderField:"X-Sentry-Auth")
        
        let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        let task = session.dataTaskWithRequest(request, completionHandler: {
            (_, response, error) in
            if let error = error {
                let userInfo = error.userInfo as! [String: AnyObject]
                let errorKey: AnyObject? = userInfo[NSURLErrorFailingURLStringErrorKey]
                print("Connection failed! Error - \(error.localizedDescription) \(errorKey!)")

            } else if let response = response {
                #if DEBUG
                    println("Response from Sentry: \(response)")
                #endif
            }
            print("JSON sent to Sentry")
        })
        task.resume()
        
        #if DEBUG
        let debug = NSString(data: JSON!, encoding: NSUTF8StringEncoding)
        println(debug)
        #endif
    }
}