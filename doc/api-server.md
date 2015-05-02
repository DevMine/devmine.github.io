---
layout: default
title: doc/API-server
permalink: /doc/api-server/
---
<span class="pull-right">
<a class="dm-grey" href="https://github.com/DevMine/api-server">View on GitHub <i class="fa fa-github"></i></a>
</span>

{% remote_markdown https://raw.githubusercontent.com/DevMine/api-server/master/README.md %}

## Internals

### Composition function

The composition function computes the final ranking of developers according to a
given user query. For all features, it retrieves the corresponding pre-computed
developer scores from the database, normalizes them by dividing each score by
the maximum score for that very feature, and builds a big sparse matrix. In
order to decrease the response time, this matrix is pre-computed when the API
server is started. The default weights per feature are also fetched from the
database and the weights are increased or decreased based on the user query. A
column vector is then built from these weights. At this point, it is very
important that the columns of the sparse matrix match the rows of the weights
vector: it must have both, the same size and the same order. Finally, for
computing the final developer rank, the composition function uses a  weighted
sum model. To do so, it computes the dot product between the sparse matrix of
scores and the weights vector.

The scores matrix is loaded by functions from the `cache` package and the actual
dot product between the scores matrix and the adjusted features weights vector
is done in the `score` package.

The figure below illustrates the process.

![api-server-internals](/img/api-server-queries-internals.png)
