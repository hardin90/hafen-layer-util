;;; -*- Lisp -*- mode
(defsystem :salem-layer-util
    :name "salem-layer-util"
    :author "Corey Furmanski"
    :license "MIT"
    :description "A resource utility for Salem"
    :depends-on (:babel)
    :components ((:file "packages")
                 (:file "const"
                        :depends-on ("packages"))
                 (:file "util" 
                        :depends-on ("const"))
                 (:file "layers"
                        :depends-on ("util"))
                 (:file "resource" 
                        :depends-on ("layers"))
                 (:file "salem-layer-util" 
                        :depends-on ("resource"))))
