# ThereAndBack-iOS

Demonstrates communication between two apps in iOS.

## Rationale

If you have a scenario where two apps rely on each other, or one app delegates to 
a helper app, you need to establish a way of communicating with them. As there is
no inter-process mechanism in iOS (at least anything that is fully sanctioned by Apple
and doesn't require UNIX wizardry), app-to-app or "inter-app" communication is established 
by using a URL to launch a second app from a running app.

For an app to be launched with a URL you need to register a URL scheme for the app
for iOS to know about it.
Making up new URL schemes is not necessarily a good idea in an Internet context,
although allowed by the Internet standard RFC 3986,
but for an OS-level inter-app communication channel it is acceptable.

When you have registered a URL scheme, it is completely up to the two apps how
to structure the actual URL. It can include information about how to drive the 
helper app when it is launched from another app, or anything else, as long as
it is agreed between the two apps.

In many cases you will also want to come back from the helper app to the originating
app. For that you will need to register a URL scheme for the originating app as well.
The actual URL body is up to the apps themselves, but it needs to be carefully
coordinated.

Some URL schemes are reserved by Apple in iOS, and you cannot register a handler
for them. Sensibly, these include at least `http` and `https`, `mailto`, `tel` and `sms`,
and any attempt to use them will result in the Apple-defined handler for them to
be started (Safari, Mail, Phone, and Messages for those schemes mentioned above).

Note that there is no way to prevent two or more apps registering the same URL
scheme, but the documentation says there is no process to determine which app,
if any, gets to handle the scheme. This is something that should be investigated,
because it could be a way to prevent an app from working as intended.

## How to register a URL scheme in iOS

To register one or more URL schemes, you need to add the `CFBundleURLTypes key to your
app's `Info.plist` file. The value of the key must be an array of dictionaries.
Each element in the array defines a name for the URL scheme (a reverse domain name
is a good idea) and the actual scheme names.

Here is an example in property list format:

```
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLName</key>
    <string>com.mycompany.App2</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>app2</string>
    </array>
  </dict>
</array>
```

("CF" stands for "Core Foundation".)

If you could express this in Swift instead of the XML-based property list format,
it would be something like this:

```swift
let bundleURLTypes: [String: Any] = [
    "bundleURLName": "com.mycompany.App2",
    "bundleURLSchemes": ["app2"]
]
```

## How to check if there is a handler for a given URL scheme

You can call the `canOpenURL` of the shared `UIApplication` object in iOS to determine if there 
is a handler for a specific URL. 

If the URL scheme hasn't been registered, and try to open a URL that has the schema, the call will fail
and return false, with a message on the console:

```
canOpenURL: failed for URL: "app2:///" - error: "The operation couldn’t be completed. (OSStatus error -10814.)"
```

Here is a helper function in Swift to determine
if URLs with a given scheme can be opened. You can specify a minimal but still 
complete URL with the scheme in place.

```swift
func isSchemeAvailable(_ scheme: String) -> Bool {
    var result = false
    if let url = URL(string: "\(scheme):///") {
        result = UIApplication.shared.canOpenURL(url)
        print("isSchemeAvailable? \(scheme) = \(result)")
    }
    return result
}
```

Since iOS 9, the call to `canOpenURL` will fail unless you have specified 
the URL schemes you are allowed to query:

```
canOpenURL: failed for URL: "app2:///" - error: "This app is not allowed to query for scheme app2"
```

You ask for permission to query by adding the
`LSApplicationQueriesSchemes` key in the app's `Info.plist` file:

```
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>app2</string>
</array>
```

## Starting the helper app from the main app

Once you know there is a handler for the URL scheme, you can try to launch
the handler app:

`openURL:options:completionHandler:`

Note that the old `openURL` method is deprecated since iOS 10, so if you're 
targeting iOS 10 or later, you should use the method with the completion
handler. If you're targeting an earlier version of iOS, use an availability
macro.

Use the helper function before you call `canOpenURL`:

```swift
let app2Scheme = "app2"
let app2URL = "\(app2Scheme):///foobar"
if isSchemeAvailable(app2Scheme) {
    if let url = URL(string: app2URL) {
        UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
            print("Opening URL '\(app2URL)': \(success)")
        })        
    }
}
```

## Handling the URL request in the helper app

In most cases you will want to pass some information from the main app to the
helper app using the launch URL. You'll need to parse the URL when the helper
app is launched.

Let's say you launch the helper app and need to include a UUID and a parameter. 
The launch URL could look something like this:

`app2:///6e68faa8-7b82-461b-8a8b-b2a0c0bed0cb?verified=true

Note that the host part of the URL is empty.

If you need to generate UUIDs on the command line for testing on macOS,
use the `uuidgen` command. If you want to fold the result to lower case,
combine it with the `tr` command:

`uuidgen | tr '[:upper:]' '[:lower:]'`

The launch URL will end up in the launch options of the helper app, and you
can process it in the `application:didFinishLaunchingWithOptions:` method
of your application delegate. The launch option key is `UIApplicationLaunchOptionsKey.url`.

```
func application(_ application: UIApplication, 
                 didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    if let options = launchOptions {
        if let url = options[UIApplicationLaunchOptionsKey.url] {
            debugPrint("Launched with URL: \(url)")
        }
    }
    
    return true
}
```

## Testing the launch

When you have run your helper app at least once to get its URL scheme registered,
you will want to test launching it from the URL. The easiest way to do this is
to load a URL in Safari, either in the simulator or in an actual device.

Just type `app2:///something` in the location field of Safari. You will be asked
to verify if you want the helper app to open.

If you want to log something or stop at a breakpoint, you will need to start
the helper app from Xcode and have it wait for the app to be launched manually.
Go to the Run scheme of your app, then in the Info section select Launch > Wait
for executable to be launched.

When you run the helper app in Xcode, you will see "Waiting to attach to XXX
on YYY" in the Xcode display, where XXX is your app and YYY is your device.
Now if you enter your app's URL in Safari, the Xcode debugger will attach to
your app and you will see what you have logged in the Xcode log area.


## Returning from the helper app to the main app

When the user has performed a task in the helper app, and wants to return
to the main app, you will need to open the appropriate URL with the
right scheme. For this you will obviously need to perform the same steps
with the helper as you did with the main app:

* Declare in the helper app that you will want to query the main app's scheme, `app1`
* Register the `app1` scheme in the main app
* Start the main app (most likely it is backgrounded at this point) using `openURL:options:completionHandler:`
* Handle the URL request in the helper app, in `application:didFinishLaunchingWithOptions:`

# Adding a verification mechanism

Some inter-app communication scenarios need a third component for verifying the 
interaction. For example, if you start a banking transaction from the main app, 
you would first retrieve a transaction identifier from a verification server, then
include the identifier in the URL used to start the helper app.

The helper app should verify the transaction identifier with the server before
starting the main app.

# References

* https://useyourloaf.com/blog/querying-url-schemes-with-canopenurl/
* https://developer.apple.com/library/content/documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/Inter-AppCommunication/Inter-AppCommunication.html
* https://tools.ietf.org/html/rfc3986
