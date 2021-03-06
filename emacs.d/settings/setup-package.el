(require 'package)
(package-initialize)

;; build repo
(add-to-list 'package-archives
             '("melpa" . "https://melpa.org/packages/") t)
(add-to-list 'package-archives
             '("elpa" . "https://elpa.gnu.org/packages/") t)

(setq load-prefer-newer t)

(defun packages-install (packages)
  "Install all packages in the list that haven't already been installed"
  (dolist (it packages)
    (when (not (package-installed-p it))
      (package-install it)))
  (delete-other-windows))

(defun install-custom-packages ()
  (packages-install
   '(better-defaults
     ido-completing-read+
     smex
     company
     dashboard
     package-lint
     dash
     s
     async
     eyebrowse
     window-purpose
     all-the-icons
     iy-go-to-char
     dumb-jump
     god-mode

     ;; language server support
     lsp-mode
     company-lsp

     ;; docker
     dockerfile-mode

     ;; yaml
     yaml-mode

     ;; protobuf
     protobuf-mode

     ;; git
     magit
     magit-todos
     diff-hl

     ;; clojure/lisp
     paredit
     clojure-mode
     clojure-mode-extra-font-locking
     cider
     rainbow-delimiters

     ;; project navigation
     projectile
     helm
     ag

     ;; html
     tagedit
     web-mode

     ;; terraform
     terraform-mode

     ;; misc editing
     avy
     ace-window
     undo-tree
     real-auto-save
     multiple-cursors
     expand-region
     key-chord
     ripgrep

     ;; python
     python-mode
     virtualenvwrapper
     elpy
     python-pytest

     ;; rust
     rust-mode
     toml-mode
     cargo

     ;; groovy
     groovy-mode

     ;; java
     lsp-java

     ;; sql
     sql-indent

     ;; s3
     s3ed

     ;; elisp
     multi

     ;; php
     php-mode

     ;; haskell
     haskell-mode

     ;; go
     go-mode

     ;; javascript
     js2-mode
     elm-mode
     coffee-mode
     vue-mode
     tide
     rjsx-mode

     ;; scss
     scss-mode

     ;; scala
     scala-mode
     sbt-mode

     ;; markdown
     markdown-mode
     markdown-preview-mode

     ;; shell
     exec-path-from-shell
     vterm

     ;; themes
     monokai-theme
     base16-theme
     solarized-theme
     gruvbox-theme
     ujelly-theme
     kaolin-themes
     material-theme
     challenger-deep-theme
     doom-themes
     moe-theme
     zenburn-theme
     nord-theme
     dracula-theme
     color-theme-sanityinc-solarized
     color-theme-sanityinc-tomorrow
     )))

;; install any packages that haven't been installed yet
(condition-case nil
    (install-custom-packages)
  (error
   (package-refresh-contents)
   (install-custom-packages)))

;; Add external projects to load path
(defun search-for-elisp-dir (dir level)
  (let ((exclusions '("yasnippet-snippets")))

    ;; filter out exclusions
    (dolist (project (delq nil
                           (mapcar (lambda (proj)
                                     (when (not (member (car (last (split-string proj "/"))) exclusions))
                                         proj))
                                   (directory-files dir t "\\w+"))))
      (when (file-directory-p project)
        (let ((project-lisp-files
               (delq nil
                     (mapcar (lambda (subdir) (string-match ".el$" subdir))
                             (directory-files project t "\\w+"))))
              (project-directories
               (delq nil
                     (mapcar (lambda (subdir)
                               (when (file-directory-p subdir)
                                 subdir))
                             (directory-files project t "\\w+")))))
          (if (and (null project-lisp-files) (not (null project-directories)))
              (when (< level 2)
                (search-for-elisp-dir project (+ level 1)))
            (add-to-list 'load-path project)))))))

;; begin search at vendor dir
(search-for-elisp-dir vendor-dir 1)

(provide 'setup-package)
