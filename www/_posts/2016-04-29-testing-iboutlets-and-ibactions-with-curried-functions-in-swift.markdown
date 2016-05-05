---
layout: post
title: "Testing IBOutlets and IBActions With Curried Functions in Swift"
date: 2016-04-29T13:39:19-06:00
tags: swift, interface-builder, testing, function-currying, quick, nimble
---

**Update:** These nifty utility functions are now available as the [Outlets Pod]({% post_url 2016-05-03-outlets-pod %}).

> This post is a eulogy to the syntactic-sugar :lollipop: syntax for curried functions in Swift 1-2.

## IBOutlet Testing

A couple years ago I built a universal iPhone / iPad app with three storyboards.

- iPhone
- iPad
- shared scenes

![](/images/firefly-storyboards.png "iPad, iPhone and shared storyboards")

Many of the view controllers between the device-specific storyboards were shared and thus the outlets and actions all had to be the same. Each outlet property was bound to two different storyboards and required launching the app in different simulators to manually validate they were hooked up correctly. It was a constant challenge to keep them in sync whenever renaming a property or method. Most of the time I would forget to update at least one outlet and I’d have another lovely crasher from the device I forgot to test on.

I came up with a scheme to use unit tests to assert that these outlets and actions were bound correctly so that I could validate them almost instantly. I ended up with a handful of ugly C functions that I never shared.

It's much easier nowadays to build a universal iPhone/iPad app with shared storyboards due to [Size Classes](https://developer.apple.com/library/ios/recipes/xcode_help-IB_adaptive_sizes/chapters/AboutAdaptiveSizeDesign.html). The new [UI Testing](https://developer.apple.com/videos/play/wwdc2015/406/) in Xcode 7 makes it much easier to automate testing, which can catch any missed outlet/action bindings (as long as your test touches every UI element). However, I still find this sort of low-level assertion helpful, especially since it's so easy to do.

## Swift Curried Functions

When I learned that Swift had super-clean function currying syntax I refactored these ugly helper functions into something much more beautiful, learning about a new language feature in the process.

Swift 2 has syntactic sugar for defining curried functions.

```
func sum(A: Int)(_ B: Int)(_ C: Int) -> Int {
  return A + B + C
}
```

This `sum` function can be called in a number of ways:

```
let sumA = sum(1)     // Int -> Int -> Int
let sumAB = sumA(2)   // Int -> Int

sum(1)(2)(3)          // 6
sumA(2)(3)            // 6
sumAB(3)              // 6
```

In this example, the `sumA` function has captured the value of the `A` parameter (1), whereas `sumAB` has captured the values of both the `A` and `B` parameters (1 and 2). When the final `C` parameter is passed to any of these functions the resulting `Int` value (6) is returned.

An equivalent `sum` function using the more verbose curried function syntax shows that it is really a set of nested functions.

```
func sum(A: Int) -> (Int -> (Int -> Int)) {
  return { B in
    return { C in
      return A + B + C
    }
  }
}
```

This more verbose syntax can get noisy very quickly with many arguments. It's a common practice to define a `curry` function which transforms a multi-parameter function into its curried version. [^curry-func]

[^curry-func]: As I've learned from @aligatr :crocodile:

```
func curry(f: (A,B)->C) -> A->B->C
```

The thoughtbot [Curry library](https://github.com/thoughtbot/Curry/blob/master/Source/Curry.swift) has all the variations of the `curry` function up to 19 parameters.

## Why Currying?

Currying helps to simplify these outlet and action test functions so that the view controller doesn't have to be passed in every function call. Just like the `sumA` function holds onto the value of the first parameter, these test functions hold onto a reference to the view controller being tested. There's also the benefit of being able to give the returned function a very readable name.

## Outlet Assertion

Just look at how beautiful this is!

```swift
it("has a leftButton outlet") {
  hasButtonOutlet("leftButton")
}
```

> This is a BDD-style test using the [Quick](https://github.com/Quick/Quick) framework.

So, what is that `hasButtonOutlet` magic? It’s a [partially-applied](https://en.m.wikipedia.org/wiki/Partial_application) function saved in a local variable. This is how it is created:

```swift
class ViewControllerSpec: QuickSpec {
  override func spec() {
    var viewController: UIViewController!
    var hasButtonOutlet: (String -> UIButton?)!
    describe("view controller") {
      beforeEach {
        viewController = ...
        hasButtonOutlet = outlet(viewController)
      }
      ...
```

The return type in the `hasButtonOutlet` declaration (`UIButton` in the above example) is the type used for validation inside the generic `outlet` function below.

Calling the `outlet` full function would look like this:

```swift
outlet(viewController)("leftDoneButton")
```

But, you might as well just have a plain, old multi-parameter function if you want all that. Currying reduces noise and makes these tests more readable - Handy when you have dozens of outlets and are chasing down which one you mistyped.

Here is a condensed definition of the `outlet` curried function:

```swift
func outlet<T>(viewController: UIViewController) -> (String) -> T? {
  return { (expectedOutlet: String) -> T? in
    guard let object = viewController.valueForKey(expectedOutlet)
      else { fail("\(expectedOutlet) outlet was nil"); return nil }

    guard let objectOfType = object as? T
      else { fail("\(object) outlet was not a \(T.self)"); return nil }

    return objectOfType
  }
}
```

> The `fail` function is part of the [Nimble](https://github.com/Quick/Nimble) matcher framework

## Action Assertion

The action assertion functions are similarly simple.

```swift
it("receives a didTapLeftButton: action from leftButton") {
  receivesAction("didTapLeftButton:", from: "leftButton")
}
```

One caveat is that they require an outlet on the thing sending the action. A lot of the time an outlet isn’t necessary for an action-sending UI element, but I haven’t found a way to get the actions from the view controller (yet).

Here is the setup for the partially-applied `receivesAction`:

```swift
class ViewControllerSpec: QuickSpec {
    override func spec() {
    var receivesAction: ((String, from: String) -> Void)!
    describe("view controller") {
      beforeEach {
        viewController = ...
        receivesAction = action(viewController)
      }
      ...
```

Implementation of the `action` function is more complex as getting to the IBAction differs depending on whether the UI element is a `UIBarButtonItem` or a type of `UIControl`. [^action-test]

[^action-test]: This bit of UIKit magic :sparkles: is from @qcoding's [post on Stack Overflow](http://stackoverflow.com/questions/18699524/is-it-possible-to-test-ibaction) for how to test IBActions.

```swift
func action(viewController: UIViewController) -> (String, from: String) -> Void {
  return { (expectedAction: String, expectedOutlet: String) in
    let optionalControl = outlet(viewController)(expectedOutlet)

    var target: AnyObject?
    var action: String?

    if let control = optionalControl {
      switch control {
      case let button as UIBarButtonItem:
        target = button.target
        action = button.action.description
      case let control as UIControl:
        target = control.allTargets().first!
        var allActions: [String] = []
        for event: UIControlEvents in [.TouchUpInside, .ValueChanged] {
          allActions += control.actionsForTarget(target!, forControlEvent: event) ?? []
        }

        // Filter down to the expected action
        action = allActions.filter({$0 == expectedAction}).first
      default:
        fail("Unhandled control type: \(control.dynamicType)")
      }
    }

    expect(target) === viewController
    expect(action).toNot(beNil())
    if let action = action {
      expect(action) == expectedAction
    }
  }
}
```

> The `expect` function is part of the [Nimble](https://github.com/Quick/Nimble) matcher framework

## Code

A full project demonstrating these helper functions is available at:
[https://github.com/phatblat/OutletActionAssertion](https://github.com/phatblat/OutletActionAssertion)

The functions in the sample code are much more beautiful due to @esttorhe's help in simplifying the API.

Running the tests in the example project gives quick[^quick] feedback that all the outlets and actions are properly connected without even launching the app.

[^quick]: These tests are run using the [Quick :stuck_out_tongue_winking_eye: testing framework](https://github.com/Quick/Quick).

![](/images/outlet-action-tests-pass.png "ViewControllerSpec test status with all green checkmarks")

## Deprecated :sob:

Shortly after @allonsykraken posted [Hipster Swift](http://krakendev.io/blog/hipster-swift), I learned that the super-clean syntactic sugar version of curried functions is [going away in Swift 3](https://github.com/apple/swift-evolution/blob/master/proposals/0002-remove-currying.md)[^swift3] and it made me sad. While this is a more esoteric language feature, I really like how curried functions can be used to simplify an API. Also, the way Swift implemented curried functions made them so easy to use.

[^swift3]: Note that function currying isn't going away, only the nice shorthand (sweet :lollipop:) syntax is.

Isn’t this:

```swift
func fourChainedFunctions(a: Int)(b: Int)(c: Int)(d: Int) -> Int {
  return a + b + c + d
}
```

…so much cleaner than this? [^curried-function-example]

```swift
func fourChainedFunctions(a: Int) -> (Int -> (Int -> (Int -> Int))) {
  return { b in
    return { c in
      return { d in
        return a + b + c + d
      }
    }
  }
}

fourChainedFunctions(1)(2)(3)(4)
```

[^curried-function-example]: Borrowed with :heart: from the **Almighty Kraken** :octopus: [http://krakendev.io/blog/hipster-swift#currying](http://krakendev.io/blog/hipster-swift#currying)

Versions of these outlet/action assertion functions using the older, cleaner syntactic-sugary function currying can be reviewed on the [`deprecated-syntax`](https://github.com/phatblat/CurriedOutletFunctions/blob/deprecated-syntax/CurriedOutletFunctionsTests/SpecFunctions.swift#L47) tag of the example repo.

Apple, you can take my sweet curry, but you'll never take my Sriracha.

<center>
{% img /images/sriracha-clip-on-bag.jpg 400 'Small Sriracha bottle attached to messenger bag' title:'Sriracha2Go' %}
</center>

<br>

#### Footnotes
