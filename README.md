<h1 align="center">
  <img width="128px" src="https://raw.githubusercontent.com/jimeh/yank-indent/main/img/yank-indent.svg" alt="Logo"><br />
  yank-indent
</h1>

<p align="center">
  <strong>
    Emacs minor-mode that ensures pasted (yanked) text has the correct indentation level.
  </strong>
</p>

<p align="center">
  <a href="https://github.com/jimeh/yank-indent/releases">
    <img src="https://img.shields.io/github/v/tag/jimeh/yank-indent?label=release" alt="GitHub tag (latest SemVer)">
  </a>
  <a href="https://github.com/jimeh/yank-indent/issues">
    <img src="https://img.shields.io/github/issues-raw/jimeh/yank-indent.svg?style=flat&logo=github&logoColor=white" alt="GitHub issues">
  </a>
  <a href="https://github.com/jimeh/yank-indent/pulls">
    <img src="https://img.shields.io/github/issues-pr-raw/jimeh/yank-indent.svg?style=flat&logo=github&logoColor=white" alt="GitHub pull requests">
  </a>
  <a href="https://github.com/jimeh/yank-indent/blob/master/LICENSE">
    <img src="https://img.shields.io/github/license/jimeh/yank-indent.svg?style=flat" alt="License Status">
  </a>
</p>

Do you often find yourself fixing the indentation of a code snippet right after
pasting it somewhere? Never again! yank-indent is the answer.

## Features

- A fire-and-forget style global mode that does the right thing most of time.
  Can be customized if you find it enables `yank-indent-mode` when it shouldn't.
- Configurable size threshold to prevent triggering indentation on very large
  regions which may cause performance issues in with some major-modes.

## Installation

### use-package + straight.el

```elisp
(use-package yank-indent
  :straight (:host github :repo "jimeh/yank-indent")
  :config (global-yank-indent-mode t))
```

### Manual

Place `yank-indent.el` somewhere in your `load-path` and require it. For example
`~/.emacs.d/vendor`:

```elisp
(add-to-list 'load-path "~/.emacs.d/vendor")
(require 'yank-indent)
(global-yank-indent-mode t)
```

## Usage

### `global-yank-indent-mode`

With `global-yank-indent-mode` enabled, you will find that `yank-indent-mode` is
automatically enabled in relevant buffers. The defaults will specifically
exclude common languages which are indentation sensitive like Python, YAML,
Makefile, etc.

For fine-grained control over which major-modes it is enabled in or not, see
customization options with `M-x customize-group RET yank-indent`.

### `yank-indent-mode`

If you prefer not to use the global mode, you can add `yank-indent-mode` as a
hook to relevant major-modes, or even manually toggle it on and off with
`M-x yank-indent-mode`.

To skip the indent operation for a single yank command, use a prefix command, so
`C-u C-y` instead of just `C-y`.

Keep in mind that the include/exclude major-mode customizations only affect the
global mode and which buffers it enables `yank-indent-mode` in. If you
explicitly enable `yank-indent-mode` in a buffer, it will operate like normal
regardless of what major-mode the buffer is using.

## Under the Hood

`yank-indent` registers an advice for after `yank` and `yank-pop` commands. The
advice function verifies that `yank-indent-mode` mode is enabled in the current
buffer, prefix argument was not given, and the yanked/pasted text was within the
`yank-indent-threshold` in size. If all true, it will trigger indentation,
otherwise it does nothing.
