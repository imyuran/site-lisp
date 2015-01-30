;;; auto-complete-php.el --- Auto Completion source for php for GNU Emacs

;; Copyright (C) 2014  jim 

;; Author: xcwenn@qq.com 
;; Keywords: completion, convenience
;; Version: 20140409.352
;; X-Original-Version: 0.1i
;; Package-Requires: ((auto-complete "1.3.1"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;; 参考 auto-complete-clang (补全), rtags (跳转堆栈 ac-php-location-stack-index )

;;; Commentary: 
;;
;; Auto Completion source for php. Most of codes are taken from

;;; Code:


(provide 'auto-complete-php)


;;load sys-data
(require 'auto-complete-php-sys-data)

(require 'auto-complete)
(require 'popup)

(defcustom ac-php-executable
  (executable-find "phpctags")
  "*Location of clang executable"
  :group 'auto-complete
  :type 'file)
(defcustom ac-php-cscope 
  (executable-find "cscope")
  "*Location of cscope executable"
  :group 'auto-complete
  :type 'file)



      


(defvar ac-php-location-stack-index 0)
(defvar ac-php-location-stack nil)

(defvar ac-php-max-bookmark-count 500 )
(defun ac-php-location-stack-push ()
  (let ((bm (ac-php-current-location)))
    (while (> ac-php-location-stack-index 0)
      (decf ac-php-location-stack-index)
      (pop ac-php-location-stack))
    (unless (string= bm (nth 0 ac-php-location-stack))
      (push bm ac-php-location-stack)
      (if (> (length ac-php-location-stack) ac-php-max-bookmark-count)
          (nbutlast ac-php-location-stack (- (length ac-php-location-stack) ac-php-max-bookmark-count))))))


(defun ac-php-goto-line-col (line column)
  (goto-char (point-min))
  (forward-line (1- line))
  (beginning-of-line)
  (forward-char (1- column)))

(defun ac-php-current-location (&optional offset)
  (format "%s:%d:%d" (or (buffer-file-name) (buffer-name))
          (line-number-at-pos offset) (1+ (- (or offset (point)) (point-at-bol)))))

(defun ac-php-find-file-or-buffer (file-or-buffer &optional other-window)
  (if (file-exists-p file-or-buffer)
      (if other-window
          (find-file-other-window file-or-buffer)
        (find-file file-or-buffer))
    (let ((buf (get-buffer file-or-buffer)))
      (cond ((not buf) (message "No buffer named %s" file-or-buffer))
            (other-window (switch-to-buffer-other-window file-or-buffer))
            (t (switch-to-buffer file-or-buffer))))))


(defun ac-php-goto-location (location &optional other-window )
  "Go to a location passed in. It can be either: file,12 or file:13:14 or plain file"
  ;; (message (format "ac-php-goto-location \"%s\"" location))
  (when (> (length location) 0)
    (cond ((string-match "\\(.*\\):\\([0-9]+\\):\\([0-9]+\\)" location)
           (let ((line (string-to-number (match-string-no-properties 2 location)))
                 (column (string-to-number (match-string-no-properties 3 location))))
             (ac-php-find-file-or-buffer (match-string-no-properties 1 location) other-window)
             ;;(run-hooks ac-php-after-find-file-hook)
             (ac-php-goto-line-col line column)
             t))
          ((string-match "\\(.*\\):\\([0-9]+\\)" location)
           (let ((line (string-to-number (match-string-no-properties 2 location))))
             (ac-php-find-file-or-buffer (match-string-no-properties 1 location) other-window)
             ;;(run-hooks ac-php-after-find-file-hook)
             (goto-char (point-min))
             (forward-line (1- line))
             t))
          ((string-match "\\(.*\\),\\([0-9]+\\)" location)
           (let ((offset (string-to-number (match-string-no-properties 2 location))))
             (ac-php-find-file-or-buffer (match-string-no-properties 1 location) other-window)
             ;;(run-hooks ac-php-after-find-file-hook)
			 (goto-char (1+ pos))
             t))
          (t
           (if (string-match "^ +\\(.*\\)$" location)
               (setq location (match-string-no-properties 1 location)))
           (ac-php-find-file-or-buffer location other-window)))
	(ac-php-location-stack-push)
   ))





(defsubst ac-php-clean-document (s)
  (when s
    (setq s (replace-regexp-in-string "<#\\|#>\\|\\[#" "" s))
    (setq s (replace-regexp-in-string "#\\]" " " s)))
  s)

(defun ac-php-document (item)
  (message "===%s" item )
  (if (stringp item)
      (let (s)
        (setq s (get-text-property 0 'ac-php-help item))
        (ac-php-clean-document s)))
  ;;(popup-item-property item 'ac-php-help)
  )


(defface ac-php-candidate-face
  '((t (:background "lightgray" :foreground "navy")))
  "Face for php candidate"
  :group 'auto-complete)

(defface ac-php-selection-face
  '((t (:background "navy" :foreground "white")))
  "Face for the php selected candidate."
  :group 'auto-complete)

(defun ac-php-get-cur-class-name ()
  "DOCSTRING"
  (let (line-txt cur-class-name )  
    (save-excursion
      (when (re-search-backward "^[ \t]*\\(abstract[ \t]+\\)*class[ \t]+" 0 t 1)
        (setq line-txt (buffer-substring-no-properties (line-beginning-position) (line-end-position)))
        (if (string-match   "class[ \t]+\\(\\w+\\)"   line-txt)
            (setq  cur-class-name  (match-string  1 line-txt)))))
    cur-class-name ))
(defun ac-php-get-class-at-point( )
  (let (line-txt    key-list   tmp-key-list frist-class-name  frist-key  ret-str )
  (setq line-txt (buffer-substring-no-properties
		    (line-beginning-position)
		    (1+ (point )) ))
  
  (setq line-txt (replace-regexp-in-string "\\<return\\>\\|\\<echo\\>" "" line-txt  ))
  (setq line-txt (replace-regexp-in-string ".*[=(,.]" "" line-txt  ))
  (setq line-txt (replace-regexp-in-string "^[^a-zA-Z]*" "" line-txt  ))
  (setq line-txt (replace-regexp-in-string "[\t \\$]" "" line-txt  ))
  (when (not (string=  line-txt "")  )
    ;;检查 :: 
    (if (and (string-match  "::"  line-txt ) (not (string-match  "\\/\\*"  line-txt ) ))
        (progn 
          (setq key-list (split-string line-txt "::" ))
          (setq frist-key (nth 0 key-list))
          (setq frist-class-name  frist-key  )
          (when (string= frist-key "parent" ) 
            (setq frist-class-name (concat (ac-php-get-cur-class-name) ".__parent__" ) ))
          (when (string= frist-key "self" ) 
            (setq frist-class-name (concat (ac-php-get-cur-class-name) ) )))


      (progn
        (setq key-list (split-string line-txt "->" ))
        (setq frist-key (nth 0 key-list))

        (save-excursion
          (re-search-backward (concat  frist-key"::" ) 0 t 1) 
          (setq key-line-txt (buffer-substring-no-properties
                              (line-beginning-position)
                              (line-end-position )))
          (if (string-match ( concat  frist-key "::\\(\\w+\\)" ) key-line-txt)
              (setq  frist-class-name  (match-string  1 key-line-txt))))

        (when (and(not frist-class-name) (or (string= frist-key "this")  ) ) 
          (setq frist-class-name (ac-php-get-cur-class-name)  ))
        )))

  
  (if frist-class-name 
	  (progn
		(setq ret-str  (concat frist-class-name ))
		(dolist (field-value (cdr key-list) )
		  (setq ret-str  (concat  ret-str "." field-value )))
		ret-str
		)
	;;(message "no find class from %s" frist-key )
	nil)))

(defun ac-php-candidate-class ( tags-data key-str-list  )
  ;;得到变量
  (let ( ret-list key-word output-list  class-name  (class-list (nth 0 tags-data)) (inherit-list (nth 2 tags-data))  )
    (setq key-str-list (replace-regexp-in-string "\\.[^.]*$" "" key-str-list ))
    (setq class-name (ac-php-get-class-name-by-key-list  tags-data key-str-list ))
	  (progn

        (setq  output-list (ac-php-get-class-member-list  class-list inherit-list  class-name ) )

		(mapcar (lambda (x)
				  (setq key-word (nth 1 x ))
				  (setq key-word (propertize key-word 'ac-php-help  (nth 2  x ) ))
				  (push key-word ret-list  )
				  nil
				  ) output-list )

      )
  ret-list))

(defun ac-php-candidate-other ( tags-data)
  
  (let (ret-list (ac-prefix-len (length ac-prefix)) cmp-value )
  ;;系统函数
  (dolist  (key-word ac-php-sys-function-list)
	
	(when (>= (length key-word) ac-prefix-len)
	  (setq cmp-value   (substring-no-properties  key-word 0 ac-prefix-len ) )
	  (if (string<   ac-prefix  cmp-value) (return ))
	  (if (string= cmp-value  ac-prefix ) (push key-word ret-list  ))
	  ))
  ;;用户函数

  (if tags-data 
      (let ((function-list (nth 1 tags-data )  ) key-word )

        (dolist (function-item function-list )
          (when (string-prefix-p  ac-prefix (nth 1 function-item )  )
            (setq key-word (nth  1 function-item ))
            (setq key-word (propertize key-word 'ac-php-help  (nth 2  function-item ) ))
            (push key-word ret-list  )
            )))
    )
  


  ret-list
  ))
;;; ==============BEGIN
(defun ac-php-find-php-files ( work-dir regex )
  "get all php file list"
  (let (results sub-results files file-name file-dir-flag file-change-time file-change-unixtime )
    (setq files (directory-files-and-attributes work-dir t))
    (dolist  (file-item  files )
      (setq file-name  (nth 0 file-item ) )
      (setq file-dir-flag  (nth 1 file-item ) )
      (setq file-change-time (nth 6 file-item ) )

      (if (stringp  file-dir-flag  );;link
          (setq  file-dir-flag (file-directory-p file-dir-flag )))


      (when (and (not file-dir-flag) ;;file
                 (string-match  regex file-name )
                 )
        
        (setq file-change-unixtime (+ (* (nth 0 file-change-time )  65536  ) (nth 1 file-change-time )   ) )
        (if results
            (nconc results (list (list file-name  file-change-unixtime)) )
          (setq results  (list (list file-name  file-change-unixtime) ))))

      (when ( and   file-dir-flag
                    ;;(not (string= "."   (file-name-base file-name)  ))
                    ;;(not (string= ".."   (file-name-base file-name)  ))
                    (not (string= "."  (substring (file-name-base file-name)  0 1 ))) ;; not start with "."
                    ) 
        (setq sub-results  (ac-php-find-php-files file-name regex ) )

        (if results
            (nconc results sub-results)
          (setq results sub-results))
        ))
    results 
    ))


(defun ac-php-gen-data ( tags-lines project-dir-len )
  "gen-el-data"
  (let ( class-list function-list inherit-list (file-start-pos project-dir-len ) (count 0 ) )
    (dolist (line-data tags-lines)
      (when (and
             (> (length line-data ) 0)
             (not (string= (substring line-data 0 1 ) "!" ) )
             (string-match "^\\(\\w+\\)\t\\(.*\\)\t/\\^\\(.+\\)\\$/;\"\t\\(\\w\\)\tline:\\([0-9]+\\)\\(.*\\)" line-data)
             )


         (let (
               (tag-name (match-string 1  line-data ))
               (file-pos (concat (substring  (match-string 2  line-data )  file-start-pos ) ":" (match-string 5  line-data )   ))
               (doc (match-string 3  line-data ))
               (tag-type (match-string 4  line-data ))
               other-data

               return-type
               class-name
               access

               ) 
           (cond
            ((string= tag-type "f") (push   (list  tag-type  tag-name (ac-php-gen-el-func tag-name doc)  file-pos  ) function-list  ))
            ((string= tag-type "d") (push   (list  tag-type  tag-name tag-name  file-pos  ) function-list  ))
            ((or (string= tag-type "c") (string= tag-type "i"))  ;;class or  interface
             (push   (list  tag-type  tag-name (concat tag-name  "()" ) file-pos  ) function-list  )
             (setq other-data  (match-string 6  line-data ) )
             ;; add class-inherits
             (when (string-match "^\tinherits:\\(\\w+\\)\\(,.*\\)*" other-data)
               (push  (list  tag-name   (match-string 1  other-data  )) inherit-list)))
            ((or (string= tag-type "p")  (string= tag-type "m") ) ;;class function member
             (setq other-data  (match-string 6  line-data ) )
             ;;get  return type
             (setq return-type  (if (string-match ".*::\\(\\w+\\).*" doc)
                                    (match-string 1  doc  )
                                  ""))


             (when (string-match "^\t\\(class\\|interface\\):\\(\\w+\\)\taccess:\\(.*\\)" other-data)
               (setq class-name (match-string 2  other-data  ))
               (setq access (match-string 3  other-data  ))
               )
             ;;add class info 
             (when (not (assoc class-name class-list ))
               (push (list class-name nil ) class-list))
             ;;add member & function 

             (if (string= tag-type "p")
                 (setq doc tag-name)
               (setq doc (ac-php-gen-el-func tag-name doc) ))

             (push (list tag-type tag-name doc file-pos return-type class-name   ) (cadr (assoc  class-name class-list ) ) ))

            ))))
    (list class-list function-list inherit-list )))

(defun  ac-php-gen-el-func ( func-name doc)
  "DOCSTRING"
  (let ( func-str ) 
    (if (string-match ".*(\\(.*\\)).*" doc)
        (progn
         (setq func-str (replace-regexp-in-string "," "#>,<#" (match-string 1 doc) ) )
         (setq func-str (replace-regexp-in-string "[\t ]+" "" func-str  ) )
         (concat func-name "(<#" func-str "#>)" )
          )
      (concat func-name "()")
      )))
(defun ac-php-get-tags-file ()
  ""
  (let ((tags-dir (ac-php-get-tags-dir)) )
    (if tags-dir
        (concat   tags-dir ".tags/tags-data.el"  )
      nil)))

(defun ac-php-remake-tags ()
  "DOCSTRING"
  (interactive)
  (let ((tags-dir (ac-php-get-tags-dir) ) tags-dir-len file-list  obj-tags-dir file-name obj-file-name cur-obj-list src-time   obj-item cmd  el-data)  

	(message "remake %s" tags-dir )
    (if (not ac-php-executable ) (message "no find cmd:  phpctags,  put it in /usr/bin/  and restart emacs "   ) )
    (if (not tags-dir) (message "no find .tags dir in path list :%s " (file-name-directory (buffer-file-name)  )   ) )
	(when (and tags-dir  ac-php-executable )
      (setq tags-dir-len (length tags-dir) )
      (setq obj-tags-dir (concat tags-dir ".tags/tags_dir_" (getenv "USER") "/" ))
      (if (not (file-directory-p obj-tags-dir ))
          (mkdir obj-tags-dir))
      (setq file-list (ac-php-find-php-files tags-dir "^[^#]+\\.php$" ) )
      (setq obj-tags-list (ac-php-find-php-files obj-tags-dir  "\\.tags$" ) )
      
      (dolist (file-item file-list )

        (setq  file-name (nth  0 file-item )  )
        (setq src-time  (nth 1 file-item ) )
        (setq obj-file-name   (substring file-name  tags-dir-len   ) )
        (setq obj-file-name (replace-regexp-in-string "/" "-" obj-file-name ))
        (setq obj-file-name (replace-regexp-in-string "\\.php$" ".tags" obj-file-name ))
        (setq  obj-file-name (concat obj-tags-dir  obj-file-name ))

        (push obj-file-name cur-obj-list )
        ;;check change time
        (setq obj-item (assoc obj-file-name obj-tags-list ))
        (when (or (not obj-item) (< (nth 1 obj-item) src-time ) )
          ;;gen tags file
          (message "rebuild %s" file-name )
          (let (cmd-output   )
            (setq cmd-output (shell-command-to-string (concat ac-php-executable  " -f " obj-file-name " "  file-name  )) )
            
            (when (> (length cmd-output) 3) (princ (concat "phpctags ERROR:" cmd-output )))
            )
          ;;gen el data file
          ))
	;;加入参数
      (let ((temp-list cur-obj-list) tags-lines )
        (setq cmd "cat" )
        (while temp-list  
          (setq  cmd (concat cmd  " " (car  temp-list  )  ))
          (setq temp-list (cdr  temp-list)))

        )
      ;;(message "%s" cmd)
      (setq tags-lines  (split-string (shell-command-to-string  cmd ) "\n"   ))
      (ac-php-save-data  (ac-php-get-tags-file ) (ac-php-gen-data  tags-lines tags-dir-len)  )
      ;;  TODO do cscope  
      (when ac-php-cscope
        (message "rebuild cscope  data file " )
        (setq tags-lines  (split-string (shell-command-to-string  cmd ) "\n"   ))
        (shell-command-to-string  (concat " cd " tags-dir ".tags &&  find  ../ -name \"[A-Za-z0-9_]*.php\" ! -path \"../.tags/*\"  > cscope.files &&  cscope -bkq -i cscope.files  ") ) )
      (message "build end.")
      )))

(defun ac-php-save-data (file data)
  (with-temp-file file
    (let ((standard-output (current-buffer))
          (print-circle t))  ; Allow circular data
      (prin1 data))))

(defun ac-php-load-data (file)
  (with-temp-buffer
    (insert-file-contents file)
    (read (current-buffer))))

(defun ac-php-get-tags-data ()
  (let ((tags-file   (ac-php-get-tags-file )))
    (if tags-file
        (ac-php-load-data  (ac-php-get-tags-file) )
      nil))) 

;;; ==============END

(defun ac-php-get-tags-dir  ()
  "DOCSTRING"
  (let (tags-dir tags-file) 
    (setq tags-dir (file-name-directory (buffer-file-name)  ))
    (while (not (or (file-exists-p  (concat tags-dir  ".tags" )) (string= tags-dir "/") ))
	  (setq tags-dir  ( file-name-directory (directory-file-name  tags-dir ) ) ))
	(if (string= tags-dir "/") (setq tags-dir nil )   )
	tags-dir
	))





(defun ac-php-get-class-member-info (class-list inherit-list  class-name member )
  "DOCSTRING"
  (let ((tmp-class class-name ) (check-class-list (list class-name)) (ret ) find-flag )
    (while (setq  tmp-class (nth 1 (assoc tmp-class inherit-list  )) )
      (push tmp-class check-class-list )
      )
    (setq check-class-list (nreverse check-class-list ) )
    (let (  class-member-list )
      (dolist (opt-class check-class-list)
        (setq  class-member-list  (nth 1 (assoc  opt-class class-list  ))) 
        (dolist (member-info class-member-list)
          (when (string= (nth 1 member-info ) member  )
            (setq ret  member-info)
            (setq find-flag t)
            (return)
            )
          )
        (if find-flag (return) )
        ))
    ret
    ))

(defun ac-php-get-class-member-list (class-list inherit-list  class-name  )
  "DOCSTRING"
  (let ((tmp-class class-name ) (check-class-list (list class-name)) (ret ) find-flag )
    (while (setq  tmp-class (nth 1 (assoc tmp-class inherit-list  )) )
      (push tmp-class check-class-list )
      )
    (setq check-class-list (nreverse check-class-list ) )
    (let (  class-member-list )
      (dolist (opt-class check-class-list)
        (setq  class-member-list  (nth 1 (assoc  opt-class class-list  ))) 
        (if ret 
            (nconc ret class-member-list   )
          (setq ret class-member-list  ))
        ))
    ret
    ))



(defun ac-php-get-class-name-by-key-list ( tags-data key-list-str )
  "DOCSTRING"
  (let (temp-class (cur-class "" ) (class-list (nth 0 tags-data) ) (inherit-list (nth 2 tags-data)) (key-list (split-string key-list-str "\\." ) ) )
    (dolist (item key-list )
      (if (string= cur-class "" )
          (setq cur-class item)
        (progn
          (setq temp-class cur-class)

          (if (string= item "__parent__" )
              (progn
                (setq cur-class (nth 1 (assoc cur-class inherit-list  ))  ) 
                (if (not cur-class) (setq cur-class "") ))
            (let ( member-info)
              (setq member-info (ac-php-get-class-member-info class-list inherit-list cur-class  item ))
              (setq cur-class (if  member-info
                                  (nth 4 member-info)
                                ""))

              ))

          (when (string= cur-class "")
            (message (concat " class[" temp-class "]'s member[" item "] not define type "))
            (return))

          ))
      )
    cur-class
    ))

(defun ac-php-find-symbol-at-point (&optional prefix)
  (interactive "P")
  ;;检查是类还是 符号 
  (let ( key-str-list  line-txt cur-word val-name class-name output-vec    jump-pos  cmd complete-cmd  find-flag tags-data)
	  (setq line-txt (buffer-substring-no-properties
					  (line-beginning-position)
					  (line-end-position )))
	  (setq cur-word  (current-word))
      (setq key-str-list (ac-php-get-class-at-point ))
      (setq  tags-data  (ac-php-get-tags-data )  )
	  (if  key-str-list  
		  (progn
            (if tags-data
                (progn
                  (let (class-name member-info  )  
                  ;;(setq key-str-list (replace-regexp-in-string "\\.[^.]*$" (concat "." cur-word ) key-str-list ))
                  (setq key-str-list (replace-regexp-in-string "\\.[^.]*$" "" key-str-list ))
                  (setq class-name (ac-php-get-class-name-by-key-list  tags-data key-str-list ))
                  ;;(message "class %s" class-name)
                  (if (not (string= class-name "" ) )
                      (progn 
                        (setq member-info (ac-php-get-class-member-info (nth 0 tags-data)  (nth 2 tags-data)  class-name cur-word ) )
                        (if member-info
                            (progn
                              (setq jump-pos  (concat (ac-php-get-tags-dir)  (nth 3 member-info)  ))
                              (ac-php-location-stack-push)
                              (ac-php-goto-location jump-pos ))
                          (message "no find %s.%s " class-name cur-word  )
                          ))
                    ;;(message "no find class  from key-list %s " key-str-list  )
                    )
                  ))))

		(progn ;;function
		  (if tags-data 
			  (progn
                (let ((function-list (nth 1 tags-data )  ))

                (dolist (function-item function-list )
                  (when (string=  (nth 1 function-item )  cur-word)

                    (setq jump-pos  (concat (ac-php-get-tags-dir)  (nth 3 function-item)   ))
                    (ac-php-location-stack-push)
                    (ac-php-goto-location jump-pos )
                    (setq find-flag t)
                    (return )))
                  )
                ))

          (if (not find-flag )
			(progn
			  
			  (dolist (function-str ac-php-sys-function-list )
				(when (string= function-str cur-word)

				  (php-search-documentation cur-word  )
				  (return )))

			  ))))
		))

(defun ac-php-gen-def ()
  "DOCSTRING"
  (interactive)
  (let (line-txt (cur-word  (current-word) ) )
	(setq line-txt (buffer-substring-no-properties
					(line-beginning-position)
					(line-end-position )))
	  (if  (string-match ( concat  "$" cur-word ) line-txt)
		  (kill-new (concat "\t/*$" cur-word "::`<...>` */\n") )
		(kill-new (concat "\tpublic /*::"cur-word" */ $" cur-word ";\n") )
		  )
	))
(defun ac-php-location-stack-forward ()
  (interactive)
  (ac-php-location-stack-jump -1))

(defun ac-php-location-stack-back ()
  (interactive)
  (ac-php-location-stack-jump 1))



(defun ac-php-location-stack-jump (by)
  (interactive)
  (let ((instack (nth ac-php-location-stack-index ac-php-location-stack))
        (cur (ac-php-current-location)))
    (if (not (string= instack cur))
        (ac-php-goto-location instack )
      (let ((target (+ ac-php-location-stack-index by)))
        (when (and (>= target 0) (< target (length ac-php-location-stack)))
          (setq ac-php-location-stack-index target)
          (ac-php-goto-location (nth ac-php-location-stack-index ac-php-location-stack) ))))))



(defun ac-php-candidate ()
  (let ( key-str-list  tags-data)
    (setq key-str-list (ac-php-get-class-at-point))
    (setq  tags-data  (ac-php-get-tags-data )  )
    (if key-str-list
        (ac-php-candidate-class tags-data key-str-list  )
      (ac-php-candidate-other tags-data))
    ))
(defun ac-php-show-tip	(&optional prefix)
  (interactive "P")
  ;;检查是类还是 符号 
  (let ( key-str-list  line-txt cur-word val-name class-name output-vec    class-name doc  cmd complete-cmd  find-flag)
	  (setq line-txt (buffer-substring-no-properties
					  (line-beginning-position)
					  (line-end-position )))
	  (setq cur-word  (current-word))

      (setq  tags-data  (ac-php-get-tags-data )  )
      (setq key-str-list (ac-php-get-class-at-point ))
	  (if  key-str-list  
		  (progn
            (if tags-data
                (progn
                  (let (class-name member-info  )  
                  (setq key-str-list (replace-regexp-in-string "\\.[^.]*$" "" key-str-list ))
                  (setq class-name (ac-php-get-class-name-by-key-list  tags-data key-str-list ))
                  (setq member-info (ac-php-get-class-member-info (nth 0 tags-data)    (nth 2 tags-data)  class-name cur-word ) )
                  (if member-info
                      (progn
                        (setq  doc   (nth 2 member-info) )
                        (setq  class-name   (nth 5 member-info) )
                        (popup-tip (concat "[user]:" class-name  "::"  (ac-php-clean-document doc)    ))
                        )
                    )
                  ))))


		(progn ;;function
		  (if tags-data 
			  (progn
                (let ((function-list (nth 1 tags-data ) ))

                  (dolist (function-item function-list )
                    (when (string=  (nth 1 function-item )  cur-word)
                      (setq  doc   (nth 2 function-item ) )
					  (popup-tip (concat "[user]:"  (ac-php-clean-document doc)  ))
                      (setq find-flag t)
                      (return )))
                  ))) 

		  (if (not find-flag) 
			  (let ((cur-function (php-get-pattern) ) function-info) ;;sys function
				(dolist (function-str ac-php-sys-function-list )
				  (when (string= function-str cur-function)
					(setq function-info (get-text-property 0 'ac-php-help  function-str ) )
					;;显示信息
					(popup-tip (concat "[system]:" (ac-php-clean-document function-info)))
					(return )))
				
				))))
	  ))



(defvar ac-template-start-point nil)
(defvar ac-template-candidates (list "ok" "no" "yes:)"))

(defun ac-php-action ()
  (interactive)
  ;; (ac-last-quick-help)
  (let ((help (ac-php-clean-document (get-text-property 0 'ac-php-help (cdr ac-last-completion))))
        (raw-help (get-text-property 0 'ac-php-help (cdr ac-last-completion)))
        (candidates (list)) ss fn args (ret-t "") ret-f)
    (setq ss (split-string raw-help "\n"))
    (dolist (s ss)
      (when (string-match "\\[#\\(.*\\)#\\]" s)
        (setq ret-t (match-string 1 s)))
      (setq s (replace-regexp-in-string "\\[#.*?#\\]" "" s))
      (cond ((string-match "^\\([^(]*\\)\\((.*)\\)" s)
             (setq fn (match-string 1 s)
                   args (match-string 2 s))
             (push (propertize (ac-php-clean-document args) 'ac-php-help ret-t
                               'raw-args args) candidates)
             (when (string-match "\{#" args)
               (setq args (replace-regexp-in-string "\{#.*#\}" "" args))
               (push (propertize (ac-php-clean-document args) 'ac-php-help ret-t
                                 'raw-args args) candidates))
             (when (string-match ", \\.\\.\\." args)
               (setq args (replace-regexp-in-string ", \\.\\.\\." "" args))
               (push (propertize (ac-php-clean-document args) 'ac-php-help ret-t
                                 'raw-args args) candidates)))
            ((string-match "^\\([^(]*\\)(\\*)\\((.*)\\)" ret-t) ;; check whether it is a function ptr
             (setq ret-f (match-string 1 ret-t)
                   args (match-string 2 ret-t))
             (push (propertize args 'ac-php-help ret-f 'raw-args "") candidates)
             (when (string-match ", \\.\\.\\." args)
               (setq args (replace-regexp-in-string ", \\.\\.\\." "" args))
               (push (propertize args 'ac-php-help ret-f 'raw-args "") candidates)))))
    (cond (candidates
           (setq candidates (delete-dups candidates))
           (setq candidates (nreverse candidates))
           (setq ac-template-candidates candidates)
           (setq ac-template-start-point (point))
           (ac-complete-template)

           (unless (cdr candidates) ;; unless length > 1
             (message (replace-regexp-in-string "\n" "   ;    " help))))
          (t
           (message (replace-regexp-in-string "\n" "   ;    " help))))))
(defun ac-php-prefix ()
  (or (ac-prefix-symbol)
      (let ((c (char-before)))
        (when (or
                  ;; ->
                  (and (eq ?> c) (eq ?- (char-before (1- (point)))))
                  ;; :: 
                  (and (eq ?: c) (eq ?: (char-before (1- (point))))))

          (point)))))


(ac-define-source php
  '((candidates . ac-php-candidate)
    (candidate-face . ac-php-candidate-face)
    (selection-face . ac-php-selection-face)
    (prefix . ac-php-prefix)
    (requires . 0)
    (document . ac-php-document)
    (action . ac-php-action)
    (cache)
    (symbol . "p")))

