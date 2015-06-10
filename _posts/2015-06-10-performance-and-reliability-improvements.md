---
title: Recent performance and reliability improvements
categories: technical
author: robin
---

Our main focus for the past months has been on improving the existing tools.
This technical article talks about some of the steps we took to improve
both the quality and reliability of some of the DevMine tools and more
specifically about the improvements made on [crawld](/doc/crawld) and
[repotool](/doc/repotool).

Back in the last months of 2014, our focus on [crawld](/doc/crawld) has mainly
been on the crawlers part. The simple explanation is that the fetcher part was
good enough for the amount of data we had back then. We knew some parts needed
improvements like, for instance, the fetcher not being able to update a git
repository in a detached head state. However, performance was generally not an
issue. This hold true until [ght2dm](/doc/ght2dm) came into the game.

This spring, with [ght2dm](/doc/ght2dm), we started importing data from the
[GHTorrent](http://ghtorrent.org/) project. Suddenly, from the mere tens of
thousands repositories metadata we had, we ended up having millions. It is one
thing to clone and update a few thousands repositories, it is another when it
comes to hundreds of thousands.

## Performance improvements

### Use tar archives when storing source code repositories

As a first step, we cloned approximately 300'000 source code repositories. This
was a huge bump from the ~80'000 we had clone so far and we started having some
issues with the file system. For instance, we had no way to tell how large was
the directory in which we clone the repositories. Why? Because there was already
so many files that even after running for a week, `du(1)` would not return a
result... Something clearly had to be done...

At this point, we decided that storing too many files was not an option. Hence,
the decision was made to archive all source code repositories in tar format.
This meant that all the language parsers, [crawld](/doc/crawld) and
[repotool](/doc/repotool) had to be adapted to the change. For the language
parsers, the change was fairly easy: they simply have to be able to read the
content of a tar archive. However, it was another story for
[repotool](/doc/repotool) and something even more challenging for
[crawld](/doc/crawld).

[repotool](/doc/repotool) uses [git2go](https://github.com/libgit2/git2go), a
Go binding to [libgit2](https://libgit2.github.com), a C library which
implements the git protocol. Since it does not work on tar archives, the only
way to get commits information is by extracting the archive, at least the `.git`
directory of the git repository, because this is where repository information is
stored. This means that [repotool](/doc/repotool) has to extract a tar archive
before being able to read the repository information it looks for and, of
course, delete the extracted content afterwards.

In the same vein, [crawld](/doc/crawld) has to extract a repository archive
before being able to perform an update. Of course, if the tar option is
activated, it has to re-create the tar archive after the operation. Upon new
repository clone, it has to create a tar archive as well.

So this meant lots of changes but in the end, all the work was well worth it.
`du(1)` is now quick to calculate the size of the clone directory even with more
than 10TB of data. Having 1 file per repository instead of tens of thousands is
really a game changer. We also noticed a considerable speedup when parsing
source code from repositories. Indeed, only one `open`/`close` file operation is
now required per repository in order to parse the code. This changes
everything...

On the other hand, having to deal with tar archives brings a little overhead to
[crawld](/doc/crawld) and [repotool](/doc/repotool) operations. One of the
next paragraph explains how we dealt with this matter.

### Parallelize the tasks

Until recently, only two goroutines were spawned by [crawld](/doc/crawld): one
to crawl GitHub repositories, users and organizations metadata and another one
to fetch git repositories. As there is no hard dependency between two different
repositories, there is no reason not to use several goroutines for the fetching
part. So now, the user has the possibility to set the number of goroutines to
use to fetch repositories. This is especially an improvement now that there is
an induced overhead when storing source code in tar archives.

In the past, we used to use a script which was iterating over the repositories
giving repositories path location to a number of goroutines which were spawning
[repotool](/doc/repotool) processes to collect commits information.
It used to be decent enough in that it took about 2 weeks to collect ~15mio
commits and ~150mio commit diff deltas from the ~80'000 repositories and store
them into the database. This way of doing allowed `repotool` to run in parallel
but at the cost of spawning a lot of processes.

### Avoid spawning processes

[crawld](/doc/crawld) used to spawn git processes to clone and update
repositories. This worked okay for a moment but it is not viable when you need
to scale. Consider that a process is spawned each time we do a clone or update
operation on a repository, that throw-away process creation is costly and that
we now have millions of repositories to deal with. Hence, we decided to use
[libgit2](https://libgit2.github.com) via
[git2go](https://github.com/libgit2/git2go) which we were already using with
[repotool](/doc/repotool) with satisfying results.

Using this library allows us to take some shortcuts on repository update
operation. At first, one might think that it shall mimic the `git pull` command,
ie doing the equivalent of `git fetch && git merge FETCH_HEAD`. However,
repositories, in our context, are only meant to be read from. Hence, there shall
never be anything to actually merge. So the update operation only fetches
changes from remote and fast-forwards locally which avoids doing an actual
merge.

In the previous section, I mentioned that we were using a script to run several
instances of [repotool](/doc/repotool/) in parallel. Now, this means spawning
hundreds of thousands of processes to collect commits information from locally
stored repositories. Again, this used to work fine with a limited number of
repositories. Now that we have ~750'000 git repositories clone (and that it is
just small fraction of what we aim at collecting), it is a problem.  Hence, we
split [repotool](/doc/repotool) into two binaries, one to output information as
JSON which works like [repotool](/doc/repotool) always has, and another one,
`repotool-db`, which is responsible for inserting information into the database.
Now, instead of spawning costly process, it uses goroutine which is way lighter.
Also, we decided that inserting commit diff deltas was too much and we simply do
not collect them into the database anymore. `repotool-db` is still capable of
doing it but it is slower and generates a very large quantity of data. We were
also able to speed things up by inserting commits information in batches of 1mio
per transaction, having a routine which takes care of that, instead of one
transaction per commit. By not storing commit diff deltas, we are also now able
to disable foreign keys constraints and indexes which speed things up. In order
to associate commits information with repositories and users, we also used to
query the database 1 time per project to retrieve the repository ID and two
times per commit to get the author and committer IDs. You can guess that this
was impacting performances by a lot. Instead now, all repositories and users IDs
are now queried once when `repotool-db` starts and stored in a hashmap for a
O(1) access time.

### Use a ramdisk

Storing source code repositories as tar archives has several advantages as I
mentioned in a previous section. This does however bring some overhead for the
repositories update operation. Actually, [crawld](/doc/crawld) now appeared to
be limited by disk I/Os, without a surprise. Something had to be done and the
ideal solution for this case is to use a ramdisk. The only thing we care to
store is only the tar archive of the repositories after all. So
[crawld](/doc/crawld) has been modified to use a temporary directory, which can
be specified by the user, to extract tar archives in order to update the
repositories. After the update, repositories are simply re-tar'ed in their
original location. There is no reasons not to clone repositories in ramdisk as
well and create the tar archive on main storage afterwards. The only problem
which may arise by doing so is if the repository does not fit in size in the
ramdisk. Most of repositories are not very large so [crawld](/doc/crawld)'s
behavior is to attempt at cloning in the ramdisk and fallback to cloning
directly on main storage if that reveals to be impossible. By doing so, we
uncovered [a bug](https://github.com/libgit2/libgit2/pull/3174) in
[libgit2](https://libgit2.github.com) where attempting to clone a repository in
a not large enough partition leads to a crash because of a SIGBUS signal raised
from an attempt at mapping data somewhere it is not allowed to. Fortunately for
us, [Carlos Martín Nieto](https://github.com/carlosmn), one of the main
[libgit2](https://libgit2.github.com) developer was very quick to address that
issue.

[repotool](/doc/repotool) also uses a ramdisk when repositories are stored as
tar archives. Since it has to untar them in order to be able to collect commits
information, this is done in a ramdisk. Note that only the `.git` folder is
extracted since this is all that is required to collect the information. Of
course, this temporary directory is simply removed after the operation. Again,
doing this operation in RAM speeds things up considerably.

## Reliability improvements

### Take the right decision when errors are raised

Handling errors correctly is essential, especially with tools that are supposed
to run continuously for long period of times. However, it is not always clear at
first what the right decision is to handle some errors.

[crawld](/doc/crawld) used to skip a repository when it was not able to update
it. Now, when this happens, unless it is due to a network error, it deletes it
from disk and re-clones it. Not doing this when the error is network related is
very important because sometimes repositories are deleted from remote and we do
not want to delete our copy without any possibility to get it back afterwards.

### Restart where interrupted after a crash

Even with all our efforts to make the tools stable, crashes happen. They may be
related to a library error or an unexpected non-frequent condition, fact is that
they do happen. When the tool has been running for a few days, you are usually
quite sad if when checking if it still is running and you note that it has
stopped running and, moreover, that this means it has to start over from the
start again.

This is why [crawld](/doc/crawld) now remembers, using a file, the ID of the
last successfully processed repository. Hence, after a crash or having been
stopped on a voluntary basis, it can resume its operations where it stopped.

### Use an error rate based throttler

When a tool runs continuously for very long period of time, like
[crawld](/doc/crawld), you usually simply deal with an error and log it. This is
usually fine but think about how the tool would behave if the storage space is
full or the network is down? Yes, [crawld](/doc/crawld) would record _a lot_ of
errors and try to keep on going... This is obviously not a desired behavior. Our
take on this problem was to implement an error rate based throttler. What it
does now is that each error happening is not only dealt with and logged but it
is also recorded by the error rate based throttler. When the error rates gets
too high, and all the parameters can be adjusted by the user, which means that
something really wrong is probably happening, it automatically throttles all
routines for a predefined period of time. In consequence, [crawld](/doc/crawld)
pauses operations and when the administrator resolves the underlying problem,
such as freeing space on the storage device or restoring the network, all
operations are resumed.

## Conclusion

In this article, I mentioned several steps taken to improve performances and
reliability of [crawld](/doc/crawld) and [repotool](/doc/repotool). Nothing much
can be measured with regard to stability improvements but I can simply say that
things are now way better. However, to assess my performance improvement claims,
I shall provide some numbers. 

The [repotool](/doc/repotool) changes allow us to now insert ~20-25mio commits
per day on our machine (currently a server with an Intel Xeon CPU E5-2630L v2 @
2.40GHz processor, 128GB or ECC RAM and 20TB of storage in a 6 times 4TB RAID 5
configuration), which is a big improvement comparing to the ~15mio in two weeks
previously. To be completely fair, we do not insert commit diff deltas anymore
but we gained a huge speedup nonetheless.

As for [crawld](/doc/crawld), we have no real numbers to compare with. However,
I can say that we are now able to collect up to 8 times more data in a single
day than we used to collect in a week. With our server and infrastructure, we
are now able to clone/update ~6-8TB of repositories data per day.
