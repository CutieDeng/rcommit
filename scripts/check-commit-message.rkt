#lang racket/base

(require racket/cmdline
         racket/file
         racket/list
         racket/match
         racket/port
         racket/string)

(define message-file-arg ".commit")

(define allowed-types
  '(FEAT FIX REFACTOR TEST DOCS BUILD))

(define (eprintln msg)
  (displayln msg (current-error-port)))

(define (trim-git-comment-lines content)
  (define lines (string-split content "\n" #:trim? #f))
  (string-trim
   (string-join
    (for/list ([line (in-list lines)]
               #:unless (string-prefix? (string-trim line) "#"))
      line)
    "\n")))

(define (read-single-datum source)
  (call-with-input-string
   source
   (lambda (in)
     (define datum (read in))
     (define next (read in))
     (unless (eof-object? next)
       (raise-user-error 'commit-message "message must contain exactly one Racket datum"))
     datum)))

(define (feature-entry? value)
  (or (string? value)
      (symbol? value)))

(define (feature-form? value)
  (match value
    [(list-rest 'feature entries)
     (and (pair? entries)
          (andmap feature-entry? entries))]
    [_ #f]))

(define (valid-title? value)
  (and (string? value)
       (positive? (string-length value))
       (<= (string-length value) 50)))

(define (valid-detail? value)
  (and (string? value)
       (string-contains? value "Modified:")))

(define (valid-commit-datum? value)
  (match value
    [(list type title features detail)
     (and (memq type allowed-types)
          (valid-title? title)
          (feature-form? features)
          (valid-detail? detail))]
    [_ #f]))

(define (print-rules!)
  (begin
    (eprintln "Expected commit message shape:")
    (eprintln "")
    (eprintln "(FEAT \"title\"")
    (eprintln "")
    (eprintln "(feature ...)")
    (eprintln "\"detail info\"")
    (eprintln ")")
    (eprintln "")
    (eprintln "Rules: TYPE in FEAT/FIX/REFACTOR/TEST/DOCS/BUILD, title <= 50 chars, feature form required, detail must contain Modified:.")
  ))

(command-line
 #:program "check-commit-message.rkt"
 #:once-each
 [("--message-file") path "Commit message file to validate (default: .commit)"
                     (set! message-file-arg path)]
 #:args ()
 (void))

(unless (file-exists? message-file-arg)
  (eprintln (string-append "Commit message file does not exist: " message-file-arg))
  (exit 1))

(define message
  (trim-git-comment-lines (file->string message-file-arg)))

(when (string=? message "")
  (eprintln "Commit message is empty after removing comments.")
  (print-rules!)
  (exit 1))

(define datum
  (with-handlers ([exn:fail?
                   (lambda (exn)
                     (eprintln (string-append "Commit message is not a single readable Racket datum: "
                                              (exn-message exn)))
                     (print-rules!)
                     (exit 1))])
    (read-single-datum message)))

(unless (valid-commit-datum? datum)
  (eprintln "Commit message does not match the required Racket datum shape.")
  (print-rules!)
  (exit 1))
