(in-package :hlu)

(defun next-input (fd)
  (loop
     do (let ((ln (read-line fd nil nil)))
          (when (or (null ln)
                    (< (length ln) 2)
                    (not (string= ";;" (subseq ln 0 2))))
            (return-from next-input ln)))))

(defun skip-bom (fd)
  (when (char= (peek-char nil fd nil :eof) (code-char #xFEFF))
    (read-char fd)))

(defun read-int (fd)
  (parse-integer (next-input fd)))

(defun read-special (fd)
  (with-input-from-string (in (next-input fd))
    (read in)))

(defun read-string (fd)
  (next-input fd))

(defun eint (fd int bytes)
  (let ((ret int))
    (ntimes bytes
      (write-byte (logand #xff int) fd)
      (setf int (ash int -8)))
    reT))

(defun estring (fd str)
  (let ((bytes (str->ub str)))
    (write-sequence bytes fd)
    (eint fd 0 1))
  str)

(defun efloat32 (fd float)
  (write-byte (ieee-floats:encode-float32 float) fd)
  float)

(defun efloat64 (fd float)
  (write-byte (ieee-floats:encode-float64 float) fd)
  float)

(defun ecpfloat (fd float)
  (cond
    ((zerop float)
     (write-byte 128 fd)
     (ntimes 4
       (write-byte 0 fd))
     float)
    (t
     (let ((sign #x00000000))
       (when (minusp float)
         (setf sign #x80000000)
         (setf float (* float -1)))
       (do ((exp 0 (1+ exp)))
           ((= exp 127))
         (let ((m (round (* (1- (/ float (expt 2 exp))) 2147483648.0))))
           (when (and (or (plusp m)
                          (zerop m))
                      (<= m #x7fffffff))
             (write-byte exp fd)
             (eint fd (logior m sign) 4)
             (return-from ecpfloat float)))
         (let ((m (round (* (1- (/ float (Expt 2 (1- exp))))
                            2147483648.0))))
           (when (and (or (plusp m)
                          (zerop m))
                      (<= m #x7fffffff))
             (write-byte exp fd)
             (eint fd (logior m sign) 4)
             (return-from ecpfloat float)))))
     (error "Can't re-encode a cpfloat"))))


;;type
;;value
;;...
;;LIST_END
(defun edlist (in out)
  (do ((type (read-string in)
             (read-string in)))
      ((string= type "LIST_END"))
    (setf type (parse-integer type))
    (eint out type 1)
    (cond
      ((= type +t-end+)
       (read-string in))
      ((= type +t-int+)
       (eint out (read-int in) 4))
      ((= type +t-str+)
       (estring out (read-string in)))
      ((= type +t-coord+)
       (dolist (i (read-special in))
         (eint out i 4)))
      ((or (= type +t-uint8+)
           (= type +t-int8+))
       (eint out (read-int in) 1))
      ((or (= type +t-uint16+)
           (= type +t-int16+))
       (eint out (read-int in) 2))
      ((= type +t-color+)
       (dolist (i (read-special in))
         (eint out i 1)))
      ((= type +t-ttol+)
       (edlist in out))
      ((= type +t-nil+)
       (read-string in))
      ((= type +t-uid+)
       (eint out (read-int in) 8))
      ((= type +t-bytes+)
       (let ((sz (read-int in)))
         (if (< sz 128)
             (eint out sz 1)
             (progn
               (eint out 128 1)
               (eint out sz 4)))
         (dolist (byte (read-special in))
           (write-byte byte out))))
      ((= type +t-float32+)
       (efloat32 out (read-special in)))
      ((= type +t-float64+)
       (efloat64 out (read-special in)))
      (t (error "Unknown type in TTO list")))))