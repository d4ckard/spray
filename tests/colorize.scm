#! /bin/sh
#|
exec csi -s "$0" "$@"
|#

(load "src/colorize.scm")
(import colorizer)
(import c-regex)

(define (test-regex)
  (define (test-literal-regex)
    ;; Match a string made up of only a string literal.
    (assert (equal? (full-match literal-regex "\"blah\"")
		    "\"blah\""))
    ;; Match a string starting with a string literal.
    (assert (equal? (full-match  literal-regex "\"blah\" ... some more lame text")
		    "\"blah\""))
    ;; Don't match a string not starting with a string literal.
    (assert (not (regex-match? literal-regex "blah ... invalid text \"string literal\"")))
    ;; Match escaped backslashes and quotation marks.
    ;; After removing the backslashes to embed this string in this source,
    ;; the string below looks like this: "\\ \" ... blah "
    (assert (equal? (full-match literal-regex "\"\\\\ \\\" ... blah \"")
		    "\"\\\\ \\\" ... blah \"")))
  (test-literal-regex)
  (define (test-whitespace-regex)
    (assert (equal? (full-match whitespace-regex  " \t\t\r  ")
		    " \t\t\r  "))
    (assert (regex-match? whitespace-regex "\n \t  blah"))
    (assert (not (regex-match? whitespace-regex "blah \n  "))))
  (test-whitespace-regex)
  (define (test-identifier-regex)
    (assert (not (regex-match? identifier-regex "98blah")))
    (assert (equal? (full-match identifier-regex "blah_984baz")
		    "blah_984baz"))
    (assert (not (regex-match? identifier-regex "  \n blah"))))
  (test-identifier-regex)
  (define (test-hex-constant-regex)
    (assert (regex-match? hex-constant-regex "0x81babe"))
    (assert (not (regex-match? hex-constant-regex "92873")))
    (assert (regex-match? hex-constant-regex "0xbad1dealueLU")))
  (test-hex-constant-regex)
  (define (test-octal-constant-regex)
    (assert (regex-match? octal-constant-regex "01543672"))
    (assert (not (regex-match? octal-constant-regex "09082"))))
  (test-octal-constant-regex)
  (define (test-decimal-constant-regex)
    (assert (regex-match? decimal-constant-regex "780934lu"))
    ;; 0 is special in that it's the octal-prefix when followed by other digits.
    (assert (regex-match? decimal-constant-regex "0")))
  (test-decimal-constant-regex)
  (define (test-char-constant-regex)
    (assert (regex-match? char-constant-regex "'a'"))
    (assert (regex-match? char-constant-regex "'abc\\n'"))
    (assert (not (regex-match? char-constant-regex "blha 'a'"))))
  (test-char-constant-regex)
  (define (test-sci-constant-regex)
    (assert (regex-match? sci-constant-regex "81e-2")))
  (test-sci-constant-regex)
  (define (test-float-constant-regex-frac)
    (assert (regex-match? float-constant-regex-frac ".024E-3F"))
    (assert (regex-match? float-constant-regex-frac "0184.708e+9fl"))
    (assert (not (regex-match? float-constant-regex-frac "98.e+085L"))))
  (test-float-constant-regex-frac)
  (define (test-float-constant-regex-whole)
    (assert (regex-match? float-constant-regex-whole "983.E-3F"))
    (assert (regex-match? float-constant-regex-whole "0184.708e+9fl"))
    (assert (not (regex-match? float-constant-regex-whole ".41e+085L"))))
  (test-float-constant-regex-whole)
  (define (test-preproc-directive-regex)
    (assert (regex-match? preproc-directive-regex "#include"))
    (assert (regex-match? preproc-directive-regex "#undef"))
    (assert (regex-match? preproc-directive-regex "#include_next"))
    (assert (equal? (full-match preproc-directive-regex "#include <blah.h> int main ...")
		    "#include <blah.h>"))
    (assert (regex-match? preproc-directive-regex "#import \"blah.h\"")))
  (test-preproc-directive-regex)
  (define (test-comment-text-regex)
    (assert (equal? (full-match comment-text-regex "blah */ asdf")
		    "blah "))
    (assert (equal? (full-match comment-text-regex "blah \n * asdf */")
		    "blah \n * asdf "))
    (assert (equal? (full-match line-comment-text-regex "blah /* hey */ wow\n asdf")
		    "blah /* hey */ wow")))
  (test-comment-text-regex)
  'test-regex-passed)
(display (test-regex)) (newline)


(define (test-colorize)
  (define test-code (list "int main(void) {" "    int i = 0;" "    for (; i < 91; i++) {" "        printf(\"Blah: %d\" i);" "    }"))
  (assert (equal? (colorize test-code)
		  '(((tt-type . "int") (tt-whitespace . " ") (tt-identifier . "main") (tt-special-symbol . "(") (tt-type . "void") (tt-special-symbol . ")") (tt-whitespace . " ") (tt-special-symbol . "{")) ((tt-whitespace . "    ") (tt-type . "int") (tt-whitespace . " ") (tt-identifier . "i") (tt-whitespace . " ") (tt-operator . "=") (tt-whitespace . " ") (tt-constant . "0") (tt-special-symbol . ";")) ((tt-whitespace . "    ") (tt-keyword . "for") (tt-whitespace . " ") (tt-special-symbol . "(") (tt-special-symbol . ";") (tt-whitespace . " ") (tt-identifier . "i") (tt-whitespace . " ") (tt-operator . "<") (tt-whitespace . " ") (tt-constant . "91") (tt-special-symbol . ";") (tt-whitespace . " ") (tt-identifier . "i") (tt-operator . "++") (tt-special-symbol . ")") (tt-whitespace . " ") (tt-special-symbol . "{")) ((tt-whitespace . "        ") (tt-identifier . "printf") (tt-special-symbol . "(") (tt-literal . "\"Blah: %d\"") (tt-whitespace . " ") (tt-identifier . "i") (tt-special-symbol . ")") (tt-special-symbol . ";")) ((tt-whitespace . "    ") (tt-special-symbol . "}")))))
  ;; The colorizer doesn't accept 'Äpfel' which isn't a valid identifier.
  ;; However, it must continue correctly scanning the rest of the source
  ;; after finding a whitespace character.
  (assert (equal? (colorize  (list "int Äpfel = (6 + 4) * 9;"))
		  '(((tt-type . "int") (tt-whitespace . " ") (tt-other . "Äpfel") (tt-whitespace . " ") (tt-operator . "=") (tt-whitespace . " ") (tt-special-symbol . "(") (tt-constant . "6") (tt-whitespace . " ") (tt-operator . "+") (tt-whitespace . " ") (tt-constant . "4") (tt-special-symbol . ")") (tt-whitespace . " ") (tt-operator . "*") (tt-whitespace . " ") (tt-constant . "9") (tt-special-symbol . ";")))))
  ;; Single line C-style comments should work.
  (assert (equal? (colorize (list "int main(void) {" "    /* blah */" "    printf(\"blah\");" "}"))
		  '(((tt-type . "int") (tt-whitespace . " ") (tt-identifier . "main") (tt-special-symbol . "(") (tt-type . "void") (tt-special-symbol . ")") (tt-whitespace . " ") (tt-special-symbol . "{")) ((tt-whitespace . "    ") (tt-comment . "/*") (tt-comment-text . " blah ") (tt-uncomment . "*/")) ((tt-whitespace . "    ") (tt-identifier . "printf") (tt-special-symbol . "(") (tt-literal . "\"blah\"") (tt-special-symbol . ")") (tt-special-symbol . ";")) ((tt-special-symbol . "}")))))
  (assert (equal? (colorize (list "int a = 2;" "/*blah\nasdf */" "int b = 4;"))
		  '(((tt-type . "int") (tt-whitespace . " ") (tt-identifier . "a") (tt-whitespace . " ") (tt-operator . "=") (tt-whitespace . " ") (tt-constant . "2") (tt-special-symbol . ";")) ((tt-comment . "/*") (tt-comment-text . "blah\nasdf ") (tt-uncomment . "*/")) ((tt-type . "int") (tt-whitespace . " ") (tt-identifier . "b") (tt-whitespace . " ") (tt-operator . "=") (tt-whitespace . " ") (tt-constant . "4") (tt-special-symbol . ";")))))
  (assert (equal? (colorize (list "int blah = 5;" "/* I don't end," "But this is still me"))
		  '(((tt-type . "int") (tt-whitespace . " ") (tt-identifier . "blah") (tt-whitespace . " ") (tt-operator . "=") (tt-whitespace . " ") (tt-constant . "5") (tt-special-symbol . ";")) ((tt-comment . "/*") (tt-comment-text . " I don't end,")) ((tt-comment-text . "But this is still me")))))
  ;; Anything before the single `*/` must become a comment.
  (assert (equal? (colorize (list "int main(void) */ {int a = 0;"))
		  '(((tt-comment-text . "int main(void) ") (tt-trailing-uncomment . "*/") (tt-whitespace . " ") (tt-special-symbol . "{") (tt-type . "int") (tt-whitespace . " ") (tt-identifier . "a") (tt-whitespace . " ") (tt-operator . "=") (tt-whitespace . " ") (tt-constant . "0") (tt-special-symbol . ";")))))
  (assert (equal? (colorize (list "int" "a" "=" "2;" " */ /* another comment */"))
		  '(((tt-comment-text . "int")) ((tt-comment-text . "a")) ((tt-comment-text . "=")) ((tt-comment-text . "2;")) ((tt-comment-text . " ") (tt-trailing-uncomment . "*/") (tt-whitespace . " ") (tt-comment . "/*") (tt-comment-text . " another comment ") (tt-uncomment . "*/")))))
  (assert (equal? (colorize (list "int a = 7;  // This C++ style comment can contain this */ or that /*.""// It even continues on the next line!"))
		  '(((tt-type . "int") (tt-whitespace . " ") (tt-identifier . "a") (tt-whitespace . " ") (tt-operator . "=") (tt-whitespace . " ") (tt-constant . "7") (tt-special-symbol . ";") (tt-whitespace . "  ") (tt-comment . "//") (tt-comment-text . " This C++ style comment can contain this */ or that /*.")) ((tt-comment . "//") (tt-comment-text . " It even continues on the next line!")))))
  'test-colorize-passed)
(display (test-colorize)) (newline)
