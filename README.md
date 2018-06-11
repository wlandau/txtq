
<!-- README.md is generated from README.Rmd. Please edit that file -->

[![CRAN](http://www.r-pkg.org/badges/version/bbqr)](http://cran.r-project.org/package=bbqr)
[![Travis build
status](https://travis-ci.org/wlandau/bbqr.svg?branch=master)](https://travis-ci.org/wlandau/bbqr)
[![AppVeyor build
status](https://ci.appveyor.com/api/projects/status/github/wlandau/bbqr?branch=master&svg=true)](https://ci.appveyor.com/project/wlandau/bbqr)
[![Codecov](https://codecov.io/github/wlandau/bbqr/coverage.svg?branch=master)](https://codecov.io/github/wlandau/bbqr?branch=master)

# A bare-bones message queue for R

The `bbqr` package is a way for parallel processes in R to send messages
to each other. Let’s say Process A and Process B are working on a
parallel task together. First, both processes grab the queue.

``` r
path <- tempfile() # Define a path to your queue.
path # In real life, temp files go away when the session exits, so be careful.
#> [1] "/tmp/RtmpnxJghP/file1b452f08b87"
q <- bbqr(path) # Create the queue.
```

The queue uses flat text files in the folder you specified.

``` r
list.files(q$path) # The queue lives in this folder.
#> [1] "db"   "head" "lock"
q$list() # You have not pushed any messages yet.
#> [1] title   message
#> <0 rows> (or 0-length row.names)
q$empty()
#> [1] TRUE
q$count()
#> [1] 0
```

Then, Process A sends instructions to Process B.

``` r
q$push(title = "Hello", message = "process B.")
q$push(title = "Calculate", message = "sqrt(4)")
q$push(title = "Calculate", message = "sqrt(16)")
q$push(title = "Send back", message = "the sum.")
```

You can inspect the contents of the queue from either process.

``` r
q$list()
#>       title    message
#> 1     Hello process B.
#> 2 Calculate    sqrt(4)
#> 3 Calculate   sqrt(16)
#> 4 Send back   the sum.
q$count()
#> [1] 4
q$empty()
#> [1] FALSE
```

As Process A is pushing the messages, Process B can consume them.

``` r
q$pop(2) # If you pass 2, you are assuming the queue has >=2 messages.
#>       title    message
#> 1     Hello process B.
#> 2 Calculate    sqrt(4)
```

Those “popped” messages are not technically in the queue any longer, but
we can still see a full log of all the messages that were ever sent.

``` r
q$list()
#>       title  message
#> 1 Calculate sqrt(16)
#> 2 Send back the sum.
q$list(1) # You can specify the number of messages to list.
#>       title  message
#> 1 Calculate sqrt(16)
q$log()
#>       title    message
#> 1     Hello process B.
#> 2 Calculate    sqrt(4)
#> 3 Calculate   sqrt(16)
#> 4 Send back   the sum.
```

Let’s let Process B get the rest of the instructions.

``` r
q$pop() # q$pop() with no arguments just pops one message.
#>       title  message
#> 1 Calculate sqrt(16)
q$pop() # Call q$pop(-1) to pop all the messages at once.
#>       title  message
#> 1 Send back the sum.
```

Now let’s say Process B follows the instructions in the messages. The
last step is to send the results back to Process A.

``` r
q$push(title = "Results", message = as.character(sqrt(4) + sqrt(16)))
```

Process A can now see the results.

``` r
q$pop()
#>     title message
#> 1 Results       6
```

When you are done, you have the option to destroy the files in the
queue.

``` r
q$destroy()
file.exists(q$path)
#> [1] FALSE
```

This entire time, the queue was locked when either process was trying to
create, access, or modify it. That way, the results stay correct even
when multiple processes try to read or change the data at the same time.

# Similar work

## liteq

[Gábor Csárdi](https://github.com/gaborcsardi)’s
[`liteq`](https://github.com/r-lib/liteq) package offers essentially the
same functionality implemented with SQLite databases. It has a few
additional features (for example, the ability to detect crashed workers
and requeue failed messages). However, at the time `bbqr` was
implemented, `liteq` was [still in an early stage of
development](https://github.com/r-lib/liteq/issues/17).

## Other message queues

There is a [plethora of message queues](http://queues.io/) beyond R,
most notably [ZeroMQ](http://zeromq.org) and
[RabbitMQ](https://www.rabbitmq.com/). In fact, [Jeroen
Ooms](http://github.com/jeroen) and [Whit
Armstrong](https://github.com/armstrtw) maintain
[`rzmq`](https://github.com/ropensci/rzmq), a package to work with
[ZeroMQ](http://zeromq.org) from R. These tools may be ideal for
intermediate advanced users, but `bbqr` has two main advantages for
simple use cases.

1.  It does not require you to install anything outside R.
2.  Tools based on IP/TCP sockets may only be able to send one message
    at a time, but `bbqr` can send multiple messages before any are
    consumed. Some applications may need to allow for a backlog of
    unread messages.
