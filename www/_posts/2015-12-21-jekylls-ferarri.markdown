---
layout: post
title: Jekyll's Ferarri
date: 2015-12-21T17:37:11-07:00
categories: octopress jekyll blogging
---

I've finally gotten around to converting this blog over to [Octopress 3](http://octopress.org). The last hangup was the silliest issue. I was running the commands in the wrong directory.

# Octopress 2 vs. 3

Back at the start of 2014, it was actually a PITA it get v2 set up. A big part of this was due to the confusing way the markdown/sass source and generated HTML site was stored. The source was actually stored in a `source` branch, disconnected from the `master` branch in the same repo, which is where the generated site ended up. You'd have to make sure `source` was checked out before running any of the `rake` commands or get really confusing errors.

To deploy, you'd run `rake generate && rake deploy` which generates the static content and deploys that according to the configuration. In my case, deploying to GitHub Pages would update the site, but I'd still have to switch to the master branch and pull to update that branch.

## V3

Much improved over a fancy [Rakefile](https://github.com/phatblat/phatblat.github.io.bak/blob/source/Rakefile), Octopress 3 is a collection of gems.

###  CLI

The [CLI commands](https://github.com/octopress/octopress#octopress-cli-commands) are more intuitive:

octopress new post "Jekyll's Ferarri"
git commit -am "Add 'Jekyll's Ferarri' post"
octopress deploy

I could never remember the `rake new_post["title"]` syntax.

### Separate Repos

Now, instead of creating your blog from a fork of the framework used to generate it, these two are now cleanly separated. The framework is installed and updated through rubygems while the blog source and generated content are stored in two separate git repos. At least, that's how it's arranged when you're deploying to GitHub Pages.

- Source: https://github.com/phatblat/reflog
- Content: https://github.com/phatblat/phatblat.github.io

# Migration

The migration process is actually fairly straight-forward and has been detailed very well at:
http://samwize.com/2015/09/30/migrating-octopress-2-to-octopress-3

The only point I had trouble with was previewing the site using `bundle exec jekyll serve`. I got all kinds of [build warnings](https://github.com/benbalter/wordpress-to-jekyll-exporter/issues/37) about missing layouts. It certainly seemed like a path issue, but digging through the config and sass source I couldn't find anything obviously wrong. Turns out the issue is that this Jekyll command _must be run from inside the [**www**](https://github.com/phatblat/reflog/tree/master/www) directory_.

# Theme

Now that it's live on Octopress 3, this site doesn't look as nice. It's just using a default Jekyll theme. There are a ton of themes out there for Octopress 2, but since 3 isn't finished there aren't a lot of people using it yet or making themes for it. Hopefully, it will be easy to adapt a Jekyll theme.

# References

- http://octopress.org
- https://github.com/octopress/octopress
- https://github.com/octopress/octopress/issues/30
- http://octopress.org/2015/01/15/octopress-3.0-is-coming
- http://samwize.com/2015/09/30/migrating-octopress-2-to-octopress-3
- http://decomplecting.org/blog/2015/05/16/hello-octopress-3-0
- https://lauris.github.io/blogging/2014/08/16/jekyll-vs-octopress
