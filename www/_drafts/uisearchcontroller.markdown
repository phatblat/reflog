---
layout: post
title: "UISearchController"
tags: swift, ios, tableview
---

A "search controller" is the thing behind a `UISearchBar` on iOS that is responsible for showing and hiding the "search results" screen (typically a table view) and updating the results in response to changes to the search term, character by character.

Let's go through the setup of a very simple search controller for an iOS app. It will display a list of Swift keywords in a table and filter them in response to text entered into the search bar.

## Search Bar

What's unexpected about `UISearchController` is that you have to _install_ its `searchBar` into the view hierarchy. You can't connect it to an existing `UISearchBar` defined in a storyboard.[^searchbar-storyboard] If you're just adding the search bar to the top of a table, like in Apple's sample code[^apple-sample-code], you can just make it the `tableHeaderView`. But just about any other situation is going to have to deal with auto layout.

[^searchbar-storyboard]: This was how the old, deprecated [`UISearchDisplayController`](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UISearchDisplayController_Class/) was often set up. There is even still a template for it in the Interface Builder Object library. ![Search Bar and Search Display Controller in Interface Builder Object library pane](/images/uisearchcontroller-search-bar-and-search-display-controller.png)

[^apple-sample-code]:  The [UISearchController](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UISearchController/#//apple_ref/doc/uid/TP40014432-CH1-SW8) reference documentation contains a minimal code sample.

```swift
override func viewDidLoad() {
  super.viewDidLoad()
  let searchBar = searchController.searchBar
  searchBar.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
  searchBarContainerView.addSubview(searchBar)
}
```

We're going to reserve some space in the UI using a "container" view[^container-view]. This will showi where the search bar will eventually be in the storyboard to give an idea of how it will fit with other UI elements. Also, constraints can be tied to the container view in the storyboard so that we don't have to install any in code.

[^container-view]: Nothing as fancy as [View Controller Containment](https://www.objc.io/issues/1-view-controllers/containment-view-controller/). Just a simple `UIView` which we'll be using as the parent view for the `UISearchBar`.

<center>
{% img /images/uisearchcontroller-main-scene.png 300 'Main scene showing search bar container view' title:'Main scene' %}
</center>

## Search Results Controller

In this example, we're going to use a simple `UITableViewController` with each cell displaying a single Swift keyword.

<center>
{% img /images/uisearchcontroller-search-results.png 300 'Search results table showing a list of swift keywords' title:'Search results' %}
</center>

## Search Controller

A `UISearchController` must be set up in code and it's constructor takes a single argument - a `UIViewController` which is going to display the search results. Here we pass in a reference to our `searchResultsController` stored in a property.

```swift
let searchController = UISearchController(searchResultsController: self.searchResultsController)
searchController.searchResultsUpdater = self
searchController.delegate = self

searchController.hidesNavigationBarDuringPresentation = true
searchController.dimsBackgroundDuringPresentation = false

searchController.searchBar.delegate = self
```

There is little interaction with `UISearchController` beyond creating one, configuring it and connecting it to the following:

1. the search results controller
2. a `UISearchResultsUpdating` (the `searchResultsUpdater`)
3. a `UISearchControllerDelegate` (optional)
4. a `UISearchBarDelegate` (optional)

## Search Results Updater

The `UISearchResultsUpdating` protocol is very simple, but it's where all the fun stuff happens:

```swift
func updateSearchResultsForSearchController(searchController: UISearchController)
  guard let searchTerm = searchController.searchBar.text else { return }
  // use searchTerm to filter search results
  ...
```

This method is called whenever the text changes in the search bar. The current text can be accessed through the `searchController` parameter. This makes it easy to make any object handle these updates.

It's common to also make the search results controller the `searchResultsUpdater` and have it conform to the `UISearchResultsUpdating` protocol. That configuration causes the search results controller to update itself with the latest search term. However, we're not going that route because of a special case we want to handle: a custom "empty results" view. Attempting to add a subview to a `UITableView` is fraught with peril, so we're not going to do that.


<center>
{% img /images/uisearchcontroller-no-results.png 300 'Empty search results screen' title:'Empty search results' %}
</center>

Instead the "main" view controller will be the `searchResultsUpdater` and it will pass the current `searchTerm` into the search results controller. The search results controller will take care of filtering and return the number of results displayed.

The "main" view controller will use the number of results displayed to determine when to show and hide the "no results" view.

```swift
  ...
  let displayedResultCount = searchResultsController.filterData(searchTerm)
  handleEmptyResults(displayedResultCount)
}

func handleEmptyResults(displayedResults: Int) {
  let showEmptyResultsView = (searchController.active && displayedResults == 0)
  emptyResultsView.hidden = !showEmptyResultsView
}
```

This `emptyResultsView` is defined in the storyboard and initially hidden.

## Code

That's pretty much it. I wanted to provide a simple example because there's a lot of confusing information out there on how this API works. Web searches are tainted with the old API since the type names are so similar.[^search-display-controller]

[^search-display-controller]: Do yourself a favor and never look at the API for `UISearchDisplayController` - it's deprecated anyway. I'm constantly confusing the two.

You can find the complete project on GitHub at the URL below:
**[https://github.com/phatblat/SearchController](https://github.com/phatblat/SearchController)**

The only other interesting aspect of this sample project is how the [Swift keywords are escaped](https://github.com/phatblat/SearchController/blob/master/SearchController/SwiftKeyword.swift) to serve as enum member values. Sure, it's easier to store them as strings but where's the fun in that?

## Other Types of Search Results

`UISearchController` is not coupled with the presentation of the search results, so we are free to use any kind of view controller to handle it. At [360\|iDev 2015](http://360idev.com), @jeremiahgage presented using a [UISearchController with a UICollectionView](https://github.com/phatblat/360iDev-Slides/blob/master/2015-Slides.md#uisearchcontroller-with-a-uicollectionview) which is a fabulous example especially since `UICollectionView` is so highly customizable.

### Footnotes
