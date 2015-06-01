---
title: writing a language parser
categories: technical
author: laurent
---

To be able to analyze source code, the DevMine framework uses programming
language parsers that produce a [custom abstract syntax
tree](http://godoc.org/github.com/DevMine/srcanlzr/src)
([AST](http://en.wikipedia.org/wiki/Abstract_syntax_tree)). This article is
giving you some leads on how to proceed if you want to write a language parser
to add to the framework.

The first thing you might want to do is to find a parser for the programming
language you want to parse. From a high level point a view, the goal is to
transform the AST returned by this parser into the DevMine's custom AST.

From a given returned structure, you have to fill all the fields of the
corresponding custom structure, as long as they exist in the language you are
working on.

The parser shall output a JSON object to the standard output. All logs or error
messages are expected to be written to the standard error output. This is the
expected behavior that will allow the different tools of the framework to be
used in chain, the Unix way. You may then pipe the result of, let's say as an
example, the output of the language parser into the srctool and then pipe the
output into the srcanlzr tool. Take care to keep the standard output free from
anything else than the resulting JSON.

The JSON marshalling shall follow the syntactic rules of the
[documentation](http://godoc.org/github.com/DevMine/srcanlzr/src) in order for
the JSON merger tools to work properly. In the case of an expression or a
statement, the first attribute of this structure in the JSON representation must
absolutely be the expression name, or the statement name, respectively. The best
way to ensure this is to build structures and their attibutes in the same order
than in the [documentation](http://godoc.org/github.com/DevMine/srcanlzr/src).

There are a few more points that require some attention. The first may appear to
be an obvious one but is still worth mentioning. A parser will only take care of
the source code files that belong to the language it is parsing. If the
repository is made of different programming languages, other parsers will then
parse the project to manage these languages.

The 'Project' structure of the AST is the one that contains all the others.
Basically, the JSON object returned by the parser is a 'Project'. Its name shall
be the name of the repository.

Furthermore, one of the attributes of the 'Project' structure is a list of
language structures. The parser shall return a list of one element, it is the
srcanlzr tool that will take care of filling the whole languages list when
merging different JSON objects from different parsers when appropriate.

About the 'Package' structure, the 'name' attribute shall be the same as the
name of the folder that contains source code files. In the case where some
source code files would happen to be at the root of the repository, the name of
the package should then be the same as the repository.

Different structures have a number of lines of code as attribute. The parser
shall not count imports, comments nor annotations as lines of code. Only
statements and declarations are to be counted. Multilines of code such as in the
following snippet have to be counted as **1** line.


```java
String code = new StringBuilder()
           .append("Peace is a lie, there is only passion.\n")
           .append("Through passion, I gain strength.\n")
           .append("Through strength, I gain power.\n")
           .append("Through power, I gain victory.\n")
           .append("Through victory, my chains are broken.\n")
           .append("The force shall free me.")
           .toString();
```

The language parser will be run in command line with a path as argument. This
path will either refer to a source code repository or to a tar archive of such a
repository. It will then have to be able to manage both cases indifferently.

As the name given to the 'Project' structure may come from the path given as
argument when you run the parser, take care not to use a dot when parsing the
current directory for instance, as it would lead to a wrong result. Prefer an
absolute path rather than a relative. In the same area, the tar archive of the
repository should keep the name of the repository, as the name of the 'Project'
will certainly come from the archive name cleared from the tar suffix.

This article has been written having in mind the pitfall encountered while
writing and testing the DevMine's current parsers, but it may not foresee every
possible difficulty. In any case, always refer to the
[documentation](http://godoc.org/github.com/DevMine/srcanlzr/src) in case of
doubt, and feel free to write us an email.
