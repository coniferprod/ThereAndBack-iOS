# ThereAndBack-iOS

Demonstrates communication between two apps in iOS.

## Rationale

If you have a scenario where two apps rely on each other, or one app delegates to 
a helper app, you need to establish a way of communicating with them. As there is
no inter-process mechanism in iOS, app-to-app or "inter-app" communication is established 
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
for them. Sensibly, these include at least http and https, mailto, tel and sms,
and any attempt to use them will result in the Apple-defined handler for them to
be started (Safari, Mail, Phone, and Messages for those schemes mentioned above).

Note that there is no way to prevent two or more apps registering the same URL
scheme, but the documentation says there is no process to determine which app,
if any, gets to handle the scheme. This is something that should be investigated,
because it could be a way to prevent an app from working as intended.

## How to register a URL scheme in iOS

To register one or more URL schemes, you need to add the CFBundleURLTypes key to your
app's Info.plist file. The value of the key must be an array of dictionaries.
Each element in the array defines a name for the URL scheme (a reverse domain name
is a good idea) and the actual scheme names.

Here is an example in property list format:

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

("CF" stands for "Core Foundation".)

If you could express this in Swift instead of the XML-based property list format,
it would be like this:

let bundleURLTypes: [[String: [String]]] = [
    "bundleURLName": "com.mycompany.App2",
    "bundleURLSchemes": ["app2"]
]

## How to check for the existence of a URL scheme

You can call the canOpenURL of the shared UIApplication object to determine if there 
is a handler for a specific URL. Here is a helper function in Swift to determine
if URLs with a given scheme can be opened. You don't have to specify a full URL,
just the scheme.

func isSchemeAvailable(scheme: String) -> Bool {
    if let url = "\(scheme)://" {
        return UIApplication.shared.canOpenURL(scheme)
    }
    return false
}

Since iOS 9, the call to canOpenURL will fail unless you have specified 
the URL schemes you are allowed to query. This is done by adding the
LSApplicationQueriesSchemes key in the app's Info.plist file.

<key>LSApplicationQueriesSchemes</key>
<array>
    <string>app2</string>
</array>


## Starting the helper app from the main app

Once you know there is a handler for the URL scheme, you can try to launch
the handler app:

openURL:options:completionHandler:

Note that the old openURL method is deprecated since iOS 10, so if you're 
targeting iOS 10 or later, you should use the method with the completion
handler. If you're targeting an earlier version of iOS, use an availability
macro.

Use the helper function before you call canOpenURL:

let app2Scheme = "app2"
let app2URL = "\(app2Scheme)"
if isSchemeAvailable(app2Scheme) {
    if let url = URL(string: app2URL) {
        UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
            print("Opening URL '\(app2URL)': \(success)")
        })        
    }
}

## Handling the URL request in the helper app



## Returning from the helper app to the main app

When the user has performed a task in the helper app, and wants to return
to the main app, you will need to open the appropriate URL with the
right scheme. For this you will obviously need to perform the same steps
with the helper as you did with the main app:

* Declare in the helper app that you will want to query the main app's scheme, app1
* Register the app1 scheme in the main app
* Start the main app (most likely it is backgrounded at this point) using openURL:options:completionHandler:
* Handle the URL request in the helper app, in application:didFinishLaunchingWithOptions:

# Adding a verification mechanism

Some inter-app communication scenarios need a third component for verifying the 
interaction. For example, if you start a banking transaction from the main app, 
you would first retrieve a transaction identifier from a verification server, then
include the identifier in the URL used to start the helper app.

The helper app should verify the transaction identifier with the server before
starting the main app.

# References

https://useyourloaf.com/blog/querying-url-schemes-with-canopenurl/
https://developer.apple.com/library/content/documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/Inter-AppCommunication/Inter-AppCommunication.html
https://tools.ietf.org/html/rfc3986

