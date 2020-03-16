(require 'cl-lib)
(require 'ffi)

(cl-pushnew "/home/jonas/git/pep/sequoia/target/debug" load-path :test #'equal)

(define-ffi-library sequoia-openpgp-ffi "libsequoia_openpgp_ffi")

(define-ffi-function pgp-fingerprint-from-hex "pgp_fingerprint_from_hex"
  :pointer [:pointer] sequoia-openpgp-ffi)

(define-ffi-function pgp-fingerprint-to-string "pgp_fingerprint_to_string"
  :pointer [:pointer] sequoia-openpgp-ffi)

(define-ffi-function pgp-fingerprint-free "pgp_fingerprint_free"
  :void [:pointer] sequoia-openpgp-ffi)

;; Let us do https://docs.sequoia-pgp.org/sequoia_openpgp_ffi/index.html#objects:

(let* ((str (ffi-make-c-string "71FEF36B144438271DDCE4FA8F44F72AB931831C"))
       (fp (pgp-fingerprint-from-hex str))
       (pretty (pgp-fingerprint-to-string fp))
       (ret (ffi-get-c-string pretty)))
  (cl-assert (equal ret "71FE F36B 1444 3827 1DDC  E4FA 8F44 F72A B931 831C"))
  (ffi-free str)
  (ffi-free pretty)
  (pgp-fingerprint-free fp))
