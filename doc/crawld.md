---
layout: default
title: doc/crawld
permalink: /doc/crawld/
---
<span class="pull-right">
<a class="dm-grey" href="https://github.com/DevMine/crawld">View on GitHub <i class="fa fa-github"></i></a>
</span>

{% remote_markdown https://raw.githubusercontent.com/DevMine/crawld/master/README.md %}

## Internals

`crawld` consists of two main parts internally: the crawlers (only GitHub for
now) and the repositories fetcher (which only supports git for now).

The metadata crawled are put into the database whereas the repositories are
cloned on physical storage.

Note that the internal architecture of `crawld` has been thought to make it easy
to implement new crawlers or VCS backends.

![crawld internals](/img/crawld-internals.png)
