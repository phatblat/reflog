---
layout: post
title: "Mac mini Server"
date: 2015-12-31T15:08:32-07:00
---

## Traveling without a Mac

My family and I traveled for Christmas this year I managed to leave the MacBook behind, bringing only iPads and iPhones on the trip.

![](/images/ipad-sizes.jpg "iPhone 5s (left), iPad mini 2 (center), iPad Pro with Smart Keyboard (right)")

Wile on the road, there are two things that I wanted to do which I wasn't able to on my iPad Pro:

1. Run octopress and jekyll to update this blog
2. Run Xcode to play with some code

I don't foresee either of these being possible on iOS in the near future. #1 requires an app to be able to spawn processes, which isn't currently possible. Apple's answer to some of the multi-process use cases is [App Extensions](https://developer.apple.com/library/ios/documentation/General/Conceptual/ExtensibilityPG/), introduced in iOS 8, but that doesn't allow for arbitrary terminal commands. While I'm certain we'll see Xcode on iOS some day, #2 has similar limitations as Xcode on OS X spawns lots of processes when running builds.

I attempted to do #1 on a Linux server at my web hosting provider, but was quickly reminded why I normally use Macs.

It would be nice to access a Mac remotely for these purposes. For security reasons, I do not want to expose my home iMac to the Internet, so a dedicated box is preferred.

These issues are not critical, but they got me thinking that this "leave the Mac at home" approach isn't going to work if I'm going to do any development. With [Git2Go](http://git2go.com) and [Working Copy](http://workingcopyapp.com), I can commit changes directly to git, but I can't compile or test them without a Mac. Taking an iPad Pro everywhere is mostly extra weight if I _also_ have to bring a MacBook; it defeats the purpose of bringing the iPro.

##  Macminicolo

I've been aware of [Macminicolo](https://macminicolo.net) for years mostly due to [iStat](https://bjango.com/ios/istat) for iOS, which appears to no longer be available in the App Store. They specialize in, well, colocation of Mac minis.

![](/images/mac-mini.png "Mac mini")

I finally settled on getting a mini and hosting it there, but was thinking I'd wait until the new mini models come out later in 2016. In typical Apple fashion, there is no announced release date, but looking at their [release history](http://buyersguide.macrumors.com/#Mac_Mini) for the mini, they are due for a new model now. Intel's [Skylake processors](http://www.macrumors.com/2015/09/02/intel-skylake-notebooks-desktops) are out and most of the Mac lineup should receive updates in 2016 (perhaps not the Mac Pro).

However, Macminicolo just launched a [2016 Promo](https://macminicolo.net/2016) for a year of 2x Pro service and an upgraded Mac mini for a heavily discounted rate. That was enough to convince me and I went for it.

## Purpose

What the heck am I going to do with this? I have a few things in mind:

- Website hosting, relocating several sites from [DreamHost](http://www.dreamhost.com/r.cgi?41837)
- Relocate this reflog for server-side access log-based analytics instead of Google Analytics
- Minecraft servers (PC & PE)
- CI server
- Fastlane and xcodebuild access over SSH using [Prompt](https://panic.com/prompt) on iOS
- Xcode GUI over VNC using [Screens](http://edovia.com/screens) on iOS

## Upcoming

In the upcoming months I'll be posting on topics related to setting up a Mac server, since I'll be going through it anyway.

A few years ago, I built the CI stack for iOS and Android apps at Kaiser Permanente. Once that became a full-time job, [CGRekt](https://twitter.com/CGRekt) took that over so I could focus on building iOS apps. Now, I'm mainly a user of CI, so I like to play around with it at home where I can break things without affecting others.

I've wanted to write about CI for iOS for years but it's such a huge subject it's hard to know where to start. If I post as I go through setting it up, I think it'll be easier to write and consume.

