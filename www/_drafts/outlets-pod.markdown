---
layout: post
title: "Outlets Pod"
tags: swift, cocoapods, carthage, ios
---

Inspired by the great work that came out of writing [Testing IBOutlets][1] (and the wonderful help I got through [sharing][2] the [code][3]), I've created a micro-library which contains these testing functions to make it easy to include them in a project. [Outlets][4] is live now on [CocoaPods][5] and can also be built with Carthage, if that's your poison.

For now, the library only works with iOS apps as these utility functions depend on UIKit. I'll be looking into support for OS X, tvOS and watchOS (if we get [XCTest support for it][6] in June :wink:)

![](/images/outlets-logo.png "Outlets logo showing electrical sockets from various contries")

Why don't you give it a good ol' `pod try Outlets`?

[1]: {% post_url 2016-04-29-testing-iboutlets-and-ibactions-with-curried-functions-in-swift %}
[2]: https://gist.github.com/phatblat/ee2c470970b906238e395c4fd48f4ad3
[3]: https://github.com/phatblat/OutletActionAssertion
[4]: https://github.com/phatblat/Outlets
[5]: https://cocoapods.org/pods/Outlets
[6]: https://openradar.appspot.com/21760513
