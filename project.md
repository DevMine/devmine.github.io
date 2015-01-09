---
layout: default
title: Project
permalink: /project/
---

# The DevMine project

The DevMine project is about creating a database of developers and establishing
developers profiles based on their open source code contributions. This database
of developers may then be used to offer a service allowing people, typically
recruiters from companies, to search for developers with a specific set of
skills. The developers in the results are ranked by best match based on the user
query.

Several things are considered to evaluate developers skills. The DevMine project
calls them _features_. Some of them are used to filter results, others are used
to differentiate developers from each another.

For instance, you may want to hire a developer that knows about Java. DevMine
will look at all developers that have code contributions in Java. But of course,
this represents a lot of developers. So they are sorted according to several
criteria in order to provide good results. These criteria are not only based
on, for instance, the number of lines that a developer committed in that
language because this does not tell us anything about the quality of the
contributions.  So instead, DevMine will analyze the quality of the contributed
source code using several metrics such as cyclomatic complexity. Some developers
are also widely recognized as being behind some popular open source projects.
This can be measured as, for instance, their popularity on
[GitHub](https://github.com/) based on their number of followers and average
number of _stars_ per repository owned among other metrics.

But maybe you do not care about a specific programming language. Instead, you
want to hire someone that knows about, say, functional programming. Then a user
that has many source code contributions in Haskell and Lisp programming
languages is probably a good candidate.

Of course, other things that make a good developer do not concern programming
abilities directly. For instance, single word commit messages may indicate that
the developer is not very conscientious about documenting what he does. Also,
the amount of comments in the source code, such as function comments, indicates
how much he cares about explaining what he writes does.

Does this project sound interesting? Well, we do not have reach a final stage
yet but we are confident that we will. And best of all, all of this project is
open source so you can contribute in order to improve it.
