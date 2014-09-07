# raven-swift

Swift client for [Sentry](https://www.getsentry.com/welcome/).


//TODO: ## Installation

The easiest way is to use [CocoaPods](http://cocoapods.org). It takes care of all required frameworks and third party dependencies:

```ruby
pod 'Raven-swift'
```

**Alternatively**, you can install manually.

1. Get the code: `git clone git://github.com/getsentry/raven-swift`
2. Drag the `Raven` subfolder to your project. Check both "copy items into destination group's folder" and your target.

Alternatively you can add this code as a Git submodule:

1. `cd [your project root]`
2. `git submodule add git://github.com/getsentry/raven-swift`
3. Drag the `Raven` subfolder to your project. Uncheck the "copy items into destination group's folder" box, do check your target.


## How to get started

While you are free to initialize as many instances of `RavenClient` as is appropriate for your application, there is a shared singleton instance that is globally available. This singleton instance is often configured in your app delegate's `application:didFinishLaunchingWithOptions:` method:

```swift
 func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        RavenClient.clientWithDSN("https://30d629f2df9c4fdf8507e1704c09a526:f766cf8e0fff446986ac6daf1902e832@app.getsentry.com/888")

        // [...]
        return true
}
```
The first `RavenClient` that is initialized is automatically configured as the singleton instance and becomes available via the `sharedClient` singleton method:

```swift
println("I am your RavenClient singleton : \(RavenClient.sharedClient())")
```

//TODO: ### Sending messages

```swift
// Sending a basic message (note, does not include a stacktrace):
[[RavenClient sharedClient] captureMessage:@"TEST 1 2 3"];

// Sending a message with another level and a stacktrace:
[[RavenClient sharedClient] captureMessage:@"TEST 1 2 3" level:kRavenLogLevelDebugInfo method:__FUNCTION__ file:__FILE__ line:__LINE__];

// Recommended macro to send a message with automatic stacktrace:
RavenCaptureMessage(@"TEST %i %@ %f", 1, @"2", 3.0);
```

### Handling exceptions

Setup a global exception handler:

```swift
func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    // Override point for customization after application launch.
    
    RavenClient.clientWithDSN("https://[public]:[secret]@[server]/[project id])
    
    RavenClient.sharedClient()?.setupExceptionHandler()

    return true
}
```

//TODO: You can also capture errors:

```swift
NSError *error;
[[NSFileManager defaultManager] removeItemAtPath:@"some/path" error:&error];
RavenCaptureError(error);
```

*Note: when using the global exception handler, exceptions will be sent the __next__ time the app is started.*


## Issues and questions

Have a bug? Please create an issue on GitHub!

https://github.com/getsentry/raven-swift/issues


## Contributing

raven-swift is an open source project and your contribution is very much appreciated.

1. Check for [open issues](https://github.com/getsentry/raven-swift/issues) or [open a fresh issue](https://github.com/getsentry/raven-swift/issues/new) to start a discussion around a feature idea or a bug.
2. Fork the [repository on Github](https://github.com/getsentry/raven-swift) and make your changes.
3. Make sure to add yourself to AUTHORS and send a pull request.


## License

raven-swift is available under the MIT license. See the LICENSE file for more info.
