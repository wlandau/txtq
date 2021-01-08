
<!-- README.md is generated from README.Rmd. Please edit that file -->

[![CRAN](https://www.r-pkg.org/badges/version/txtq)](https://cran.r-project.org/package=txtq)
[![check](https://github.com/wlandau/txtq/workflows/check/badge.svg)](https://github.com/wlandau/txtq/actions?query=workflow%3Acheck)
[![Codecov](https://codecov.io/github/wlandau/txtq/coverage.svg?branch=main)](https://codecov.io/github/wlandau/txtq?branch=main)

# txtq - a small message queue for parallel processes

The `txtq` package helps parallel R processes send messages to each
other. Let’s say Process A and Process B are working on a parallel task
together. First, both processes grab the queue.

``` r
path <- tempfile() # Define a path to your queue.
path # In real life, temp files go away when the session exits, so be careful.
#> [1] "/var/folders/k3/q1f45fsn4_13jbn0742d4zj40000gn/T//RtmpezZ1r3/file6f34c3ca3b4"
q <- txtq(path) # Create a new queue or recover an existing one.
q$validate() # Check if the queue is corrupted.
```

The queue uses text files to keep track of your data.

``` r
list.files(q$path()) # The queue's underlying text files live in this folder.
#> [1] "db"    "head"  "lock"  "total"
q$list() # You have not pushed any messages yet.
#> [1] title   message time   
#> <0 rows> (or 0-length row.names)
```

Then, Process A sends instructions to Process B.

``` r
q$push(title = "Hello", message = "process B.")
q$push(
  title = c("Calculate", "Calculate"),
  message = c("sqrt(4)", "sqrt(16)")
)
q$push(title = "Send back", message = "the sum.")
```

You can inspect the contents of the queue from either process.

``` r
q$list()
#>       title    message                                 time
#> 1     Hello process B. 2021-01-08 08:16:52.610826 -0500 GMT
#> 2 Calculate    sqrt(4) 2021-01-08 08:16:52.625710 -0500 GMT
#> 3 Calculate   sqrt(16) 2021-01-08 08:16:52.625710 -0500 GMT
#> 4 Send back   the sum. 2021-01-08 08:16:52.628082 -0500 GMT
q$list(1) # You can specify the number of messages to list.
#>   title    message                                 time
#> 1 Hello process B. 2021-01-08 08:16:52.610826 -0500 GMT
q$count()
#> [1] 4
```

As Process A is pushing the messages, Process B can consume them.

``` r
q$pop(2) # If you pass 2, you are assuming the queue has >=2 messages.
#>       title    message                                 time
#> 1     Hello process B. 2021-01-08 08:16:52.610826 -0500 GMT
#> 2 Calculate    sqrt(4) 2021-01-08 08:16:52.625710 -0500 GMT
```

Those popped messages are not technically in the queue any longer.

``` r
q$list()
#>       title  message                                 time
#> 1 Calculate sqrt(16) 2021-01-08 08:16:52.625710 -0500 GMT
#> 2 Send back the sum. 2021-01-08 08:16:52.628082 -0500 GMT
q$count() # Number of messages technically in the queue.
#> [1] 2
```

But we still have a full log of all the messages that were ever sent.

``` r
q$log()
#>       title    message                                 time
#> 1     Hello process B. 2021-01-08 08:16:52.610826 -0500 GMT
#> 2 Calculate    sqrt(4) 2021-01-08 08:16:52.625710 -0500 GMT
#> 3 Calculate   sqrt(16) 2021-01-08 08:16:52.625710 -0500 GMT
#> 4 Send back   the sum. 2021-01-08 08:16:52.628082 -0500 GMT
q$total() # Number of messages that were ever queued.
#> [1] 4
```

Let’s let Process B get the rest of the instructions.

``` r
q$pop() # q$pop() with no arguments just pops one message.
#>       title  message                                 time
#> 1 Calculate sqrt(16) 2021-01-08 08:16:52.625710 -0500 GMT
q$pop() # Call q$pop(-1) to pop all the messages at once.
#>       title  message                                 time
#> 1 Send back the sum. 2021-01-08 08:16:52.628082 -0500 GMT
```

Now let’s say Process B follows the instructions in the messages. The
last step is to send the results back to Process A.

``` r
q$push(title = "Results", message = as.character(sqrt(4) + sqrt(16)))
```

Process A can now see the results.

``` r
q$pop()
#>     title message                                 time
#> 1 Results       6 2021-01-08 08:16:52.690375 -0500 GMT
```

The queue can grow large if you are not careful. Popped messages are
kept in the database file.

``` r
q$push(title = "not", message = "popped")
q$count()
#> [1] 1
q$total()
#> [1] 6
q$list()
#>   title message                                 time
#> 1   not  popped 2021-01-08 08:16:52.708969 -0500 GMT
q$log()
#>       title    message                                 time
#> 1     Hello process B. 2021-01-08 08:16:52.610826 -0500 GMT
#> 2 Calculate    sqrt(4) 2021-01-08 08:16:52.625710 -0500 GMT
#> 3 Calculate   sqrt(16) 2021-01-08 08:16:52.625710 -0500 GMT
#> 4 Send back   the sum. 2021-01-08 08:16:52.628082 -0500 GMT
#> 5   Results          6 2021-01-08 08:16:52.690375 -0500 GMT
#> 6       not     popped 2021-01-08 08:16:52.708969 -0500 GMT
```

To keep the database file from getting too big, you can clean out the
popped messages.

``` r
q$clean()
q$count()
#> [1] 1
q$total()
#> [1] 1
q$list()
#>   title message                                 time
#> 1   not  popped 2021-01-08 08:16:52.737766 -0500 GMT
q$log()
#>   title message                                 time
#> 1   not  popped 2021-01-08 08:16:52.737766 -0500 GMT
```

You can also reset the queue to remove all messages, popped or not.

``` r
q$reset()
q$count()
#> [1] 0
q$total()
#> [1] 0
q$list()
#> [1] title   message time   
#> <0 rows> (or 0-length row.names)
q$log()
#> [1] title   message time   
#> <0 rows> (or 0-length row.names)
```

When you are done, you can destroy the files in the queue.

``` r
q$destroy()
file.exists(q$path())
#> [1] FALSE
```

This entire time, the queue was locked when either process was trying to
create, access, or modify it. That way, the results stay correct even
when multiple processes try to read or change the data at the same time.

## Importing

You can import a `txtq` into another `txtq`. The unpopped messages are
grouped together and sorted by timestamp. Same goes for the popped
messages.

``` r
q_from <- txtq(tempfile())
q_to <- txtq(tempfile())
q_from$push(title = "from", message = "popped")
q_from$push(title = "from", message = "unpopped")
q_to$push(title = "to", message = "popped")
q_to$push(title = "to", message = "unpopped")

q_from$pop()
#>   title message                                 time
#> 1  from  popped 2021-01-08 08:16:52.791970 -0500 GMT

q_to$pop()
#>   title message                                 time
#> 1    to  popped 2021-01-08 08:16:52.796093 -0500 GMT

q_to$import(q_from)

q_to$list()
#>   title  message                                 time
#> 1  from unpopped 2021-01-08 08:16:52.814312 -0500 GMT
#> 2    to unpopped 2021-01-08 08:16:52.814312 -0500 GMT

q_to$log()
#>   title  message                                 time
#> 1  from   popped 2021-01-08 08:16:52.814312 -0500 GMT
#> 2    to   popped 2021-01-08 08:16:52.814312 -0500 GMT
#> 3  from unpopped 2021-01-08 08:16:52.814312 -0500 GMT
#> 4    to unpopped 2021-01-08 08:16:52.814312 -0500 GMT
```

# Network file systems

As an interprocess communication tool, `txtq` relies on the
[`filelock`](https://github.com/r-lib/filelock) package to prevent race
conditions. Unfortunately, `filelock` cannot prevent race conditions on
network file systems (NFS), which means neither can `txtq`. In other
words, on certain common kinds of clusters, `txtq` cannot reliably
manage interprocess communication for processes on different computers.
However, it can still serve as a low-tech replacement for a simple
non-threadsafe database.

# Similar work

## liteq

[Gábor Csárdi](https://github.com/gaborcsardi)’s
[`liteq`](https://github.com/r-lib/liteq) package offers essentially the
same functionality implemented with SQLite. It has a some additional
features, such as the ability to detect crashed workers and re-queue
failed messages, but it was in an early stage of development at the time
`txtq` was released.

## Other message queues

There is a plethora of message queues beyond R, most notably
[ZeroMQ](https://zeromq.org) and [RabbitMQ](https://www.rabbitmq.com/).
In fact, [Jeroen Ooms](https://github.com/jeroen) and [Whit
Armstrong](https://github.com/armstrtw) maintain
[`rzmq`](https://github.com/ropensci/rzmq), a package to work with
[ZeroMQ](https://zeromq.org) from R. Even in this landscape, `txtq` has
advantages.

1.  The `txtq` user interface is friendly, and its internals are simple.
    No prior knowledge of sockets or message-passing is required.
2.  `txtq` is lightweight, R-focused, and easy to install. It only
    depends on R and a few packages on
    [CRAN](https://cran.r-project.org).
3.  Because `txtq` it is file-based,
      - The queue persists even if your work crashes, so you can
        diagnose failures with `q$log()` and `q$list()`.
      - Job monitoring is easy. Just open another R session and call
        `q$list()` while your work is running.
