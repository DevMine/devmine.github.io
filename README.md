This is the sources of the DevMine project's website (http://devmine.ch/).

It is built with [Jekyll](http://jekyllrb.com/) as a static site.
The `master` branch contains only the generated files, ie what is in the `_site`.

To update the website, proceed like this:

* Make changes in the `source` branch.
* Build the site with Jekyll and test it locally.
* Commit your changes.
* Run `make publish`

This is the commands that are run when you type `make publish`:

```
git branch -D master
git checkout -b master
git filter-branch --subdirectory-filter _site/ -f
git checkout source
git push --all origin
```

The idea behind this process is from [@randymorris](https://github.com/randymorris)
(see [this](https://github.com/randymorris/randymorris.github.com/blob/source/README.md)).
