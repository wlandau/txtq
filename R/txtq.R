#' @title Create a message queue.
#' @description See the README at
#'   [https://github.com/wlandau/txtq](https://github.com/wlandau/txtq)
#'   and the examples in this help file for instructions.
#' @export
#' @param path Character string giving the file path of the queue.
#'   The `txtq()` function creates a folder at this path to store
#'   the messages.
#' @examples
#'   path <- tempfile() # Define a path to your queue.
#'   q <- txtq(path) # Create a new queue or recover an existing one.
#'   q$validate() # Check if the queue is corrupted.
#'   list.files(q$path()) # The queue lives in this folder.
#'   q$list() # You have not pushed any messages yet.
#'   # Let's say two parallel processes (A and B) are sharing this queue.
#'   # Process A sends Process B some messages.
#'   # You can only send character vectors.
#'   q$push(title = "Hello", message = "process B.")
#'   q$push(
#'     title = c("Calculate", "Calculate"),
#'     message = c("sqrt(4)", "sqrt(16)")
#'   )
#'   q$push(title = "Send back", message = "the sum.")
#'   # See your queued messages.
#'   # The `time` is a formatted character string from `Sys.time()`
#'   # indicating when the message was pushed.
#'   q$list()
#'   q$count() # Number of messages in the queue.
#'   q$total() # Number of messages that were ever queued.
#'   q$empty()
#'   # Now, let's assume process B comes online. It can consume
#'   # some messages, locking the queue so process A does not
#'   # mess up the data.
#'   q$pop(2) # Return and remove the first messages that were added.
#'   # With those messages popped, we are farther along in the queue.
#'   q$list()
#'   q$count() # Number of messages in the queue.
#'   q$list(1) # You can specify the number of messages to list.
#'   # But you still have a log of all the messages that were ever pushed.
#'   q$log()
#'   q$total() # Number of messages that were ever queued.
#'   # q$pop() with no arguments just pops one message.
#'   # Call pop(-1) to pop all the messages at once.
#'   q$pop()
#'   # There are more instructions.
#'   q$pop()
#'   # Let's say Process B follows the instructions and sends
#'   # the results back to Process A.
#'   q$push(title = "Results", message = as.character(sqrt(4) + sqrt(16)))
#'   # Process A now has access to the results.
#'   q$pop()
#'   # Clean out the popped messages
#'   # so the database file does not grow too large.
#'   q$push(title = "not", message = "popped")
#'   q$count()
#'   q$total()
#'   q$list()
#'   q$log()
#'   q$clean()
#'   q$count()
#'   q$total()
#'   q$list()
#'   q$log()
#'   # Optionally remove all messages from the queue.
#'   q$reset()
#'   q$count()
#'   q$total()
#'   q$list()
#'   q$log()
#'   # Destroy the queue's files altogether.
#'   q$destroy()
#'   # This whole time, the queue was locked when either Process A
#'   # or Process B accessed it. That way, the data stays correct
#'   # no matter who is accessing/modifying the queue and when.
#'   #
#'   # You can import a `txtq` into another `txtq`.
#'   # The unpopped messages are grouped together
#'   # and sorted by timestamp.
#'   # Same goes for the popped messages.
#'   q_from <- txtq(tempfile())
#'   q_to <- txtq(tempfile())
#'   q_from$push(title = "from", message = "popped")
#'   q_from$push(title = "from", message = "unpopped")
#'   q_to$push(title = "to", message = "popped")
#'   q_to$push(title = "to", message = "unpopped")
#'   q_from$pop()
#'   q_to$pop()
#'   q_to$import(q_from)
#'   q_to$list()
#'   q_to$log()
txtq <- function(path) {
  R6_txtq$new(path = path)
}

#' @title R6 class for `txtq` objects
#' @description See the [txtq()] function for full documentation and usage.
#' @seealso txtq
#' @export
R6_txtq <- R6::R6Class(
  classname = "R6_txtq",
  private = list(
    path_dir = character(0),
    db_file = character(0),
    head_file = character(0),
    lock_file = character(0),
    total_file = character(0),
    txtq_establish = function(path) {
      dir_create(path)
      private$path_dir <- path
      private$db_file <- file.path(private$path_dir, "db")
      private$head_file <- file.path(private$path_dir, "head")
      private$total_file <- file.path(private$path_dir, "total")
      private$lock_file <- file.path(private$path_dir, "lock")
      private$txtq_exclusive({
        file_create(private$db_file)
        if (!file.exists(private$head_file)) {
          private$txtq_set_head(0)
        }
        if (!file.exists(private$total_file)) {
          private$txtq_set_total(0)
        }
      })
      private$txtq_validate()
    },
    txtq_exclusive = function(code) {
      on.exit(filelock::unlock(lock))
      lock <- filelock::lock(private$lock_file)
      force(code)
    },
    txtq_get_head = function() {
      scan(private$head_file, quiet = TRUE, what = integer())
    },
    txtq_set_head = function(n) {
      write(x = as.integer(n), file = private$head_file, append = FALSE)
    },
    txtq_get_total = function() {
      scan(private$total_file, quiet = TRUE, what = integer())
    },
    txtq_set_total = function(n) {
      write(x = as.integer(n), file = private$total_file, append = FALSE)
    },
    # Faster than txtq_get_total and txtq_set_total
    # because it uses fewer connections:
    txtq_inc_total = function(n) {
      con <- file(private$total_file, "r+w")
      on.exit(close(con))
      old <- scan(con, quiet = TRUE, what = integer())
      out <- old + as.integer(n)
      write(x = out, file = con, append = FALSE)
    },
    txtq_count = function() {
      as.integer(
        private$txtq_get_total() - private$txtq_get_head()
      )
    },
    txtq_pop = function(n) {
      out <- private$txtq_list(n = n)
      new_head <- private$txtq_get_head() + nrow(out)
      private$txtq_set_head(new_head)
      out
    },
    txtq_push = function(title, message) {
      time <- base64_urlencode(microtime())
      out <- paste(
        base64_urlencode(as.character(title)),
        base64_urlencode(as.character(message)),
        time = rep(time, length(title)),
        sep = "|"
      )
      if (length(out) > 0) {
        private$txtq_inc_total(length(out))
        out <- paste(out, collapse = "\n")
        write(x = out, file = private$db_file, append = TRUE)
      }
    },
    txtq_reset = function() {
      unlink(private$db_file, force = TRUE)
      file_create(private$db_file)
      private$txtq_set_head(0)
      private$txtq_set_total(0)
    },
    txtq_clean = function() {
      keep <- private$txtq_pop(n = private$txtq_count())
      private$txtq_reset()
      private$txtq_push(title = keep$title, message = keep$message)
    },
    txtq_log = function() {
      if (length(scan(private$db_file, quiet = TRUE, what = character())) < 1) {
        return(null_log)
      }
      read_db_table(
        dbfile = private$db_file,
        skip = 0,
        n = -1
      )
    },
    txtq_list = function(n) {
      if (n == 0L || private$txtq_count() < 1L) {
        return(null_log)
      }
      read_db_table(
        dbfile = private$db_file,
        skip = private$txtq_get_head(),
        n = n
      )
    },
    txtq_validate = function() {
      assert_dir(private$path_dir)
      assert_file(private$db_file)
      assert_file_scalar(private$head_file)
      assert_file_scalar(private$total_file)
    },
    txtq_import = function(queue) {
      stopifnot(inherits(queue, "R6_txtq"))
      ext_log <- queue$log()
      ext_total <- queue$total()
      ext_count <- queue$count()
      ext_head <- ext_total - ext_count
      ext_popped <- seq_len(ext_total) <= ext_head
      this_log <- private$txtq_log()
      this_total <- private$txtq_get_total()
      this_head <- private$txtq_get_head()
      this_popped <- seq_len(this_total) <= this_head
      # nolint start
      new_popped <- rbind(
        ext_log[ext_popped,, drop = FALSE],
        this_log[this_popped,, drop = FALSE]
      )
      new_unpopped <- rbind(
        ext_log[!ext_popped,, drop = FALSE],
        this_log[!this_popped,, drop = FALSE]
      )
      new_popped <- new_popped[order(new_popped$time),, drop = FALSE]
      new_unpopped <- new_unpopped[order(new_unpopped$time),, drop = FALSE]
      # nolint end
      new_log <- rbind(new_popped, new_unpopped)
      unlink(private$db_file)
      file_create(private$db_file)
      private$txtq_push(title = new_log$title, message = new_log$message)
      new_head <- this_head + ext_total - ext_count
      private$txtq_set_head(new_head)
    }
  ),
  public = list(
    initialize = function(path) {
      private$txtq_establish(path)
    },
    path = function() {
      private$path_dir
    },
    count = function() {
      private$txtq_exclusive(private$txtq_count())
    },
    total = function() {
      private$txtq_exclusive(private$txtq_get_total())
    },
    empty = function() {
      private$txtq_exclusive(private$txtq_count()) < 1
    },
    log = function() {
      private$txtq_exclusive(private$txtq_log())
    },
    list = function(n = -1) {
      private$txtq_exclusive(private$txtq_list(n = n))
    },
    pop = function(n = 1) {
      private$txtq_exclusive(private$txtq_pop(n = n))
    },
    push = function(title, message) {
      private$txtq_exclusive(
        private$txtq_push(title = title, message = message)
      )
      invisible()
    },
    reset = function() {
      private$txtq_exclusive(private$txtq_reset())
      invisible()
    },
    clean = function() {
      private$txtq_exclusive(private$txtq_clean())
      invisible()
    },
    destroy = function() {
      unlink(private$path_dir, recursive = TRUE, force = TRUE)
      invisible()
    },
    validate = function() {
      private$txtq_validate()
      invisible()
    },
    import = function(queue) {
      private$txtq_exclusive(private$txtq_import(queue = queue))
      invisible()
    }
  )
)
