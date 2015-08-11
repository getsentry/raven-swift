//
//  RavenClientTests.swift
//  Raven-Swift
//
//  Created by Tommy Mikalsen on 06.09.14.
//

import XCTest

let testDSN = "http://public:secret@example.com/foo"

class MockRavenClient : RavenClient {
    var lastEvent: [String: AnyObject] = [:]
    var numEvents = 0
    
    override func sendDictionary(dict: [String : AnyObject]) {
        lastEvent = dict
        numEvents++
    }
}


class RavenClientTests: XCTestCase {
    
    var client: MockRavenClient?
    var config = RavenConfig(DSN: testDSN)
    
    override func setUp() {
        client = MockRavenClient(config: config!, extra: [:], tags: [:], logger: nil)
    }
    
    
    func testGenerateUUID() {
        let uuid = client!.generateUUID()
        XCTAssert(count(uuid) == 32 , "Invalid value for UUID returned: \(uuid)")
    }
    
    func testCaptureMessageWithOnlyMessage() {
        if let client = client {
            
            let testMessage = "An example message"
            client.captureMessage(testMessage)
            let lastEvent = client.lastEvent
            
            XCTAssertNotNil(lastEvent["event_id"], "Missing event_id")
            XCTAssertNotNil(lastEvent["message"], "Missing message")
            XCTAssertNotNil(lastEvent["project"], "Missing project")
            XCTAssertNotNil(lastEvent["level"], "Missing level")
            XCTAssertNotNil(lastEvent["timestamp"], "Missing timestamp")
            XCTAssertNotNil(lastEvent["platform"], "Missing platform")
            
            if let message = lastEvent["message"] as? String {
                XCTAssertEqual(message, testMessage, "Invalid value for message: \(message)")
            }
            else {
                XCTFail("The message was not a string")
            }
            
            if let project = lastEvent["project"] as? String {
                XCTAssertEqual(project, client.config.projectId!, "Invalid value for project: \(project)")
            }
            else {
                XCTFail("The project was not a string")
            }
            
            if let level = lastEvent["level"] as? String {
                XCTAssertEqual(level, "info", "Invalid value for level: \(level) ")
            }
            else {
                XCTFail("The level was not a string")
            }
            
            if let platform = lastEvent["platform"] as? String {
                XCTAssertEqual(platform, "swift", "Invalid value for platform: \(platform)")
            }
            else {
                XCTFail("Platform was not a string")
            }
        }
        else {
            XCTFail("The client was nil")
        }
    }
    
    func testCaptureMessageWithMessageAndLevel() {
        if let client = client {
            
            let testMessage = "An example message"
            let testLevel = RavenLogLevel.Warning
            client.captureMessage(testMessage, level: testLevel)
            let lastEvent = self.client!.lastEvent
            
            XCTAssertNotNil(lastEvent["event_id"], "Missing event_id")
            XCTAssertNotNil(lastEvent["message"], "Missing message")
            XCTAssertNotNil(lastEvent["project"], "Missing project")
            XCTAssertNotNil(lastEvent["level"], "Missing level")
            XCTAssertNotNil(lastEvent["timestamp"], "Missing timestamp")
            XCTAssertNotNil(lastEvent["platform"], "Missing platform")
            
            
            if let message = lastEvent["message"] as? String {
                XCTAssertEqual(message, testMessage, "Invalid value for message: \(message)")
            }
            else {
                XCTFail("Message was not a string")
            }
            
            if let project = lastEvent["project"] as? String {
                XCTAssertEqual(project, client.config.projectId!, "Invalid value for project: \(project)")
            }
            else {
                XCTFail("Project was not a string")
            }
            
            if let level = lastEvent["level"] as? String {
                XCTAssertEqual(level, testLevel.rawValue, "Invalid value for level: \(level)")
            }
            else {
                XCTFail("Warning was not a string")
            }
            
            if let platform = lastEvent["platform"] as? String {
                XCTAssertEqual(platform, "swift", "Invalid value for platform: \(platform)")
            }
            else {
                XCTFail("Platform was not a string")
            }
        }
        else {
            XCTFail("The client was nil")
        }
    }
    
    
    func testCaptureMessageWithMessageAndLevelAndMethodAndFileAndLine() {
        if let client = client {
            let testMessage = "An example message"
            let testLevel = RavenLogLevel.Warning
            let testMethod = "method name"
            let testFile = "filename"
            let testLine = 34
            
            client.captureMessage(testMessage, level: testLevel, method: testMethod, file: testFile, line: testLine)
            let lastEvent = self.client!.lastEvent
            
            XCTAssertNotNil(lastEvent["event_id"], "Missing event_id")
            XCTAssertNotNil(lastEvent["message"], "Missing message")
            XCTAssertNotNil(lastEvent["project"], "Missing project")
            XCTAssertNotNil(lastEvent["level"], "Missing level")
            XCTAssertNotNil(lastEvent["timestamp"], "Missing timestamp")
            XCTAssertNotNil(lastEvent["platform"], "Missing platform")
            XCTAssertNotNil(lastEvent["stacktrace"], "Missing stacktrace")
            
            if let message = lastEvent["message"] as? String {
                XCTAssertEqual(message, testMessage, "Invalid value for message: \(message)")
            }
            else {
                XCTFail("Message was not a string")
            }
            
            if let project = lastEvent["project"] as? String {
                XCTAssertEqual(project, client.config.projectId!, "Invalid value for project: \(project)")
            }
            else {
                XCTFail("Project was not a string")
            }
            
            if let level = lastEvent["level"] as? String {
                XCTAssertEqual(level, testLevel.rawValue, "Invalid value for level: \(level)")
            }
            else {
                XCTFail("Warning was not a string")
            }
            
            if let platform = lastEvent["platform"] as? String {
                XCTAssertEqual(platform, "swift", "Invalid value for platform: \(platform)")
            }
            else {
                XCTFail("Platform was not a string")
            }
        }
        else {
            XCTFail("The client was nil")
        }
    }
    
    func testCaptureMessageWithMessageAndLevelAndExtraAndTags() {
        if let client = client {
            let testMessage = "An example message"
            let testLevel = RavenLogLevel.Warning
            
            client.captureMessage(testMessage, level: testLevel, additionalExtra:["key" : "extra value"], additionalTags:["key" : "tag value"])
            let lastEvent = self.client!.lastEvent
            
            XCTAssertNotNil(lastEvent["event_id"], "Missing event_id")
            XCTAssertNotNil(lastEvent["message"], "Missing message")
            XCTAssertNotNil(lastEvent["project"], "Missing project")
            XCTAssertNotNil(lastEvent["level"], "Missing level")
            XCTAssertNotNil(lastEvent["timestamp"], "Missing timestamp")
            XCTAssertNotNil(lastEvent["platform"], "Missing platform")
            XCTAssertNotNil(lastEvent["extra"], "Missing extra")
            XCTAssertNotNil(lastEvent["tags"], "Missing tags")
            
            if let message = lastEvent["message"] as? String {
                XCTAssertEqual(message, testMessage, "Invalid value for message: \(message)")
            }
            else {
                XCTFail("Message was not a string")
            }
            
            if let project = lastEvent["project"] as? String {
                XCTAssertEqual(project, client.config.projectId!, "Invalid value for project: \(project)")
            }
            else {
                XCTFail("Project was not a string")
            }
            
            if let level = lastEvent["level"] as? String {
                XCTAssertEqual(level, testLevel.rawValue, "Invalid value for level: \(level)")
            }
            else {
                XCTFail("Warning was not a string")
            }
            
            if let platform = lastEvent["platform"] as? String {
                XCTAssertEqual(platform, "swift", "Invalid value for platform: \(platform)")
            }
            else {
                XCTFail("Platform was not a string")
            }
        }
        else {
            XCTFail("The client was nil")
        }
    }
    
    func testClientWithExtraAndTags() {
        let firstKey = "key"
        let secondKey = "key2"
        let extraValue = "extraValue"
        let tagValue = "tagValue"
        
        let testMessage = "An example message"
        let testLevel = RavenLogLevel.Warning
        
        let clientWithExtraAndTags = MockRavenClient(config: config!, extra: [firstKey: extraValue], tags: [firstKey: tagValue], logger: nil)
        
        clientWithExtraAndTags.captureMessage(testMessage, level: testLevel, additionalExtra: [secondKey: extraValue], additionalTags:[secondKey: tagValue])
        
        let lastEvent = clientWithExtraAndTags.lastEvent
        
        XCTAssertNotNil(lastEvent["extra"], "Missing extra")
        XCTAssertNotNil(lastEvent["tags"], "Missing tags")
        
        if let extra = lastEvent["extra"] as? [String: AnyObject] {
            if let extraValueForKey = extra[firstKey] as? String {
                XCTAssertEqual(extraValueForKey, extraValue, "Missing extra data")
            }
            else {
                XCTFail("First extra data could not be converted to a string")
            }
            
            if let extraValueForKey2 = extra[secondKey] as? String {
                XCTAssertEqual(extraValueForKey2, extraValue, "Missing extra data")
            }
            else {
                XCTFail("Second extra data could not be converted to a string")
            }
        }
        else {
            XCTFail("Could not parse the extra information")
        }
        
        if let tags = lastEvent["tags"] as? [String: AnyObject] {
            if let tagValueForKey = tags[firstKey] as? String {
                XCTAssertEqual(tagValueForKey, tagValue, "Missing tags data")
            }
            else {
                XCTFail("First tag data could not be converted to a string")
            }
            
            if let tagValueForKey2 = tags[secondKey] as? String {
                XCTAssertEqual(tagValueForKey2, tagValue, "Missing tags data")
            }
            else {
                XCTFail("Second tag data could not be converted to a string")
            }
            
            XCTAssertNotNil(tags["OS version"], "Missing tags data (OS Version)")
            XCTAssertNotNil(tags["Device model"], "Missing tags data (Device Model)")
        }
        else {
            XCTFail("Could not parse the tag information")
        }
    }
    
    func testClientWithRewritingExtraAndTags() {
        let key = "key"
        let extraValue = "extraValue"
        let secondExtraValue = "AnotherExtraValue"
        let tagValue = "tagValue"
        let secondTagValue = "AnotherTagValue"
        
        let testMessage = "An example message"
        let testLevel = RavenLogLevel.Warning
        
        let clientWithExtraAndTags = MockRavenClient(config: config!, extra: [key: extraValue], tags: [key: tagValue], logger: nil)
        
        clientWithExtraAndTags.captureMessage(testMessage, level: testLevel, additionalExtra: [key: secondExtraValue], additionalTags:[key: secondTagValue])
        
        let lastEvent = clientWithExtraAndTags.lastEvent
        
        XCTAssertNotNil(lastEvent["extra"], "Missing extra")
        XCTAssertNotNil(lastEvent["tags"], "Missing tags")
        
        if let extra = lastEvent["extra"] as? [String: AnyObject] {
            if let extraValueForKey = extra[key] as? String {
                XCTAssertEqual(extraValueForKey, secondExtraValue, "Incorrect extra data")
                XCTAssertNotEqual(extraValueForKey, extraValue, "Extra data was not rewritten")
            }
            else {
                XCTFail("First extra data could not be converted to a string")
            }
        }
        else {
            XCTFail("Could not parse the extra information")
        }
        
        if let tags = lastEvent["tags"] as? [String: AnyObject] {
            if let tagValueForKey = tags[key] as? String {
                XCTAssertEqual(tagValueForKey, secondTagValue, "Incorrect tags data")
                XCTAssertNotEqual(tagValueForKey, tagValue, "Tag data was not rewritten")
            }
            else {
                XCTFail("First tag data could not be converted to a string")
            }
            
            XCTAssertNotNil(tags["OS version"], "Missing tags data (OS Version)")
            XCTAssertNotNil(tags["Device model"], "Missing tags data (Device Model)")
        }
        else {
            XCTFail("Could not parse the tag information")
        }
    }
    
    func testClientWithLogger() {
        let testMessage = "An example message"
        let loggerValue = "Logger value"
        var clientWithExtraAndTags = MockRavenClient(config: config!, extra: ["key" : "value"], tags: ["key" : "value"], logger: loggerValue)
        
        clientWithExtraAndTags.captureMessage(testMessage)
        
        let lastEvent = clientWithExtraAndTags.lastEvent
        
        if let message = lastEvent["message"] as? String {
            XCTAssertEqual(message, testMessage, "Incorrect value for message \(message)")
        }
        else {
            XCTFail("Message was not a string")
        }
        
        if let logger = lastEvent["logger"] as? String {
            XCTAssertEqual(logger, loggerValue, "Incorrect valid for the logger \(logger)")
        }
        else {
            XCTFail("Logger was not a string")
        }
    }
}
