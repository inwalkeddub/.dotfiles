;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!

(setq gnutls-log-level 3)

;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
(setq user-full-name "Kevin Rathbun"
      user-mail-address "kdrath@gmail.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-unicode-font' -- for unicode glyphs
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

(setq doom-font (font-spec :family "Fira Code" :size 14)
      doom-big-font (font-spec :family "Fira Code" :size 36)
      doom-variable-pitch-font (font-spec :family "Overpass" :size 14))
;; https://github.com/tonsky/FiraCode/wiki/Emacs-instructions
;; enable fira code ligatures on emacs-mac
(if (fboundp 'mac-auto-operator-composition-mode)
      (mac-auto-operator-composition-mode))

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'modus-vivendi)

;; start in fullscreen
(add-hook 'window-setup-hook #'toggle-frame-fullscreen)

;; add current workspace name and major mode icon
(after! doom-modeline
  (setq doom-modeline-persp-name t
        doom-modeline-major-mode-icon t))

(setq mac-command-modifier 'super)
(setq mac-option-modifier  'meta)

(map! "s-q" nil)
(map! "s-w" nil)

(setq which-key-max-description-length 35)

;; https://docs.doomemacs.org/v21.12/#/how-do-i.../include-underscores-in-evil-word-motions
;; gives underscore the word syntax-class
(modify-syntax-entry ?_ "w")

;; https://tecosaur.github.io/emacs-config/config.html
(setq-default
 uniquify-buffer-name-style 'forward
 window-combination-resize t
 x-stretch-cursor t)

(setq
 undo-limit 80000000
 evil-want-fine-undo t)

(setq confirm-kill-emacs nil)

;; startup size
(pushnew! initial-frame-alist
          '(width . 106)
          '(height . 64)
          '(left . 0)
          '(top . 0))

(global-subword-mode 1)

(setq frame-title-format
      '(""
        ;; (:eval "%b") ;; %b shows buffer name
        (:eval
         (let ((project-name (projectile-project-name)))
           (unless (string= "-" project-name)
             (format (if (buffer-modified-p)  " ◉ %s" "  ●  %s") project-name))))))

(setq display-line-numbers-type 'relative)

(setq org-directory "/Volumes/dev/org/")

(setq initial-major-mode 'emacs-lisp-mode)

(setq company-idle-delay 1.0) ;; was 0.5

(add-hook 'persp-before-deactivate-functions #'deactivate-mark)

;; f/F/t/T/s/S will repeat last search (after an initial one)
(after! evil-snipe (setq evil-snipe-repeat-keys t))

(display-time-mode t)

;; ELIDE COMMENTS (cribbed from hideshow.el)
;; used to elide excessive comments in crafting interpreters java source
(defun comments-fold ()
  "comment"
  (interactive)
  (goto-char (point-min))
  (while (comment-search-forward (point-max) t)
    (let ((c-reg (hs-inside-comment-p)))
      (when (and c-reg (car c-reg))
        (hs-make-overlay (car c-reg) (cadr c-reg) 'comment)))))

;; PDF
;;
;; to build pdf-tools
(setenv "PKG_CONFIG_PATH" "/usr/local/lib/pkgconfig:/usr/local/Cellar/libffi/3.2.1/lib/pkgconfig")
;; for pdf-tools on retina
(setq pdf-view-use-scaling t)
(setq-default pdf-view-display-size 'fit-width)

;; HLEDGER
(setq ledger-binary-path "hledger")
(setq ledger-mode-should-check-version nil)
(add-to-list 'auto-mode-alist '("\\.\\(h?ledger\\|journal\\|j\\)$" . ledger-mode))

;; NOTMUCH
(after! notmuch (set-popup-rule! "^\\*notmuch-hello" :ignore t))

;; DIFF
;; FIX: "SPC f" show "+Find directory" instead of "diff"
(map! :leader
       (:prefix "f"
        :desc "" "d" nil  ; remove existing binding
        (:prefix ("d" . "diff")
         :desc "3 files" "3" #'ediff3
         :desc "ediff" "d" #'diff
         :desc "ediff" "e" #'ediff
         :desc "version" "r" #'vc-root-diff
         :desc "version" "v" #'vc-ediff)))

;; FORMAT
(map! :leader
       (:prefix ("=" . "format")
         :desc "buffer" "=" #'+format/buffer
         :desc "buffer" "b" #'+format/buffer
         :desc "region" "r" #'+format/region
         :desc "whitespace" "w" #'delete-trailing-whitespace))

;; KEYCAST - show keys and commands in modeline
;; https://github.com/staticaland/doom-emacs-config/blob/master/config.el
(use-package! keycast
  :commands keycast-mode   ;; load package on issuing command
  :config
  (define-minor-mode keycast-mode
    "Show current command and its key binding in the mode line."
    :global t
    (if keycast-mode
        (progn
          (add-hook 'pre-command-hook 'keycast-mode-line-update t)
          (add-to-list 'global-mode-string '("" mode-line-keycast " ")))
      (remove-hook 'pre-command-hook 'keycast-mode-line-update)
      (setq global-mode-string (remove '("" mode-line-keycast " ") global-mode-string))))
  (custom-set-faces!
    '(keycast-command :inherit doom-modeline-debug
      :height 0.9)
    '(keycast-key :inherit custom-modified
      :height 1.1
      :weight bold)))

;; Toggle keycast-mode
(map! :leader
      (:prefix "t"
       :desc "keycast" "k" #'keycast-mode))

;; JAVASCRIPT
(setq-hook! 'rjsx-mode-hook +format-with-lsp nil) ; to use prettier

;; ASTRO
;; (use-package! treesit-auto
;;   :custom
;;   (treesit-auto-install 'prompt)
;;   :config
;;   (treesit-auto-add-to-auto-mode-alist 'all)
;;   (global-treesit-auto-mode))

;; (use-package! astro-ts-mode
;;   :after (treesit-auto)
;;   :init
;;   (when (modulep! +lsp)
;;     (add-hook 'astro-ts-mode-hook #'lsp! 'append))
;;   :config
;;   (let ((astro-recipe (make-treesit-auto-recipe
;;                        :lang 'astro
;;                        :ts-mode 'astro-ts-mode
;;                        :url "https://github.com/virchau13/tree-sitter-astro"
;;                        :revision "master"
;;                        :source-dir "src")))
;;     (add-to-list 'treesit-auto-recipe-list astro-recipe)))

(set-formatter! 'prettier-astro
  '("npx" "prettier" "--parser=astro"
    (apheleia-formatters-indent "--use-tabs" "--tab-width" 'astro-ts-mode-indent-offset))
  :modes '(astro-ts-mode))

(use-package! lsp-tailwindcss
  :when (modulep! +lsp)
  :init
  (setq! lsp-tailwindcss-add-on-mode t)
  :config
  (add-to-list 'lsp-tailwindcss-major-modes 'astro-ts-mode))

;; MDX Support
(add-to-list 'auto-mode-alist '("\\.\\(mdx\\)$" . markdown-mode))
(when (modulep! +lsp)
  (add-hook 'markdown-mode-local-vars-hook #'lsp! 'append))

;; CLOJURE

(add-hook 'clojure-mode-hook #'subword-mode) ; CamelCase support for editing Java names

(add-hook 'cider-mode-hook #'eldoc-mode)
(add-hook 'cider-repl-mode-hook #'eldoc-mode)

;; commented out after switching from company to corfu
;; (add-hook 'cider-mode-hook #'company-mode)
;; (add-hook 'cider-repl-mode-hook #'company-mode)

;; as per ~/.emacs.d/modules/lang/clojure/README.org
;; In recent versions, an option has been introduced that attempts to improve
;; the experience of CIDER by accessing java source & javadocs, though this
;; option is still currently considered beta.
(setq cider-enrich-classpath t)

;; skip warning when using gD to find all references
(setq cljr-warn-on-eval nil)

;; supports navigating to sources from stack trace
(setq cider-jdk-src-paths '("/Volumes/dev/java/adoptopenjdk-13.jdk"
                            "/Volumes/dev/clojure/sources/1.10.1"))

;; comment to see if this fixes indentation issues in repl after an exception
;; (add-hook 'cider-repl-mode-hook #'aggressive-indent-mode)

(setq cider-dynamic-indentation nil)

(setq cider-repl-pop-to-buffer-on-connect t)

;; When there's a cider error, show its buffer and switch to it
(setq cider-show-error-buffer t)
(setq cider-auto-select-error-buffer t)

(setq cider-repl-history-file (concat doom-cache-dir "cider-history"))
(setq cider-repl-wrap-history t)

(setq clojure-toplevel-inside-comment-form t)

(defun +toggle-lsp-eldoc-enable-hover ()
  "Toggle lsp-eldoc-enable-hover"
  (interactive)
  (setq lsp-eldoc-enable-hover (unless lsp-eldoc-enable-hover t))
  (message "LSP eldoc enable hover %s"
           (if lsp-eldoc-enable-hover "enabled" "disabled")))

(defun +toggle-lsp-ui-sideline-show-hover ()
  "Toggle lsp-ui-sideline-show-hover"
  (interactive)
  (setq lsp-ui-sideline-show-hover (unless lsp-ui-sideline-show-hover t))
  (message "LSP ui sideline show hover %s"
           (if lsp-ui-sideline-show-hover "enabled" "disabled")))

;; with SPC SPC counsel-projectile-find-file has sorting disabled, which stuffs
;; up prescient's ordering, this is fix
(setq counsel-projectile-sort-files t)

;; this doesn't work, the error buffer replaces the repl buffer
;; (after! cider (set-popup-rule! "^\\*cider-error*" :select nil))

;; (map!
;;  (:after clj-refactor
;;    :leader "r" clj-refactor-map))
;; (cljr-add-keybindings-with-prefix "r")

;; should this be inside of def-package! without the :after
;; (def-package! smartparens
;;  :config
;; or inside after!
;; (after! smartparens)

;; was working with (after! evil (define-key evil-normal-state-map (kbd "C-t") nil))

(map! :n "C-t" nil
      :n "C-h" #'evil-window-left
      :n "C-j" #'evil-window-down
      :n "C-k" #'evil-window-up
      :n "C-l" #'evil-window-right

      :m "gl"  #'open-line)

;; may need an :after lsp here
;; not working, says lsp-ui-menu not a command
;; :leader
;; (:prefix "c"
;; :n "i" #'lsp-ui-imenu))

(map!
 (:after smartparens
  :leader
  :map smartparens-mode-map
  :prefix "r"
  :n "a"      #'sp-beginning-of-sexp
  :n "e"      #'sp-end-of-sexp

  :n "d"      #'sp-down-sexp
  ;; :n "bd"  #'sp-backward-down-sexp ; not very useful
  :n "]"      #'sp-up-sexp
  :n "["      #'sp-backward-up-sexp

  ;; :n "f"   #'sp-forward-sexp ; not so useful
  :n "p"      #'sp-backward-sexp

  :n "n"      #'sp-next-sexp ; useful with =.= repeater
  ;; :n "p"   #'sp-previous-sexp ; not so useful

  :n "m"      #'sp-forward-symbol
  ;; :n "bm"  #'sp-backward-symbol

  :n "s"      #'sp-forward-slurp-sexp
  :n "S"      #'sp-backward-slurp-sexp
  :n "b"      #'sp-forward-barf-sexp
  :n "B"      #'sp-backward-barf-sexp

  :n "t"      #'sp-transpose-sexp
  :n "k"      #'sp-kill-sexp
  :n "hk"     #'sp-kill-hybrid-sexp
  ;; :n "bk"  #'sp-backward-kill-sexp
  :n "c"      #'sp-copy-sexp
  ;; :n "l"   #'delete-sexp ;; getting wrong type argument

  ;; :n "bwk" #'sp-backward-kill-word ;; just use M-DEL

  :n "u"      #'sp-unwrap-sexp
  ;; :n "bu"  #'sp-backward-unwrap-sexp

  ;; :n "o"   #'sp-transpose-hybrid-sexp ; not sure how to use

  :n "w"      #'sp-wrap-round
  :n "y"      #'sp-wrap-curly
  :n "r"      #'sp-wrap-square))

;; C-MODE
;; ~/.emacs.d/modules/lang/cc/README.org
(after! lsp-clangd
  (setq lsp-clients-clangd-args
        '("-j=3"
          "--background-index"
          "--clang-tidy"
          "--completion-style=detailed"
          "--header-insertion=never"
          "--header-insertion-decorators=0"))
  (set-lsp-priority! 'clangd 2))

;; COMMON LISP
;; fuzzy completion
(after! sly
  (setq sly-complete-symbol-function 'sly-flex-completions))

;; SCHEME
(setq geiser-chez-binary "chez")
(setq geiser-default-implementation 'chez)

;; PROLOG
;; use prolog instead of perl for .pl files
(add-to-list 'auto-mode-alist '("\\.\\(pl\\|pro\\|lgt\\)" . prolog-mode))
;;
;; https://github.com/jamesnvc/lsp_server
(after! lsp-mode
  (lsp-register-client
   (make-lsp-client
    :new-connection
    (lsp-stdio-connection (list "swipl"
                                "-g" "use_module(library(lsp_server))."
                                "-g" "lsp_server:main"
                                "-t" "halt"
                                "--" "stdio"))
    :major-modes '(prolog-mode)
    :priority 1
    :multi-root t
    :server-id 'prolog-ls)))

;; RETIRED
;;
;; C-o will show a list of available actions in a hydra
;; (setq ivy-read-action-function #'ivy-hydra-read-action)
;;
;; for access to system library source
;; someone reported simply doing this:
;; (if (eq system-type 'darwin) (add-hook 'c++-mode-hook (setq +cc-default-compiler-options "-isystem"))
;; henrik said it should actually be this:
;; (setf (alist-get 'c++-mode +cc-default-compiler-options) '("-std=c++1z" "-isystem/path/to/your/system/libs" ...))
;; commented 09172023 forgot how i was using this and whether it still works
;; (after! ccls
;;   (setq ccls-initialization-options
;;         '(:clang (:extraArgs ["-isystem/Library/Developer/CommandLineTools/usr/include/c++/v1"
;;                               "-isystem/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include"
;;                               "-isystem/usr/local/include"
;;                               "-isystem/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/clang/11.0.0/include"
;;                               "-isystem/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/include"
;;                               "-isystem/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include"
;;                               "-isystem/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/System/Library/Frameworks"]
;;                   :resourceDir "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/clang/11.0.0"))))

;; PROJECTILE
;; not working as expected:
;;(setq projectile-project-search-path (doom-files-in "/Volumes/dev" :depth 1 :type 'dirs :full t))

;; can run projectile-discover-projects-in-search-path dynamically after updating this
(setq projectile-project-search-path '(("/Volumes/dev" . 2)))

;; not working as expected
;;(setq projectile-globally-ignored-directories
;;      (append '(".DocumentRevisions-V100/") projectile-globally-ignored-directories))

;;
;; can do this now with build.deps
;;
;; ;; https://www.eigenbahn.com/2020/05/06/fast-clojure-deps-auto-reload
;; (defun prf/cider/send-to-repl (sexp &optional eval ns)
;;   "Send SEXP to Cider Repl. If EVAL is t, evaluate it.
;;    Optionally, we can change namespace by specifying NS."
;;   (cider-switch-to-repl-buffer ns)
;;   (goto-char cider-repl-input-start-mark)
;;   (delete-region (point) (point-max))
;;   (save-excursion
;;     (insert sexp)
;;     (when (equal (char-before) ?\n)
;;       (delete-char -1)))
;;   (when eval
;;     (cider-repl--send-input t)))
;; (defun prf/clj/pomegranate-dep (dep)
;;   "Format a Clojure Pomegranate dependency import for DEP."
;;   (concat
;;    (format
;;     "%s"
;;     ;; NB: this is clojure!
;;     `(use '[cemerick.pomegranate :only (add-dependencies)]))
;;    (s-replace-all
;;     `(("\\." . ".")
;;       ("mydep" . ,dep))
;;     (format
;;      "%S"
;;      ;; NB: this is clojure!
;;      `(add-dependencies :coordinates '[mydep]
;;                         :repositories (merge cemerick.pomegranate.aether/maven-central
;;                                              {"clojars" "https://clojars.org/repo"}))))))
;;
;; (defun prf/cider/inject-pomegranate-dep (&optional dep ns)
;;   "Auto-import DEP in the current Clojure Repl using Pomegranate.
;;    Optionally, we can change namespace by specifying NS."
;;   (interactive)
;;   (setq dep (or dep (read-string "Dep: ")))
;;   (prf/cider/send-to-repl (prf/clj/pomegranate-dep dep) t ns))

;; ~/.emacs.d/.local/straight/repos/sly/contrib/sly-trace-dialog.el
;; (defvar sly-trace-dialog-mode-map
;;     (define-key map (kbd "G") 'sly-trace-dialog-fetch-traces)

;; map this to something else to keep consistent evil bindings
;; across buffers
;; (map!
;;  :after sly-trace-dialog
;;  :map evil-motion-state-map
;;  "G" nil
;;  :map sly-trace-dialog-mode-map
;;  "G" 'sly-trace-dialog-fetch-traces)


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.
