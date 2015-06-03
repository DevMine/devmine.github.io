---
title: writing a language parser
categories: technical
author: laurent
---

In order to analyze source code, the DevMine framework uses programming language
parsers that produce a [custom abstract syntax
tree](http://godoc.org/github.com/DevMine/srcanlzr/src)
([AST](http://en.wikipedia.org/wiki/Abstract_syntax_tree)). This article talks
about some of the steps that need to be taken in order to implement a language
parser that is not yet available to the framework.

The first step is usually finding a parser for the programming language you want
to parse. From a high level point a view, the goal is to transform the AST
returned by this parser into DevMine's custom AST. This means converting the
fields from the parser's AST into the corresponding structures of DevMine's AST,
as long as they exist in the language you are working on.

The new parser shall output JSON to the standard output. All logs or error
messages are expected to be written to the standard error output. This is the
expected behavior that allows different tools of the framework to be used in
chain via input/output piping. For instance, the output of the language parser
can be piped as input to `srctool` which can then pipe its output into
`srcanlzr`. Hence, for this to work, only JSON needs to be produced to the
standard output. Even informative messages need to be sent to standard error
output.

JSON marshalling shall follow the syntactic rules of the
[documentation](http://godoc.org/github.com/DevMine/srcanlzr/src) in order for
the JSON merger tools to work properly. In the case of an expression or a
statement, the first attribute of this structure in the JSON representation must
absolutely be the expression name, or the statement name, respectively. The best
way to ensure this is to build structures and their attibutes in the same order
than in the [documentation](http://godoc.org/github.com/DevMine/srcanlzr/src).

There are a few more points that require some attention. The first may appear to
be obvious but is still worth mentioning. A parser will only take care of the
source code files that belong to the language it is parsing. If the repository
is made of different programming languages, other parsers will then parse the
project to manage these languages.

The 'Project' structure of the AST is the one that contains all the others.
Basically, the JSON object returned by the parser is a 'Project'. Its name shall
be the name of the repository.

Furthermore, one of the attributes of the 'Project' structure is a list of
language structures. The parser shall return a list of one element. It is
`srcanlzr` which will take care of filling the languages list when merging
different JSON objects from different parsers when appropriate.

About the 'Package' structure, the 'name' attribute shall be the same as the
name of the folder that contains source code files. For the specific case where
source code files happen to be at the root of the repository, the name of the
package should then be the same as the repository.

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

The language parser will be run from the command line with a path as argument.
This path either refers to a source code repository or to a tar archive of such
a repository.Hence, it has to be able to handle both cases indifferently.

As the name given to the 'Project' structure may come from the path given as
argument when the parser is run, care should be taken not to use a dot when
parsing the current directory for instance, as this would lead to a wrong
result.  Absolute paths are preferred to relative ones. In the same vein, when
dealing with a tar archive of repository, the archive's name trimmed from its
suffix shall be used.

This article has been written having in mind the pitfall encountered while
writing and testing the DevMine's current parsers but it may not foresee every
possible difficulties. In any case, always refer to the
[documentation](http://godoc.org/github.com/DevMine/srcanlzr/src) in case of
doubt, and feel free to write us an email if you have any questions.
