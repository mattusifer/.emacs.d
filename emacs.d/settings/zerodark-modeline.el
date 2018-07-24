;;; zerodark-modeline.el --- Just the modeline from the Zerodark Theme

(require 'all-the-icons)

(defmacro cached-for (secs &rest body)
  "Cache for SECS the result of the evaluation of BODY."
  (declare (debug t))
  (let ((cache (make-symbol "cache"))
        (last-run (make-symbol "last-run")))
    `(let (,cache ,last-run)
       (lambda ()
         (when (or (not (boundp ',last-run))
                   (null ,last-run)
                   (> (- (time-to-seconds (current-time)) ,last-run)
                      ,secs))
           (setf ,cache (progn ,@body))
           (setf ,last-run (time-to-seconds (current-time))))
         ,cache))))

(defcustom zerodark-use-paddings-in-mode-line t
  "When non-nil, use top and bottom paddings in the mode-line."
  :type 'boolean)

(defcustom zerodark-theme-display-vc-status 'full
  "Control how version control information is displayed."
  :type '(choice (const :tag "Display fork symbol and branch name" 'full)
                 (const :tag "Display fork symbol only" t)
                 (const :tag "Do not display any version control information" nil)))

(defface zerodark-ro-face
  '((t :foreground "#0088CC" :weight bold))
  "Face for read-only buffer in the mode-line.")

(defface zerodark-modified-face
  '((t :foreground "#ff6c6b" :height 0.9))
  "Face for modified buffers in the mode-line.")

(defface zerodark-not-modified-face
  '((t :foreground "#98be65" :height 0.9))
  "Face for not modified buffers in the mode-line.")

(defface zerodark-buffer-position-face
  '((t :height 0.9))
  "Face for line/column numbers in the mode-line.")

(defface zerodark-vc-face
  '((t :foreground "#61afef"))
  "Face for vc status in the mode-line.")

(defface zerodark-ok-face
  '((t :foreground "#61afef"))
  "Face for ok status in the mode-line.")

(defface zerodark-warning-face
  '((t :foreground "#da8548"))
  "Face for warning status in the mode-line.")

(defface zerodark-error-face
  '((t :foreground "#ff6c6b"))
  "Face for error status in the mode-line.")

(defvar zerodark-modeline-position '(:eval (propertize ":%l:%c %p " 'face (if (zerodark--active-window-p)
                                                                              'zerodark-buffer-position-face
                                                                            'mode-line-inactive)))
  "Mode line construct for displaying the position in the buffer.")

(defvar zerodark-modeline-buffer-identification '(:eval (propertize "%b" 'face 'bold))
  "Mode line construct for displaying the position in the buffer.")

(defvar zerodark-modeline-modified '(:eval (if (buffer-modified-p (current-buffer))
                                               (all-the-icons-faicon "floppy-o"
                                                                     :height 0.9
                                                                     :v-adjust 0
                                                                     :face (if (zerodark--active-window-p)
                                                                               'zerodark-modified-face
                                                                             'mode-line-inactive))
                                             (all-the-icons-faicon "check"
                                                                   :height 0.9
                                                                   :v-adjust 0
                                                                   :face (if (zerodark--active-window-p)
                                                                             'zerodark-not-modified-face
                                                                           'mode-line-inactive)))))

(defvar zerodark-modeline-ro '(:eval (if buffer-read-only
                                         (if (zerodark--active-window-p)
                                             (progn
                                               (propertize "RO " 'face 'zerodark-ro-face))
                                           (propertize "RO " 'face 'bold))
                                       "")))

(defvar zerodark-buffer-coding '(:eval (unless (eq buffer-file-coding-system (default-value 'buffer-file-coding-system))
                                         mode-line-mule-info)))

(defvar zerodark-modeline-vc '(vc-mode ("   "
                                        (:eval (all-the-icons-faicon "code-fork"
                                                                     :height 0.9
                                                                     :v-adjust 0
                                                                     :face (when (zerodark--active-window-p)
                                                                             (zerodark-git-face))))
                                        (:eval (when (eq zerodark-theme-display-vc-status 'full)
                                                 (propertize (truncate-string-to-width vc-mode 100 nil nil "...")
                                                             'face (when (zerodark--active-window-p)
                                                                     (zerodark-git-face))))))))

(defun zerodark-modeline-flycheck-status ()
  "Return the status of flycheck to be displayed in the mode-line."
  (when flycheck-mode
    (let* ((text (pcase flycheck-last-status-change
                   (`finished (if flycheck-current-errors
                                  (let ((count (let-alist (flycheck-count-errors flycheck-current-errors)
                                                 (+ (or .warning 0) (or .error 0)))))
                                    (propertize (format "✖ %s Issue%s" count (if (eq 1 count) "" "s"))
                                                'face (zerodark-face-when-active 'zerodark-error-face)))
                                (propertize "✔ No Issues"
                                            'face (zerodark-face-when-active 'zerodark-ok-face))))
                   (`running     (propertize "⟲ Running"
                                             'face (zerodark-face-when-active 'zerodark-warning-face)))
                   (`no-checker  (propertize "⚠ No Checker"
                                             'face (zerodark-face-when-active 'zerodark-warning-face)))
                   (`not-checked "✖ Disabled")
                   (`errored     (propertize "⚠ Error"
                                             'face (zerodark-face-when-active 'zerodark-error-face)))
                   (`interrupted (propertize "⛔ Interrupted"
                                             'face (zerodark-face-when-active 'zerodark-error-face)))
                   (`suspicious  ""))))
      (propertize text
                  'help-echo "Show Flycheck Errors"
                  'local-map (make-mode-line-mouse-map
                              'mouse-1 #'flycheck-list-errors)))))

(defun true-color-p ()
  "Return non-nil on displays that support 256 colors."
  (or
   (display-graphic-p)
   (= (tty-display-color-cells) 16777216)))

(defvar zerodark--git-face-cached (cached-for 1 (zerodark--git-face-intern)))

(defun zerodark--git-face-intern ()
  "Return the face to use based on the current repository status."
  (if (magit-git-success "diff" "--quiet")
      ;; nothing to commit because nothing changed
      (if (zerop (length (magit-git-string
                          "rev-list" (concat "origin/"
                                             (magit-get-current-branch)
                                             ".."
                                             (magit-get-current-branch)))))
          ;; nothing to push as well
          'zerodark-ok-face
        ;; nothing to commit, but some commits must be pushed
        'zerodark-warning-face)
    'zerodark-error-face))

(defun zerodark-git-face ()
  "Return the face to use based on the current repository status.
The result is cached for one second to avoid hiccups."
  (funcall zerodark--git-face-cached))

(defun zerodark-face-when-active (face)
  "Return FACE if the window is active."
  (when (zerodark--active-window-p)
    face))

;; So the mode-line can keep track of "the current window"
(defvar zerodark-selected-window nil
  "Selected window.")

(defun zerodark--set-selected-window (&rest _)
  "Set the selected window."
  (let ((window (frame-selected-window)))
    (when (and (windowp window)
               (not (minibuffer-window-active-p window)))
      (setq zerodark-selected-window window))))

(defun zerodark--active-window-p ()
  "Return non-nil if the current window is active."
  (eq (selected-window) zerodark-selected-window))

(add-hook 'window-configuration-change-hook #'zerodark--set-selected-window)
(add-hook 'focus-in-hook #'zerodark--set-selected-window)
(advice-add 'select-window :after #'zerodark--set-selected-window)
(advice-add 'select-frame  :after #'zerodark--set-selected-window)

(setq-default display-time-format "%F %H:%M")
(defun simple-mode-line-render (left right)
  "Return a string of `window-width' length containing LEFT, and RIGHT
 aligned respectively."
  (let* ((available-width (- (window-width) (length left) 2)))
    (format (format " %%s %%%ds " available-width) left right)))

;; (setq-default mode-line-format
;;               '((:eval (simple-mode-line-render
;;                         (format-mode-line `(
;;                                             "%e"
;;                                             mu/mode-line-ro
;;                                             ;; ,mode-line-mule-info
;;                                             ,mode-line-client
;;                                             ,mu/mode-line-modified
;;                                             ,mode-line-frame-identification
;;                                             " %[" mode-line-buffer-identification "%] %2 %m %2 "
;;                                             "%l/" ,(number-to-string (line-number-at-pos (point-max)))
;;                                             " "
;;                                             ,mu/mode-line-vc
;;                                             ))
;;                         (format-mode-line '(mode-line-misc-info
;;                                             display-time-string
;;                                             mode-line-end-spaces))))))

(defun zerodark-setup-modeline-format ()
  "Setup the mode-line format for zerodark."
  (interactive)
  (require 'flycheck)
  (require 'magit)
  (let ((class '((class color) (min-colors 89)))
        (light (if (true-color-p) "#ccd4e3" "#d7d7d7"))
        (comment (if (true-color-p) "#687080" "#707070"))
        (purple "#c678dd")
        (mode-line (if "#1c2129" "#222222")))
    (custom-set-faces
     ;; Mode line faces
     `(mode-line ((,class (:background ,mode-line
                                       :height 0.9
                                       :foreground ,light
                                       :box ,(when zerodark-use-paddings-in-mode-line
                                               (list :line-width 6 :color mode-line))))))
     `(mode-line-inactive ((,class (:background ,mode-line
                                                :height 0.9
                                                :foreground ,comment
                                                :box ,(when zerodark-use-paddings-in-mode-line
                                                        (list :line-width 6 :color mode-line))))))
     `(anzu-mode-line ((,class :inherit mode-line :foreground ,purple :weight bold)))
     ))

  (setq-default mode-line-format
                `("%e"
                  " "
                  ,zerodark-modeline-ro " "
                  ,zerodark-buffer-coding
                  mode-line-frame-identification " "
                  " "
                  ,zerodark-modeline-modified
                  " "
                  ,zerodark-modeline-buffer-identification
                  ,zerodark-modeline-position
                  ,(if zerodark-theme-display-vc-status
                       zerodark-modeline-vc
                     "")
                  "  "
                  (:eval (zerodark-modeline-flycheck-status))
                  "  "
                  mode-line-modes mode-line-misc-info mode-line-end-spaces
                  )))

(provide 'zerodark-modeline)
