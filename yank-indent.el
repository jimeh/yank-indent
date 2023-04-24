;;; yank-indent.el --- Automatically indent yanked text -*- lexical-binding: t -*-

;; Author: Jim Myhrberg <contact@jimeh.me>
;; URL: https://github.com/jimeh/yank-indent
;; Keywords: convenience, yank, indent
;; Version: 0.1.0
;; Package-Requires: ((emacs "25.1"))

;; This file is not part of GNU Emacs.

;;; License:
;;
;; Copyright (c) 2023 Jim Myhrberg
;;
;; Permission is hereby granted, free of charge, to any person obtaining a copy
;; of this software and associated documentation files (the "Software"), to deal
;; in the Software without restriction, including without limitation the rights
;; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;; copies of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:
;;
;; The above copyright notice and this permission notice shall be included in
;; all copies or substantial portions of the Software.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.

;;; Commentary:
;;
;; Automatically indent yanked regions when yank-indent-mode is enabled.

;;; Code:

(defgroup yank-indent nil
  "Customization options for the yank-indent package.

The yank-indent package provides functionality to automatically
indent yanked text according to the current mode's indentation
rules. This group contains customization options for controlling
the behavior of `yank-indent-mode' and `global-yank-indent-mode'."
  :group 'editing)

(defcustom yank-indent-threshold 5000
  "Max characters in yanked region to trigger auto indentation.

If the yanked region contains more characters than the value
specified by `yank-indent-threshold', the automatic indentation
will not occur. This helps prevent performance issues when
working with large blocks of text."
  :type 'number)

(defcustom yank-indent-derived-modes '(prog-mode tex-mode)
  "Derived major modes where `yank-indent-mode' should be enabled.

When `global-yank-indent-mode' is enabled, it activates
`yank-indent-mode' in buffers with major modes derived from those
listed in this variable. This is useful when you want to enable
`yank-indent-mode' for all modes that inherit from a specific
mode, such as `prog-mode' for programming modes or `text-mode'
for text editing modes."
  :type '(repeat symbol))

(defcustom yank-indent-exact-modes '()
  "Major modes where `yank-indent-mode' should be enabled.

When `global-yank-indent-mode' is enabled, it activates
`yank-indent-mode' in buffers with major modes listed in this
variable. Unlike `yank-indent-derived-modes', `yank-indent-mode'
will not be activated in modes derived from those listed here.
Use this variable to list specific modes where you want
`yank-indent-mode' to be enabled without affecting their derived
modes."
  :type '(repeat symbol))

(defcustom yank-indent-excluded-modes '(cmake-ts-mode
                                        coffee-mode
                                        conf-mode
                                        haml-mode
                                        makefile-automake-mode
                                        makefile-bsdmake-mode
                                        makefile-gmake-mode
                                        makefile-imake-mode
                                        makefile-makepp-mode
                                        makefile-mode
                                        python-mode
                                        python-ts-mode
                                        slim-mode
                                        yaml-mode
                                        yaml-ts-mode)
  "Major modes where `yank-indent-mode' should not be enabled.

`global-yank-indent-mode' will not activate `yank-indent-mode' in
buffers with major modes listed in this variable or their derived
modes. This list takes precedence over
`yank-indent-derived-modes' and `yank-indent-exact-modes'. Use
this variable to exclude specific modes and their derived modes
from having `yank-indent-mode' enabled."
  :type '(repeat symbol))

(defun yank-indent--should-enable-p ()
  "Return non-nil if current mode should be indented."
  (and (not (minibufferp))
       (not (member major-mode yank-indent-excluded-modes))
       (or (member major-mode yank-indent-exact-modes)
           (apply #'derived-mode-p yank-indent-derived-modes))))

(defvar yank-indent--active-count 0
  "Number of active `yank-indent-mode' instances in the current Emacs session.")

(defun yank-indent--enable()
  "Handle ref counting and maybe add yank advice if needed."
  (setq yank-indent--active-count (1+ yank-indent--active-count))
  (when (eq yank-indent--active-count 1)
    (advice-add #'kill-buffer :around #'yank-indent--kill-buffer-advice)
    (advice-add #'yank :after #'yank-indent--after-yank-advice)
    (advice-add #'yank-pop :after #'yank-indent--after-yank-advice)))

(defun yank-indent--disable ()
  "Handle ref counting and maybe remove yank advice if no longer needed."
  (when (eq yank-indent--active-count 1)
    (advice-remove #'yank #'yank-indent--after-yank-advice)
    (advice-remove #'yank-pop #'yank-indent--after-yank-advice)
    (advice-remove #'kill-buffer #'yank-indent--kill-buffer-advice))
  (setq yank-indent--active-count (max (1- yank-indent--active-count) 0)))

(defun yank-indent--kill-buffer-advice (orig-fn &optional buffer)
  "Track `yank-indent-mode' state when killing BUFFER, then call ORIG-FN."
  (when buffer
    (with-current-buffer buffer
      (when (bound-and-true-p yank-indent-mode)
        (yank-indent--disable))))
  (funcall orig-fn buffer))

;;;###autoload
(define-minor-mode yank-indent-mode
  "Minor mode for automatically indenting yanked text.

When enabled, this mode indents the yanked region according to
the current mode's indentation rules, provided that the region
size is less than or equal to `yank-indent-threshold' and no
prefix argument is given during yanking."
  :lighter " YI"
  :group 'yank-indent
  (if yank-indent-mode
      (yank-indent--enable)
    (yank-indent--disable)))

;;;###autoload
(define-globalized-minor-mode global-yank-indent-mode
  yank-indent-mode
  (lambda ()
    (when (yank-indent--should-enable-p)
        (yank-indent-mode 1))))

(defun yank-indent--after-yank-advice (&optional _)
  "Conditionally indent the region (yanked text) after yanking.

Indentation is triggered only if all of the following conditions
are met:

- `yank-indent-mode' minor-mode is enabled in the current buffer.
- Prefix argument was not provided.
- Region size that was yanked is less than or equal to
  `yank-indent-threshold'.

This function is used as advice for `yank' and `yank-pop'
functions."
  (if (and yank-indent-mode
           (not current-prefix-arg))
      (let ((beg (region-beginning))
            (end (region-end))
            (mark-even-if-inactive transient-mark-mode))
        (if (<= (- end beg) yank-indent-threshold)
            (indent-region beg end)))))

(provide 'yank-indent)
;;; yank-indent.el ends here
