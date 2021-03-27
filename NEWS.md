# Version 0.2.4

* Document NFS limitation (#19, @r2evans).
* Move CI to GitHub Actions.
* Change `open` argument of `file()` to `"r+"` (#20).

# Version 0.2.3

* Set a default for `use_lock_file` in the constructor.

# Version 0.2.2

* Skip some tests on CRAN to avoid parallel socket brittleness.

# Version 0.2.1

* Add R6 docstrings.
* Add a `use_lock_file` argument to allow users to disable the lock file (#18).

# Version 0.2.0

* Add the `import()` method.
* Bugfix: make `pop(0)` and `list(0)` return no messages.

# Version 0.1.6

* Fix indexing issue when pushing message of length 0 (#15, @daroczig).

# Version 0.1.5

* Allow `txtq`s to be created in subdirectories.

# Version 0.1.4

* Speed up `push()` by avoiding `data.frame()`, `write.table()`, namespaced function calls, and superfluous file connections.
* Remove dependency on `fs`.
* Add `$validate()` to check if the files are corrupted. Does not check the whole database file.

# Version 0.1.3

* Increase the precision of time stamps (to the microsecond) and store them as characters (more compact).

# Version 0.1.2

* Improved read performance for long messages.

# Version 0.1.1

* Store the POSIXct `Sys.time()` stamp of when each message is pushed.

# Version 0.1.0

* Add a new `$clean()` method to remove pushed messages from the database file.
* Add a new `$reset()` method to remove all messages from the database file, pushed or not.
* Add new `$establish()` and `$txtq_establish()` methods to do the most important work initailizing the queue.
* Ensure all public/API methods are one-liners that call private methods.

# Version 0.0.4

* Initial release
