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

func += <KeyType, ValueType> (inout left: Dictionary<KeyType, ValueType>, right: Dictionary<KeyType, ValueType>) {
    for (k, v) in right {
        left.updateValue(v, forKey: k)
    }
}

public class RavenClient {

    // MARK: - Structs

    public struct RavenAuth {
        var serverURL: NSURL
        var publicKey: String
        var privateKey: String
        var projectID: String
    }


    // MARK: - Enums

    public enum LogLevel: CustomStringConvertible {
        case Debug, Info, Warning, Error, Fatal

        public var description: String {
            switch self {
            case .Debug: return "debug"
            case .Info: return "info"
            case .Warning: return "warning"
            case .Error: return "error"
            case .Fatal: return "fatal"
            }
        }
    }


    // MARK: - Singleton Instance

    public static let defaultInstance: RavenClient = RavenClient()


    // MARK: - Attributes

    private(set) var auth: RavenAuth?
    private var dateFormatter : NSDateFormatter {
        let dateFormatter = NSDateFormatter()
        dateFormatter.timeZone = NSTimeZone(name: "UTC")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return dateFormatter
    }

    public var debugMode: Bool = false
    public var tags: [String: AnyObject] = [:] {
        didSet {
            tags += generateDefaultTags()
        }
    }
    public var extra: [String: AnyObject]?
    public var user: [String: AnyObject]?
    public var logger: String?


    // MARK: - Public Interface

    public func setDSN(DSN: String) {
        guard let url = NSURL(string: DSN), host = url.host,  projectID = url.pathComponents?.last else { return }

        let publicKey: String = url.user ?? ""
        let privateKey: String = url.password ?? ""
        let port = url.port ?? ((url.scheme == "https") ? 443 : 80)
        let server: NSURL! = NSURL(string: "\(url.scheme)://\(host):\(port)")?
            .URLByAppendingPathComponent("api")
            .URLByAppendingPathComponent(projectID)
            .URLByAppendingPathComponent("store")
            .URLByAppendingPathComponent("/")

        auth = RavenAuth(serverURL: server, publicKey: publicKey, privateKey: privateKey, projectID: projectID)
    }

    /**
     Reports message to Sentry
    - parameter message: The message to be reported.
    - parameter level: The level to describe the message being reported.
    - parameter additionalExtra: Additional data to be sent with the message.
    - parameter additionalTags: Additional tags to be sent with the message.
    */
    public func captureMessage(message: String, level: LogLevel = .Info, additionalExtra: [String: AnyObject]? = nil, additionalTags: [String: AnyObject]? = nil, method: String? = #function, file: String? = #file, line: Int = #line) {
        var stacktrace: [AnyObject] = []
        var culprit: String = ""

        if let method = method, filePath = file where line > 0 {
            let fileName = (filePath as NSString).lastPathComponent
            let frame = ["filename" : fileName, "function" : method, "lineno" : line]
            stacktrace = [frame]
            culprit = "\(method) in \(fileName)"
        }

        let data = prepareMessage(message, level: level, additionalExtra: additionalExtra, additionalTags: additionalTags, culprit: culprit, stacktrace: stacktrace, exception: [:])
        self.sendDictionary(data)
    }


    //MARK: - Error

    /**
    Capture an error

    :param: error  The error to capture
    */
    public func captureError(error: NSError, method: String? = #function, file: String? = #file, line: Int = #line) {
        captureMessage("\(error)", level: .Error, method: method, file: file, line: line )
    }


    //MARK: - ErrorType

    /**
    Capture an error that conforms the ErrorType protocol

    :param: error  The error to capture
    */
    public func captureError<E where E: ErrorType, E: CustomStringConvertible>(error: E, method: String? = #function, file: String? = #file, line: Int = #line) {
        self.captureMessage("\(error)", level: .Error, method: method, file: file, line: line )
    }


    //MARK: - Exception


    /**
    Capture an exception. Automatically sends to the server

    :param: exception  The exception to be captured.
    */
    public func captureException(exception: NSException) {
        self.captureException(exception)
    }


    /**
    Capture an uncaught exception. Does not automatically send to the server

    :param: exception  The exception to be captured.
    */
    public func captureUncaughtException(exception: NSException) {
        self.captureException(exception)
    }


    /**
    Capture an exception

    :param: exception  The exception to be captured.
    :param: additionalExtra  Additional data that will be sent with the log
    :param: additionalTags  Additional tags that will be sent with the log
    :param: sendNow  Control whether the exception is sent to the server now, or when the app is next opened
    */
    public func captureException(exception: NSException, additionalExtra: [String: AnyObject]? = nil, additionalTags: [String: AnyObject]? = nil) {
        let message: String = "\(exception.name): \(exception.reason!)"
        let exceptionDict: [String: String] = ["type": exception.name, "value": exception.reason!]
        let stacktrace: [[String:String]] = exception.callStackSymbols.map { ["function": $0] }
        let data = prepareMessage(message, level: .Fatal, additionalExtra: additionalExtra, additionalTags: additionalTags, culprit: nil, stacktrace: stacktrace, exception: exceptionDict)

        var reports = NSUserDefaults.standardUserDefaults().objectForKey(userDefaultsKey) as? [[String: AnyObject]]
        if (reports != nil) {
            reports?.append(data)
        } else {
            reports = [data]
        }

        NSUserDefaults.standardUserDefaults().setObject(reports, forKey:userDefaultsKey)
        NSUserDefaults.standardUserDefaults().synchronize()
    }


    /**
    Automatically capture any uncaught exceptions
    */
    public func setupExceptionHandler() {
        UncaughtExceptionHandler.registerHandler(self)
        NSSetUncaughtExceptionHandler(exceptionHandlerPtr)

        // Process saved crash reports
        if let reports = NSUserDefaults.standardUserDefaults().arrayForKey(userDefaultsKey) as? [[String: AnyObject]] where reports.count > 0 {
            for data in reports {
                sendDictionary(data)
            }

            NSUserDefaults.standardUserDefaults().setObject([], forKey: userDefaultsKey)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }


    // MARK: - Internal methods

    internal func generateDefaultTags() -> [String: AnyObject] {
        var tags: [String: AnyObject] = [:]

        if tags["Build version"] == nil {
            if let buildVersion: String = NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] as? String {
                tags["Build version"] = buildVersion
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

        return tags
    }

    internal func sendDictionary(dict: [String: AnyObject]) {
        let JSON = self.encodeJSON(dict)
        self.sendJSON(JSON)
    }

    internal func generateUUID() -> String {
        let uuid = NSUUID().UUIDString
        let res = uuid.stringByReplacingOccurrencesOfString("-", withString: "", options: [.LiteralSearch], range: nil)
        return res
    }

    private func prepareMessage(message: String,
        level: LogLevel,
        additionalExtra: [String : AnyObject]?,
        additionalTags: [String : AnyObject]?,
        culprit:String?,
        stacktrace:[AnyObject],
        exception:[String: String]) -> [String: AnyObject]
    {

        let stacktraceDict: [String: [AnyObject]] = ["frames": stacktrace]

        var localExtra = self.extra ?? [:]
        localExtra += additionalExtra ?? [:]
        var localTags = self.tags
        localTags += additionalTags ?? [:]

        let returnDict: [String: AnyObject] = [
            "event_id": self.generateUUID(),
            "project": auth?.projectID ?? "",
            "timestamp": self.dateFormatter.stringFromDate(NSDate()),
            "level": level.description,
            "platform": "swift",
            "extra": localExtra,
            "tags": localTags,
            "logger": self.logger ?? "",
            "message": message,
            "culprit": culprit ?? "",
            "stacktrace": stacktraceDict,
            "exception": exception,
            "user": user ?? ""
        ]

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
        guard let auth = auth where debugMode == false else {
            guard let jsonString = String(data: JSON!, encoding: NSUTF8StringEncoding) else {
                print("Could not print JSON using UTF8 encoding")
                return
            }

            print(jsonString)
            return
        }

        let header = "Sentry sentry_version=\(sentryProtocol), sentry_client=\(sentryClient), sentry_timestamp=\(NSDate.timeIntervalSinceReferenceDate()), sentry_key=\(auth.publicKey), sentry_secret=\(auth.privateKey)"

        #if DEBUG
        println(header)
        #endif

        let request = NSMutableURLRequest(URL: auth.serverURL)
        request.HTTPMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("\(JSON?.length)", forHTTPHeaderField: "Content-Length")
        request.HTTPBody = JSON
        request.setValue("\(header)", forHTTPHeaderField:"X-Sentry-Auth")
        
        let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        let task = session.dataTaskWithRequest(request) { _, response, error in
            if let error = error {
                let userInfo = error.userInfo as! [String: AnyObject]
                let errorKey: AnyObject? = userInfo[NSURLErrorFailingURLStringErrorKey]
                print("Connection failed! Error - \(error.localizedDescription) \(errorKey!)")

            } else if let response = response {
                #if DEBUG
                    print("Response from Sentry: \(response)")
                #endif
            }
            print("JSON sent to Sentry")
        }
        task.resume()
    }
}