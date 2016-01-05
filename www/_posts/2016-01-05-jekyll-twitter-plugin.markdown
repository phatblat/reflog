---
layout: post
title: "Jekyll Twitter Plugin"
date: 2016-01-05T12:51:55-07:00
---

One of the downsides to using Octopress over vanilla Jekyll when deploying a blog like this to GitHub Pages is that you have to explicitly generate your static site files. This is because Octopress deploys only the static site to GHP. A simple Jekyll site can actually push the markdown source and config files directly to GHP and let them generate the static site. This downside is more pronounced for me as I'm doing the vast majority of work on this blog from my iPad Pro, where I don't have a ruby environment to run the octopress and jekyll commands.

However, there is a big upside to this arrangement: you're not limitated to the few [Jekyll plugins](https://help.github.com/articles/using-jekyll-plugins-with-github-pages/) that GHP supports! GHP is simply hosting the generated site and I can run anything I want on my Mac to do that generation.

So, let's check out some nifty plugins, shall we?

# Embedded Tweets

In the spirit of markup free writing, I'd like to be able to reference a tweet by URL and have the content and formatting applied automatically. Luckily, there are plugins for this.

## jekyll-tweet-tag

The first plugin that I found when looking for this functionality is the obsolete [jekyll-tweet-tag](https://github.com/scottwb/jekyll-tweet-tag). Save yourself some time and don't bother installing this since it doesn't work with the current Twitter API.

Syntax:

```liquid class:"wrap"
{% tweet https://twitter.com/DEVOPS_BORAT/statuses/159849628819402752 %}
```

## jekyll-twitter-plugin

Based on the tweet-tag plugin, the [jekyll-twitter-plugin](https://github.com/rob-murray/jekyll-twitter-plugin) provides the same functionality but has been updated to work with the newer Twitter API preconditions (authentication keys) and also is a proper ruby gem for easier installation and updates.
The syntax is very similar:

```liquid class:"wrap"
{% twitter oembed https://twitter.com/DepressedDarth/status/683671063855759360 %}
```

{% twitter oembed https://twitter.com/DepressedDarth/status/683671063855759360 %}


### Ad Blockers

Note: if you're blocking the "Twitter Button" tracker with a browser plugin like Ghostery, you won't see the [Twitter Card](https://dev.twitter.com/cards/overview) version of these embedded tweets with images and they will instead fall back to a text-only version.

![Ghostery Safari plugin showing Twitter tracker blocked](/images/ghostery-twitter-button.png)


### align & width

There are a few formatting options, such as `align` and `width`:

```liquid class:"wrap"
{% twitter oembed https://twitter.com/DepressedDarth/status/684318431227727872 align='center' width='220' %}
```

{% twitter oembed https://twitter.com/DepressedDarth/status/684318431227727872 align='center' width='220' %}

The `width` parameter must be between 220 and 550 inclusive and seems to have no effect on the text-only rendering of the tweet.


### hide_media

This plugin will pass along any extra parameters like `hide_media` to the [oembed API](https://dev.twitter.com/rest/reference/get/statuses/oembed) for further customization.

```liquid class:"wrap"
{% twitter oembed https://twitter.com/DepressedDarth/status/684318431227727872 hide_media='true' %}
```

{% twitter oembed https://twitter.com/DepressedDarth/status/684318431227727872 hide_media='true' %}

Text rendering of the tweet is unaffected by `hide_media` because it only includes a link by default.

## Configuration

There are two options for configuring this Twitter plugin with your authentication keys:

1. Add them to `_config.yml`
2. Define them as environment variables

Since I'm tracking my `_config.yml` in git, shared publicly on GitHub, I'm opting for #2.

The challenge with environment variables is making sure they are defined whenever you need to run the command that depends on them. A simple solution is to add them to your `.bash_profile` or `.zshrc`, but since I'm _also_ [storing that on GitHub](https://github.com/phatblat/dotfiles/blob/master/.zshrc), I'm going to look for another option.

## .env File

Here is a very simple untracked file based solution. I created an `.env` file containing each environment variable on a separate line like so:

```bash class:"wrap"
TWITTER_CONSUMER_KEY=...
TWITTER_CONSUMER_SECRET=...
TWITTER_ACCESS_TOKEN=...
TWITTER_ACCESS_TOKEN_SECRET=...
```

The values in this file are then loaded into the environment for the Jekyll process on the fly using the `env` command.

```bash class:"wrap"
env $(cat .env | xargs) bundle exec jekyll serve
```

This is wrapped up neatly in a [`serve`](https://github.com/phatblat/dotfiles/blob/89dace6e7f9230e0b7f3ded261172f6bf7af2317/.dotfiles/www/octopress.zsh#L28) alias so I don't have to type (or remember) all that each time.

One caveat is that this command now generates an error if there is not an `.env` file in the current directory. I like that because I'm frequently in the wrong directory when I type `serve` and Jekyll is happy to create `_site` folders wherever I happen to be before blowing up in my face.

## Export

Note that the above environment variables can be loaded into the shell using the builtin `export` command instead of `env`. That is fine for testing, but leaves them defined in the environment for any other process to read.

```bash class:"wrap"
echo $TWITTER_CONSUMER_KEY
```

I tend to forget about this sort of thing (it works, :shipit:!) and would rather limit the exposure of sensitive values to the exact scope that they are needed.

# References

- <https://github.com/rob-murray/jekyll-twitter-plugin>
- <https://dev.twitter.com/rest/reference/get/statuses/oembed>
- <http://stackoverflow.com/questions/19331497/set-environment-variables-from-file>
