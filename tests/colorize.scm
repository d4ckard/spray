#! /bin/sh
#|
exec csi -s "$0" "$@"
|#

(load "src/colorize.scm")

(define (test-regex)
  (define (test-literal-regex)
    ;; Match a string made up of only a string literal.
    (assert (equal? (car (string-search literal-regex "\"blah\""))
		    "\"blah\""))
    ;; Match a string starting with a string literal.
    (assert (equal? (car (string-search literal-regex "\"blah\" ... some more lame text"))
		    "\"blah\""))
    ;; Don't match a string not starting with a string literal.
    (assert (not (string-search literal-regex "blah ... invalid text \"string literal\"")))
    ;; Match escaped backslashes and quotation marks.
    ;; After removing the backslashes to embed this string in this source,
    ;; the string below looks like this: "\\ \" ... blah "
    (assert (equal? (car (string-search literal-regex "\"\\\\ \\\" ... blah \""))
		    "\"\\\\ \\\" ... blah \"")))
  (test-literal-regex)
  (define (test-whitespace-regex)
    (assert (equal? (car (string-search whitespace-regex "   "))
		    "   "))
    (assert (equal? (car (string-search whitespace-regex "\n \t  \r blah"))
		    "\n \t  \r "))
    (assert (equal? (car (string-search whitespace-regex "blah \n  "))
		    "")))
  (test-whitespace-regex)
  (define (test-identifier-regex)
    (assert (not (string-search identifier-regex "98blah")))
    (assert (equal? (string-search identifier-regex "blah_984baz")
		    '("blah_984baz")))
    (assert (not (string-search identifier-regex "  \n blah"))))
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
    (assert (regex-match? preproc-directive-regex "#include <blah.h>"))
    (assert (regex-match? preproc-directive-regex "#import \"blah.h\"")))
  'test-regex-passed)
(display (test-regex)) (newline)


(define (test-tokenize)
  (define test-code "int main(void) {\n    int i = 0;\n    for (; i < 91; i++) {\n        printf(\"Blah: %d\" i);\n    }\n")
  (assert (equal? (tokenize test-code)
		  '((tt-type . "int") (tt-whitespace . " ") (tt-identifier . "main")
		    (tt-special-symbol . "(") (tt-type . "void") (tt-special-symbol . ")")
		    (tt-whitespace . " ") (tt-special-symbol . "{") (tt-whitespace . "\n    ")
		    (tt-type . "int") (tt-whitespace . " ") (tt-identifier . "i")
		    (tt-whitespace . " ") (tt-operator . "=") (tt-whitespace . " ")
		    (tt-constant . "0") (tt-special-symbol . ";") (tt-whitespace . "\n    ")
		    (tt-keyword . "for") (tt-whitespace . " ") (tt-special-symbol . "(")
		    (tt-special-symbol . ";") (tt-whitespace . " ") (tt-identifier . "i")
		    (tt-whitespace . " ") (tt-operator . "<") (tt-whitespace . " ")
		    (tt-constant . "91") (tt-special-symbol . ";") (tt-whitespace . " ")
		    (tt-identifier . "i") (tt-operator . "++") (tt-special-symbol . ")")
		    (tt-whitespace . " ") (tt-special-symbol . "{") (tt-whitespace . "\n        ")
		    (tt-identifier . "printf") (tt-special-symbol . "(") (tt-literal . "\"Blah: %d\"")
		    (tt-whitespace . " ") (tt-identifier . "i") (tt-special-symbol . ")")
		    (tt-special-symbol . ";") (tt-whitespace . "\n    ") (tt-special-symbol . "}")
		    (tt-whitespace . "\n"))))
  ;; The tokenizer doesn't accept 'Äpfel' which isn't a valid identifier.
  ;; However, it must continue correctly scanning the rest of the source
  ;; after finding a whitespace character.
  (assert (equal? (tokenize  "int Äpfel = (6 + 4) * 9;")
		  '((tt-type . "int") (tt-whitespace . " ") (tt-other . "Äpfel")
		    (tt-whitespace . " ") (tt-operator . "=") (tt-whitespace . " ")
		    (tt-special-symbol . "(") (tt-constant . "6") (tt-whitespace . " ")
		    (tt-operator . "+") (tt-whitespace . " ") (tt-constant . "4")
		    (tt-special-symbol . ")") (tt-whitespace . " ") (tt-operator . "*")
		    (tt-whitespace . " ") (tt-constant . "9") (tt-special-symbol . ";"))))
  'test-tokenize-passed)
(display (test-tokenize)) (newline)