---
layout: post
title: Intercepting stdout in Swift
---

In the process of creating tests for [mas](https://github.com/mas-cli/mas),
I needed to validate the text that was being output to stdout for the user.
One way to do this would be to introduce a façade for output.
This output controller would have a production version that uses the typical `print`
function and the test version stores the strings sent to it so that the values
can be compared to the expected values. However, I figured I would try to
intercept character data sent to stdout instead. While this isn't too difficult,
restoring the original stdout ended up being rather tricky as there wasn't a good
example to copy.

## Objectives

1. Store characters written to stdout in a `String`
1. Pass the unmodified data through so it can be viewed in the Xcode console
1. Only used for unit tests
1. Don't break anything

## Research

As the first step in [SODD](https://dzone.com/articles/stack-overflow-driven-development-sodd-its-really),
I made sure to Google whether anyone had figured this out before.
@ericasadun has a great post on
[Swift Logging](https://ericasadun.com/2015/05/22/swift-logging/),
but it's from the Swift 1-2 days and a bit dated now. Plus, I dislike calling C
functions from Swift and want to minimize the use of C APIs.

I found a newer post by @thesaadismail on
[Eavesdropping on Swift’s Print Statements](https://medium.com/@thesaadismail/eavesdropping-on-swifts-print-statements-57f0215efb42)
which served as my starting point. There are a few key points in his post:

- `dup2` can be used to connect a `Pipe` to an existing file handle like stdout
- use both an input `Pipe` and an output `Pipe` if you want to have output continue to appear in the Xcode console
- don't read from `Pipe`s directly as they will block the current thread
   - instead use `readInBackgroundAndNotify()`

## Implementation

I created a class to hold this funcationality so that it could be reused by different tests.

### OutputListener

```swift
class OutputListener {
    /// consumes the messages on STDOUT
    let inputPipe = Pipe()

    /// outputs messages back to STDOUT
    let outputPipe = Pipe()

    /// Buffers strings written to stdout
    var contents = ""
}
```

Here we have the minimal storage for my implementation. `inputPipe` will bring input to
my test listener, `outputPipe` will handle sending text back to stdout and `contents`
will build up a string of all the data that passes through.

### init

One-time setup code to wire up the two `Pipe`s and capture `contents`.

```swift
init() {
    // Set up a read handler which fires when data is written to our inputPipe
    inputPipe.fileHandleForReading.readabilityHandler = { [weak self] fileHandle in
        guard let strongSelf = self else { return }

        let data = fileHandle.availableData
        if let string = String(data: data, encoding: String.Encoding.utf8) {
            strongSelf.contents += string
        }

        // Write input back to stdout
        strongSelf.outputPipe.fileHandleForWriting.write(data)
    }
}
```

This uses `readabilityHandler` instead of notifications for less code and no need to
repeatedly call `readInBackgroundAndNotify()`.

While trying to get this to actually work, I found that calling either `readDataToEndOfFile()`
or `readData(ofLength:)` immediately blocks the current thread seemingly forever. This may be
because my `inputPipe` is still open so the file has no "end".

`availableData` is the property to use as it will have a `Data` object of the character data
written to the pipe's file handle so far.

### openConsolePipe

This is the code that actually wires up the pipes to intercept stdout. It uses the esoteric
`dup2` C function.

```swift
/// Sets up the "tee" of piped output, intercepting stdout then passing it through.
func openConsolePipe() {
    // Copy STDOUT file descriptor to outputPipe for writing strings back to STDOUT
    dup2(stdoutFileDescriptor, outputPipe.fileHandleForWriting.fileDescriptor)

    // Intercept STDOUT with inputPipe
    dup2(inputPipe.fileHandleForWriting.fileDescriptor, stdoutFileDescriptor)
}
```

> `stdoutFileDescriptor` is my computed property for `FileHandle.standardOutput.fileDescriptor`,
which is the same value as `STDOUT_FILENO`, or simply `1`.

This works, but it's the one piece of magic from @thesaadismail's post that I don't
fully understand. The calls to `dup2` return the 2nd argument's value indicating success,
however there was no change to any `fileDescriptor` property values as I was expecting.
`FileHandle.fileDescriptor` is read-only so perhaps the Swift Foundation functionality
doesn't refresh this value.

Things went swimmingly at this point when running a single test. However, when I ran the entire
`mas` test suite some calls to `print()` would blow up with `SIGPIPE` 💥.

### 😕

It was clear to me that monkeying with stdout was causing these issues. I attempted to use `dup2`
to restore stdout to no avail.

### 💡

Then I recalled an experiment I did a few years ago to suppress all output to stdout in a little
project called [nolog](https://github.com/phatblat/nolog/blob/master/NoLog/NoLog/ThisClassLoadsFirst.m#L17).
it uses `freopen()` to reopen stdout, pointing it to a new file path. nolog redirects stdout to
`/dev/null`, a well-known way to ignore output from a terminal command.

> `echo "can anyone hear me?" > /dev/null`

Digging around in the `/dev` directory revealed that macOS has a `/dev/stdout` file, so I gave that a whirl.

### closeConsolePipe

```swift
/// Tears down the "tee" of piped output.
func closeConsolePipe() {
    // Restore stdout
    freopen("/dev/stdout", "a", stdout)

    [inputPipe.fileHandleForReading, outputPipe.fileHandleForWriting].forEach { file in
        file.closeFile()
    }
}
```

🎉 This was the missing piece I needed to restore stdout. I don't know if the `closeFile()`
calls are necessary, especially in a test suite, but I like to clean up after myself 🧹.

## Usage

Here's how it works inside a test.

```swift
let output = OutputListener()
output.openConsolePipe()
let expectedOutput = "hi there"

// run code under test that output some text
print(expectedOutput, terminator: "")

// output is async so need to wait for contents to be updated
expect(output.contents).toEventuallyNot(beEmpty())
expect(output.contents) == expectedOutput

output.closeConsolePipe()
```

Here I'm using the Nimble [`toEventuallyNot`](https://github.com/Quick/Nimble/blob/master/Sources/Nimble/Matchers/Async.swift#L142-L148)
function to take care of the asynchroncity of these file handles as they are
essentially text streams. If you are using XCTest, take a look at
[Testing Asynchronous Operations with Expectations](https://developer.apple.com/documentation/xctest/asynchronous_tests_and_expectations/testing_asynchronous_operations_with_expectations).

## References

- [`OutputListener.swift`](https://github.com/mas-cli/mas/blob/master/MasKitTests/OutputListener.swift)
  - used in [`info` command tests](https://github.com/mas-cli/mas/blob/master/MasKitTests/Commands/InfoCommandSpec.swift#L55-L68)
- [nolog](https://github.com/phatblat/nolog/blob/master/NoLog/NoLog/ThisClassLoadsFirst.m#L17)
- [Eavesdropping on Swift’s Print Statements](https://medium.com/@thesaadismail/eavesdropping-on-swifts-print-statements-57f0215efb42)
- [Swift Logging](https://ericasadun.com/2015/05/22/swift-logging/)
- [Testing Asynchronous Operations with Expectations](https://developer.apple.com/documentation/xctest/asynchronous_tests_and_expectations/testing_asynchronous_operations_with_expectations)
- [The Weak/Strong Dance in Swift](http://kelan.io/2015/the-weak-strong-dance-in-swift/)
- [stdout](https://www.computerhope.com/jargon/s/stdout.htm)
- [tee command](http://man7.org/linux/man-pages/man1/tee.1.html)
- [`SIGPIPE`](https://stackoverflow.com/a/18963142/39207)

### API Docs

- [`Pipe`](https://developer.apple.com/documentation/foundation/pipe)
- [`FileHandle`](https://developer.apple.com/documentation/foundation/filehandle)
  - [`readabilityHandler`](https://developer.apple.com/documentation/foundation/filehandle/1412413-readabilityhandler)
  - [`availableData`](https://developer.apple.com/documentation/foundation/filehandle/1411463-availabledata)
  - [`readDataToEndOfFile()`](https://developer.apple.com/documentation/foundation/filehandle/1411490-readdatatoendoffile)
  - [`readData(ofLength:)`](https://developer.apple.com/documentation/foundation/filehandle/1413916-readdata)
- [`dup2()`](https://linux.die.net/man/2/dup2)
- [`freopen()`](https://linux.die.net/man/3/freopen)
- [`print(_:separator:terminator:)`](https://developer.apple.com/documentation/swift/1541053-print)
- [`XCTestExpectation`](https://developer.apple.com/documentation/xctest/xctestexpectation)
