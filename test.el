;;; test.el --- FFI tests for Emacs  -*- lexical-binding: t; -*-
;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Code:

(require 'ert)
(require 'ffi)

(define-ffi-library test-lib "test")

(define-ffi-function test-function "test_function" :int nil test-lib)
(define-ffi-function test-function-char "test_function" :char nil test-lib)

(ert-deftest ffi-basic ()
  (should (= (test-function) 27))
  (should (= (test-function-char) 27)))

(define-ffi-function test-c-string "test_c_string" :pointer nil test-lib)

(ert-deftest ffi-pointer-type ()
  (should (eq (type-of (test-c-string)) 'user-ptr)))

(ert-deftest ffi-c-string ()
  (should (equal (ffi-get-c-string (test-c-string)) "hello")))

(defun test-callback (arg)
  (1+ arg))

(define-ffi-function test-call-callback "test_call_callback"
  :int [:pointer] test-lib)

(ert-deftest ffi-call-callback ()
  (let* ((cif (ffi--prep-cif :int [:int]))
         (pointer-to-callback (ffi-make-closure cif #'test-callback)))
    (should (eq (test-call-callback pointer-to-callback) 23))))

(define-ffi-function test-add "test_add" :int [:int :int] test-lib)

(ert-deftest ffi-add ()
  (should (eq (test-add 23 -23) 0)))

(ert-deftest ffi-struct-layout ()
  (let ((struct-type (ffi--define-struct :int)))
    (should (eq (ffi--type-size struct-type)
                (ffi--type-size :int)))
    (should (eq (ffi--type-alignment struct-type)
                (ffi--type-alignment :int)))))

(ert-deftest ffi-struct-layout-offsets ()
  (let ((types '(:pointer :int)))
    (apply #'ffi--define-struct types)
    (should (equal (ffi--lay-out-struct types)
                   (list 0 (ffi--type-size :pointer))))))

(ert-deftest ffi-struct-layout-offsets-2 ()
  (let ((types '(:char :pointer)))
    (apply #'ffi--define-struct types)
    (should (equal (ffi--lay-out-struct types)
                   (list 0 (ffi--type-alignment :pointer))))))

(define-ffi-struct test-struct
  (stringval :type :pointer)
  (intval :type :int))

(define-ffi-function test-get-struct "test_get_struct"
  test-struct nil test-lib)

(ert-deftest ffi-structure-return ()
  (let ((struct-value (test-get-struct)))
    (should (equal (ffi-get-c-string (test-struct-stringval struct-value))
                   "string"))
    (should (eq (test-struct-intval struct-value) 23))))

(define-ffi-function test-get-struct-int "test_get_struct_int"
  :int (test-struct) test-lib)

(ert-deftest ffi-struct-modification ()
  (let ((struct-value (test-get-struct)))
    (should (eq (test-get-struct-int struct-value) 23))
    (cl-incf (test-struct-intval struct-value))
    (should (eq (test-get-struct-int struct-value) 24))))

(define-ffi-union test-union
  (cval :type :uchar)
  (ival :type :int))

(define-ffi-function test-get-union "test_get_union"
  test-union nil test-lib)

(ert-deftest ffi-union ()
  (let ((object (test-get-union)))
    (should (eq (test-union-ival object) -1))
    (should (eq (test-union-cval object) 255))))

(ert-deftest ffi-null ()
  (should (ffi-pointer-null-p (ffi-null-pointer))))

(define-ffi-function test-not "test_not" :bool (:bool) test-lib)

(ert-deftest ffi-boolean ()
  (should (eq (test-not nil) t))
  (should (eq (test-not t) nil))
  (should (eq (test-not 0) nil))
  (should (eq (test-not "hi") nil)))

(defconst test-user-defined-char :char)

(ert-deftest ffi-array ()
  (should (eq (define-ffi-array test-arr1 :char 1024)
              'test-arr1))
  (should (eq (define-ffi-array test-arr2 test-user-defined-char 1024)
              'test-arr2)))

(ert-deftest ffi-with-ffi-multi-stat ()
  (should (eq (with-ffi-temporary (a :int) 1 2 3) 3))
  (should (eq (with-ffi-temporaries ((a :int) (b :int)) 1 2 3) 3))
  (should (eq (with-ffi-string (a "test") 1 2 3) 3))
  (should (eq (with-ffi-strings ((a "s1") (b "s2")) 1 2 3) 3)))

;;; test.el ends here
