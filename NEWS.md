# Version 0.1.2

- Improved read performance for long messages.

# Version 0.1.1

- Store the POSIXct `Sys.time()` stamp of when each message is pushed.

# Version 0.1.0

- Add a new `$clean()` method to remove pushed messages from the database file.
- Add a new `$reset()` method to remove all messages from the database file, pushed or not.
- Add new `$establish()` and `$txtq_establish()` methods to do the most important work initailizing the queue.
- Ensure all public/API methods are one-liners that call private methods.

# Version 0.0.4

- Initial release
