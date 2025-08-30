;;; $DOOMDIR/gtd-org.el -*- lexical-binding: t; -*-

(setq org-capture-templates
      `(("i" "Inbox" entry  (file "inbox.org")
         ,(concat "* TODO %?\n"
                  "/Entered on/ %U"))
        ("m" "Meeting" entry  (file+headline "agenda.org" "Future")
         ,(concat "* %? :meeting:\n"
                  "<%<%Y-%m-%d %a %H:00>>"))
        ("n" "Note" entry  (file "notes.org")
         ,(concat "* Note (%a)\n"
                  "/Entered on/ %U\n" "\n" "%?"))
                                        ;        ("@" "Inbox [mu4e]" entry (file "inbox.org")
                                        ;        ,(concat "* TODO Reply to \"%a\" %?\n"
                                        ;                 "/Entered on/ %U"))
        ))

(defun org-capture-inbox ()
  (interactive)
  (call-interactively 'org-store-link)
  (org-capture nil "i"))

;; Use full window for org-capture
(add-hook 'org-capture-mode-hook 'delete-other-windows)

(define-key global-map            (kbd "C-c a") 'org-agenda)
(define-key global-map            (kbd "C-c c") 'org-capture)
(define-key global-map            (kbd "C-c i") 'org-capture-inbox)

;(setq org-agenda-hide-tags-regexp ".")

;; Refile
(setq org-refile-use-outline-path 'file)
(setq org-outline-path-complete-in-steps nil)
(setq org-refile-targets
      '(("projects.org" :regexp . "\\(?:\\(?:Note\\|Tâche\\)s\\)")))


(setq org-todo-keywords
      '((sequence "TODO(t)" "NEXT(n)" "HOLD(h)" "|" "DONE(d)")
        (sequence "TOBUY(b)" "BOUGHT(o)" "|" "RCVD(r)")))

(defun log-todo-next-creation-date (&rest _)
  "Log NEXT creation time in the property drawer under the key \='ACTIVATED'"
  (when (and (string= (org-get-todo-state) "NEXT")
             (not (org-entry-get nil "ACTIVATED")))
    (org-entry-put nil "ACTIVATED" (format-time-string "[%Y-%m-%d]"))))
(add-hook 'org-after-todo-state-change-hook #'log-todo-next-creation-date)
