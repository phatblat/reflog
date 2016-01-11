---
layout: post
title: "Mac Server Setup: Step 1"
tags: server, energy-saver, defaults, pmset
---

By default, Macs are designed to be user machines. While they are very easy to set up as servers, a few of the standard settings are not ideal for hosting services.

If you are planning on using a Mac as a server - that is, you expect it to be running services indefinitely - there are some settings you should check on _first_, before you are remote and having issues.

## Energy Saver

Launch System Preferences and navigate to the Energy Saver pane. Change these settings:

- Computer Sleep: Never
- Display Sleep: Never
- disable "Put hard disks to sleep when possible"
- enable **"Start up automatically after a power failure"**

![](/images/mac-server-setup-energysaver.jpg "Energy Saver system preferences pane")

This is a screenshot from my Mac mini which @macminicolo was kind enough to set up like this for me.

## Reading Values from the Command Line

The values behind the Energy Saver preferences pane appear to be stored in User Defaults and can be read with the following command:

```
defaults read /Library/Preferences/SystemConfiguration/com.apple.PowerManagement
```

The "Automatic Restart On Power Loss" key is the most important.

```
{
    ActivePowerProfiles =      {
        "AC Power" = "-1";
    };
    "Custom Profile" =     {
        "AC Power" =         {
            "AutoPowerOff Delay" = 14400;
            "AutoPowerOff Enabled" = 1;
            "Automatic Restart On Power Loss" = 1;
            DarkWakeBackgroundTasks = 0;
            "Disk Sleep Timer" = 0;
            "Display Sleep Timer" = 0;
            "Hibernate File" = "/var/vm/sleepimage";
            "Hibernate Mode" = 0;
            PrioritizeNetworkReachabilityOverSleep = 0;
            "Sleep On Power Button" = 1;
            "Standby Delay" = 4200;
            "Standby Enabled" = 1;
            "System Sleep Timer" = 0;
            TTYSPreventSleep = 1;
            "Wake On LAN" = 1;
        };
        Defaults = 1;
    };
}
```

Because of the way these settings are stored, they are difficult to set using the `defaults` command, which requires passing a plist file in order to set a tree of key-value pairs such as the above "Custom Profile" entry. The danger with doing this is that many values are set or unset in one step and these values will likely change through the years as OS X evolves.

## Reading Values from the Command Line

A better approach for manipulating these values from the command line is to use the `pmset` command. This utility can be used to read the current Energy Saver values (read them all with `pmset -g`, but uses shorter key aliases than defaults. The pmset keys are mostly space-free for easier typing on the command line.

```
pmset -g
Active Profiles:
AC Power                -1* Currently in use:
 standby              1
 Sleep On Power Button 1
 womp                 1
 autorestart          1
 hibernatefile        /var/vm/sleepimage
 powernap             0
 networkoversleep     0
 disksleep            0
 sleep                0
 autopoweroffdelay    14400
 hibernatemode        0
 autopoweroff         1
 ttyskeepawake        1
 displaysleep         0
 standbydelay         4200
```

### TL;DR

These are the values you will always want to change when setting up a Mac server:

```
sudo pmset -c sleep 0
sudo pmset -c displaysleep 0
sudo pmset -c disksleep 0
sudo pmset -c autorestart 1
```

# References

- [Mac mini Servers: A Cautionary Tale](http://www.neglectedpotential.com/2012/12/mac-mini-servers-a-cautionary-tale/)
- [How and Why to Tell Your Mac to Start Up Automatically After a Power Failure](http://www.tekrevue.com/tip/mac-start-up-automatically-after-a-power-failure)
- [Energy Saver preferences](https://support.apple.com/kb/PH21704?viewlocale=en_US&locale=en_US)
- [pmset(1) Mac OS X Manual Page](https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man1/pmset.1.html)

