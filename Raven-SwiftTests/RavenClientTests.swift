//
//  RavenClientTests.swift
//  Raven-Swift
//
//  Created by Tommy Mikalsen on 06.09.14.
//

import XCTest
import Sentry

let testDSN = "http://public:secret@example.com/foo"

class MockRavenClient : RavenClient {
    var lastEvent : [String: AnyObject] = [:]
    var numEvents : Int = 0

    override func sendDictionary(dict: [String : AnyObject]) {
        lastEvent = dict
        numEvents++
    }
}


class RavenClientTests: XCTestCase {

    var client : MockRavenClient?
    var config = RavenConfig(DSN: testDSN)
    
    override func setUp() {
        client =  MockRavenClient(config: config!, extra: [:], tags: [:], logger: nil)
        
    }
    func testGenerateUUID()
    {
        let uuid = client!.generateUUID()
        XCTAssert(count(uuid) == 32 , "Invalid value for UUID returned: \(uuid)")
    }
    
    func testCaptureMessageWithOnlyMessage()
    {
        self.client!.captureMessage("An example message")
        var lastEvent = self.client!.lastEvent
        
        XCTAssertNotNil(lastEvent["event_id"], "Missing event_id")
        XCTAssertNotNil(lastEvent["message"], "Missing message")
        XCTAssertNotNil(lastEvent["project"], "Missing project")
        XCTAssertNotNil(lastEvent["level"], "Missing level")
        XCTAssertNotNil(lastEvent["timestamp"], "Missing timestamp")
       
        let message: AnyObject! = lastEvent["message"]
        XCTAssertEqual(message as String, "An example message", "Invalid value for message: \(message)")
        
        let project: AnyObject! = lastEvent["project"]
        XCTAssertEqual(project as String, self.client!.config.projectId!, "Invalid value for project: \(project)")
        
        let level: AnyObject! = lastEvent["level"]
        XCTAssertEqual(level as String, "info", "Invalid value for level: \(level) ")
    }
    
    func testCaptureMessageWithMessageAndLevel()
    {
        self.client!.captureMessage("An example message", level: .kRavenLogLevelDebugWarning)
        var lastEvent = self.client!.lastEvent
        
        XCTAssertNotNil(lastEvent["event_id"], "Missing event_id")
        XCTAssertNotNil(lastEvent["message"], "Missing message")
        XCTAssertNotNil(lastEvent["project"], "Missing project")
        XCTAssertNotNil(lastEvent["level"], "Missing level")
        XCTAssertNotNil(lastEvent["timestamp"], "Missing timestamp")
        XCTAssertNotNil(lastEvent["platform"], "Missing platform")
        
        let message: AnyObject! = lastEvent["message"]
        XCTAssertEqual(message as String, "An example message", "Invalid value for message: \(message)")
        
        let project: AnyObject! = lastEvent["project"]
        XCTAssertEqual(project as String, self.client!.config.projectId!, "Invalid value for project: \(project)")
        
        let level: AnyObject! = lastEvent["level"]
        XCTAssertEqual(level as String, "warning", "Invalid value for level: \(level) ")
        
        let platform: AnyObject! = lastEvent["platform"]
        XCTAssertEqual(platform as String, "swift", "Invalid value for platform: \(platform)")
    }
    
    
    func testCaptureMessageWithMessageAndLevelAndMethodAndFileAndLine()
    {
        self.client!.captureMessage("An example message", level:.kRavenLogLevelDebugWarning, method:"method name", file:"filename", line:34)
        var lastEvent = self.client!.lastEvent

        XCTAssertNotNil(lastEvent["event_id"], "Missing event_id")
        XCTAssertNotNil(lastEvent["message"], "Missing message")
        XCTAssertNotNil(lastEvent["project"], "Missing project")
        XCTAssertNotNil(lastEvent["level"], "Missing level")
        XCTAssertNotNil(lastEvent["timestamp"], "Missing timestamp")
        XCTAssertNotNil(lastEvent["platform"], "Missing platform")
        XCTAssertNotNil(lastEvent["stacktrace"], "Missing stacktrace")
        
        let message: AnyObject! = lastEvent["message"]
        XCTAssertEqual(message as String, "An example message", "Invalid value for message: \(message)")
        
        let project: AnyObject! = lastEvent["project"]
        XCTAssertEqual(project as String, self.client!.config.projectId!, "Invalid value for project: \(project)")
        
        let level: AnyObject! = lastEvent["level"]
        XCTAssertEqual(level as String, "warning", "Invalid value for level: \(level) ")
        
        let platform: AnyObject! = lastEvent["platform"]
        XCTAssertEqual(platform as String, "swift", "Invalid value for platform: \(platform)")
    }
    
    func testCaptureMessageWithMessageAndLevelAndExtraAndTags()
    {
        self.client!.captureMessage("An example message", level:.kRavenLogLevelDebugWarning, additionalExtra:["key" : "extra value"],
        additionalTags:["key" : "tag value"])
        
        var lastEvent = self.client!.lastEvent
        
        XCTAssertNotNil(lastEvent["event_id"], "Missing event_id")
        XCTAssertNotNil(lastEvent["message"], "Missing message")
        XCTAssertNotNil(lastEvent["project"], "Missing project")
        XCTAssertNotNil(lastEvent["level"], "Missing level")
        XCTAssertNotNil(lastEvent["timestamp"], "Missing timestamp")
        XCTAssertNotNil(lastEvent["platform"], "Missing platform")
        XCTAssertNotNil(lastEvent["extra"], "Missing extra")
        XCTAssertNotNil(lastEvent["tags"], "Missing tags")
        
        let extra: [String: AnyObject] = lastEvent["extra"]! as [String: AnyObject]
        let extraValueForKey: AnyObject! = extra["key"]
        XCTAssertEqual(extraValueForKey as String, "extra value", "Missing extra data");
        
        let tags: [String: AnyObject] = lastEvent["tags"]! as [String: AnyObject]
        let tagValueForKey: AnyObject! = tags["key"]
        XCTAssertEqual(tagValueForKey as String, "tag value", "Missing tags data");
        
        let message: AnyObject! = lastEvent["message"]
        XCTAssertEqual(message as String, "An example message", "Invalid value for message: \(message)")
        
        let project: AnyObject! = lastEvent["project"]
        XCTAssertEqual(project as String, self.client!.config.projectId!, "Invalid value for project: \(project)")
        
        let level: AnyObject! = lastEvent["level"]
        XCTAssertEqual(level as String, "warning", "Invalid value for level: \(level) ")
        
        let platform: AnyObject! = lastEvent["platform"]
        XCTAssertEqual(platform as String, "swift", "Invalid value for platform: \(platform)")
    }
    
    func testClientWithExtraAndTags()
    {
        var clientWithExtraAndTags = MockRavenClient(config: config!, extra: ["key" : "value"], tags: ["key" : "value"], logger: nil)
        
        clientWithExtraAndTags.captureMessage("An example message",level:.kRavenLogLevelDebugWarning, additionalExtra:["key2" : "extra value"], additionalTags:["key2" : "tag value"])
        
        var lastEvent = clientWithExtraAndTags.lastEvent
        
        XCTAssertNotNil(lastEvent["extra"], "Missing extra")
        XCTAssertNotNil(lastEvent["tags"], "Missing tags")
        
        let extra: [String: AnyObject] = lastEvent["extra"]! as [String: AnyObject]
        let extraValueForKey: AnyObject! = extra["key"]
        let extraValueForKey2: AnyObject! = extra["key2"]
        
        XCTAssertEqual(extraValueForKey as String, "value", "Missing extra data")
        XCTAssertEqual(extraValueForKey2 as String, "extra value", "Missing extra data")
        
        let tags: [String: String] = lastEvent["tags"]! as [String: String]
        let tagValueForKey: AnyObject! = tags["key"]
        let tagValueForKey2: AnyObject! = tags["key2"]
        let tagValueForOsVersion: AnyObject? = tags["OS version"]
        let tagValueForDeviceModel: AnyObject? = tags["Device model"]
        
        XCTAssertEqual(tagValueForKey as String, "value", "Missing tags data")
        XCTAssertEqual(tagValueForKey2 as String, "tag value", "Missing tags data")
        
        XCTAssertNotNil(tagValueForOsVersion, "Missing tags data")
        XCTAssertNotNil(tagValueForDeviceModel, "Missing tags data")
        
    }
    
    func testClientWithRewritingExtraAndTags()
    {
        var clientWithExtraAndTags = MockRavenClient(config: config!, extra: ["key" : "value"], tags: ["key" : "value"], logger: nil)
       
        clientWithExtraAndTags.captureMessage("An example message", level: .kRavenLogLevelDebugWarning, additionalExtra: ["key" : "extra value"], additionalTags: ["key": "tag value"])
        var lastEvent = clientWithExtraAndTags.lastEvent
        
        XCTAssertNotNil(lastEvent["extra"], "Missing extra")
        XCTAssertNotNil(lastEvent["tags"], "Missing tags")

        let extra: [String: AnyObject] = lastEvent["extra"]! as [String: AnyObject]
        let extraValueForKey: AnyObject! = extra["key"]
        XCTAssertEqual(extraValueForKey as String, "extra value", "Missing extra data")
        
        let tags: [String: String] = lastEvent["tags"]! as [String: String]
        let tagValueForKey: AnyObject! = tags["key"]
        XCTAssertEqual(tagValueForKey as String, "tag value", "Missing tags data")
    }
    
    func testClientWithLogger()
    {
        var clientWithExtraAndTags = MockRavenClient(config: config!, extra: ["key" : "value"], tags: ["key" : "value"], logger: "Logger value")
        
        clientWithExtraAndTags.captureMessage("An example message")
        
        var lastEvent = clientWithExtraAndTags.lastEvent
        
        let message: AnyObject! = lastEvent["message"]
        XCTAssertEqual(message as String, "An example message", "Invalid value for message: \(message)")
        
        let logger: AnyObject! = lastEvent["logger"]
        XCTAssertEqual(logger as String, "Logger value", "Invalid value for logger: \(logger)")
    }
}
