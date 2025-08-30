;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

(defun training-extract-weight (headline)
  "Extract weight from headline string"
  (when (string-match "Weight: \\([0-9.]+\\)" headline)
    (string-to-number (match-string 1 headline))))

(defun training-extract-reps (headline)
  "Extract reps from headline string"
  (when (string-match "Reps \\([^ |]+\\)" headline)
    (match-string 1 headline)))

(defun training-get-property (prop)
  "Get property from exercise heading"
  (save-excursion
    (org-up-heading-safe)
    (org-entry-get nil prop)))

(defun training-get-training-days ()
  "Get training days from header"
  (let ((value (cadr (assoc "TRAINING_DAYS" (org-collect-keywords '("TRAINING_DAYS"))))))
    (when value
      (mapcar 'string-to-number (split-string value)))))

(defun training-calculate-next-weight (current-weight result)
  "Calculate next weight based on result and progression settings"
  (let* (
         (increment (cond
                     (( >= result 10) (string-to-number (training-get-property "PROGRESSION_FAST")))
                     (( and ( >= result 5) ( < result 10)) (string-to-number (training-get-property "PROGRESSION_MODERATE")))
                     (( and ( < result 5) ( > result 0)) (string-to-number (training-get-property "PROGRESSION_SLOW")))
                     (( = result 0) (string-to-number (training-get-property "PROGRESSION_FAILURE")))
                     (t 0))))
    (+ current-weight increment)))

(defun training-calculate-next-date ()
  "Calculate next training date based on interval and training days"
  (let* ((interval (string-to-number (training-get-property "TRAINING_INTERVAL")))
         (training-days (training-get-training-days))
         (today (time-to-days (current-time)))
         (current-day (calendar-day-of-week (calendar-gregorian-from-absolute today)))
         (days-ahead 0)
         (count 0))

    ;; Find the next training day that matches our interval
    (while (< count interval)
      (setq days-ahead (1+ days-ahead))
      (let ((next-day (% (+ current-day days-ahead -1) 7)))
        (when (member (1+ next-day) training-days)
          (setq count (1+ count)))))

    (time-add (current-time) (* days-ahead 24 3600))))

(defun training-add-to-history (weight reps result comments)
  "Add completed training to history table"
  (save-excursion
    (org-up-heading-safe)
    (if (re-search-forward "^\\*\\* History" nil t)
        (progn
          ;; Find the table
          (re-search-forward "^|" nil t)
          (org-table-goto-line 2) ; Skip header and separator
          (org-table-insert-row)
          (org-table-put nil 1 (format "[%s]" (format-time-string "%Y-%m-%d %a")))
          (org-table-put nil 2 (number-to-string weight))
          (org-table-put nil 3 reps)
          (org-table-put nil 4 (number-to-string result))
          (org-table-put nil 5 comments)
          (org-table-align))
      (error "History section not found"))))

(defun training-create-next-session (weight reps next-date)
  "Create new NEXT session with updated weight and scheduled date"
  (save-excursion
    (org-up-heading-safe)
    (org-insert-subheading t)
    (insert (format "TODO Weight: %s | Reps %s |" weight reps))
    (org-schedule nil (format-time-string "<%Y-%m-%d %a>" next-date))
    (org-move-subtree-up)
    ))

(defun training-refile-to-archive ()
  "Refile current headline under parent/History/Archive"
  (interactive)
  (let ((current-file (buffer-file-name))
        (target-pos nil))
    (save-excursion
      (org-up-heading-safe)
      (re-search-forward "^\\*\\* History" nil t)
      (re-search-forward "^\\*\\*\\* Archive" nil t)
      (setq target-pos (point)))
    (org-refile nil nil (list "Archive" current-file nil target-pos))))

(defun training-complete-session ()
  "Complete current training session and create next one"
  (interactive)
  (save-excursion
    (let* ((headline (nth 4 (org-heading-components)))
           (current-weight (training-extract-weight headline))
           (current-reps (training-extract-reps headline)))
      (unless current-weight
        (error "Could not extract weight from headline"))

      ;; Ask for result
      (let* ((result (read-number "Training results: "))
             (comments (read-string "Training comments: "))
             (next-weight (training-calculate-next-weight current-weight result))
             (next-date (training-calculate-next-date)))
        ;; Add to history
        (training-add-to-history current-weight current-reps result comments)

        ;; Mark current session as DONE
        (org-todo "DONE")
        (training-refile-to-archive)
        ;; Create next session
        (training-create-next-session next-weight current-reps next-date)

        (message "Training completed! Next session: %s lbs on %s"
                 next-weight
                 (format-time-string "%Y-%m-%d" next-date))))))

;; Hook to automatically call training-complete-session when marking NEXT as DONE
 (defun training-todo-state-change-hook ()
  "Hook function to handle training completion - only in training.org"
  (when (and (string= org-state "DONE")
             (string= org-last-state "TODO")
             ;; Only trigger in training.org file
             (string-suffix-p "workout.org" (buffer-file-name))
             (save-excursion
               (org-up-heading-safe)
               (org-entry-get nil "TRAINING_INTERVAL")))
    (training-complete-session)))

(add-hook 'org-after-todo-state-change-hook 'training-todo-state-change-hook)

;; Keybinding for manual completion
(define-key org-mode-map (kbd "C-c t") 'training-complete-session)

;; Template for new exercises
(defun training-new-exercise ()
  "Create a new exercise template"
  (interactive)
  (let ((exercise-name (read-string "Exercise name: "))
        (weight (read-number "Starting weight: "))
        (reps (read-string "Rep scheme (e.g., 5x5): "))
        (interval (read-number "Training interval (every X sessions): ")))

    (insert (format "* %s
:PROPERTIES:
:PROGRESSION_FAST: 10
:PROGRESSION_MODERATE: 5
:PROGRESSION_SLOW: 0
:PROGRESSION_FAILURE: -5
:TRAINING_INTERVAL: %d
:CATEGORY: %s
:END:
** TODO Weight: %s | Reps %s |
SCHEDULED: <%s>
:PROPERTIES:
:ACTIVATED: %s
:END:
** History
| Done | Weight | Reps | Result | Comments |
|------+--------+------+--------+----------|
|      |        |      |        |          |
*** Archive
"
                    exercise-name
                    interval
                    exercise-name
                    weight
                    reps
                    (format-time-string "%Y-%m-%d %a")
                    (format-time-string "[%Y-%m-%d]")))))

;; Capture template for quick training entry
(add-to-list 'org-capture-templates
             '("t" "Training Session" entry
               (file+headline "~/training.org" "Training Log")
               "* %(training-get-exercise-name)\n** NEXT Weight: %^{Weight} | Reps %^{Reps} |\nSCHEDULED: %^T\n:PROPERTIES:\n:ACTIVATED: %U\n:END:"
               :immediate-finish t))
