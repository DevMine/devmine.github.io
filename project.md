---
layout: default
title: Project
permalink: /project/
---

# The DevMine project

## What it is about

DevMine is a project born at [EPFL](http://information.epfl.ch/introduction)
with ultimate goals of providing a developer search engine and a source code
analysis framework.

How are these goals related you may ask? Well, if you are looking for a
developer, you mostly likely want to find one with abilities that correspond to
your requirements and who does not produce loads of spaghetti code.

So this means that for the developer search engine to be good, it needs not only
to analyze things like in which programming languages a developer has
contributions but also evaluate the quality of them. This is why there is a
source code analysis framework and how it relates to the search engine.

## How it works

First, data needs to be collected. This might seem to be an easy to solve
problem but it is not once you deal with a lot of data.
DevMine collects metadata from platforms such as [GitHub](https://github.com/)
but it also downloads source code from projects.

Once data has been collected, a source code analysis is run. This is where
things get complicated since doing a source code analysis on one project is
already something not trivial but doing it on millions of projects is even more
challenging. The purpose of the analysis is to compute relevant metrics that
will be available at a later stage to compute so called 'features'.

Then there is the features computation stage. Features are used to evaluate
things like coding proficiency using a specific programming paradigm, quality of
contributions to an open source project and so on. These features are used to
rank all developers according to a user query so the one that fits the best the
query terms with the best expertise comes first.

Finally, all of this would be useless if the data is not served. This is why
there is a JSON RESTful API server which is used as the back-end to serve data
for a front-end application where users are actually able to issue queries.

## Sounds cool, can I try it?

Well, unfortunately, not yet. The DevMine project has seen research and
development for over a year now but is not ready for prime time yet even
though we are starting to see encouraging results.

## Who is behind the project?

A group of student from EPFL. See [about page](/about/) for more information.
