;;; Compiled snippets and support files for `cc-mode'
;;; Snippet definitions:
;;;
(yas-define-snippets 'cc-mode
					 '(("hd" "/**\n * ============================================================\n * @file   `(file-name-nondirectory (buffer-file-name))`\n * @author `header-user-name` (`header-user-email`)\n * @date   `(format-time-string \"%Y-%m-%d %H:%M:%S\")`\n *\n * \n * @brief  $1\n * \n * ============================================================\n */\n$0\n\n" "header" nil nil nil nil nil nil)
					   ("ih" "#include \"` (file-name-nondirectory (file-name-sans-extension (buffer-file-name)))`.hpp\"\n" "#incude <self.hpp>" nil nil nil nil nil nil)
					   ("once" "#ifndef ${1:_`(upcase (file-name-nondirectory (file-name-sans-extension (buffer-file-name))))`_H_}\n#define $1\n\n$0\n\n#endif /* $1 */" "#ifndef XXX; #define XXX; #endif" nil nil nil nil nil nil)
					   ("switch" "switch ( $1 ) {\ncase 1 : $0\n     break;\ncase 2 : \n     break;\ndefault:\n	break;\n}\n" "switch (...) { ... }" nil nil nil nil nil nil)))


;;; Do not edit! File generated at Mon Feb 10 18:36:32 2014