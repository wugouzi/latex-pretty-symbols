;;; latex-pretty-symbols.el --- Display many latex symbols as their unicode counterparts

;; Copyright (C) 2011 Erik Parmann, Pål Drange
;;
;; Author: Erik Parmann <eparmann@gmail.com>
;;         Pål Drange
;; Created: 10. July 2011
;; Version: 1.0
;; Package-Version: 20150409.240
;; Keywords: convenience, display
;; Url: https://bitbucket.org/mortiferus/latex-pretty-symbols.el
;; Derived from  pretty-lambda.el (http://www.emacswiki.org/emacs/PrettyLambda ) by Drew Adams

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 2
;; of the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; License:
;; Licensed under the same terms as Emacs.

;;; Commentary:
;; Description: This library use font-locking to change the way Emacs displays
;;   various latex commands, like \Gamma, \Phi, etc.  It does not actually
;;   change the content of the file, only the way it is displayed.
;;
;; Quick start:
;;   add this file to load path, then (require 'latex-pretty-symbols)
;;

;;; TODO: The most pressing isue is a way to let not only single symbols be
;;   displayed, but also strings.  Then we can e.g display "⟨⟨C⟩⟩" instead of
;;   atldiamond.  Currently the 5 symbols gets placed on top of each other,
;;   resulting in a mighty mess.  This problem might be demomposed into two
;;   types: When the replaced string is bigger than the string replacing it
;;   (probably the easiest case), and the converse case.
;;
;;   Package it as a elpa/marmelade package.
;;   --A problem here is that marmelade destroys the unicode encoding. A
;;   possible fix for this is to change this code, so instead of containing the
;;   unicode characters directly, it can contain the code for each of them as an
;;   integer. This would probably be more portable/safe, but in some way less
;;   userfriendly, as one can not scan through the file to see which symbols it
;;   has, and to enter one one needs to find the code
;;
;;   Also it would be nice if it had some configuration possibilities. Eg the
;;   ability to add own abreviations through the customization interface, or
;;   toggle the display of math-curly-braces.
;;
;;   On a longer timeline, it would be nice if it could understand some basic
;;   newcommands, and automatically deduce the needed unicode (but this seems
;;   super hard).

(require 'cl-lib)
;;; Code:
(defun substitute-pattern-with-unicode-symbol (pattern symbol)
  "Add a font lock hook to replace the matched part of PATTERN with the Unicode
symbol SYMBOL.
Symbol can be the symbol directly, no lookup needed."
  (interactive)
  (font-lock-add-keywords
   nil
   `((,pattern
      (0 (progn
           ;;Non-working section kind of able to compose multi-char strings:
           ;; (compose-string-to-region (match-beginning 1) (match-end 1)
           ;;   ,symbol
           ;;   'decompose-region)
           ;; (put-text-property (match-beginning 1) (match-end 1) 'display ,symbol)
           (compose-region (match-beginning 1) (match-end 1)
                           ,symbol
                           'decompose-region)
           nil))))))

;;The following code can be used to add strings, and not just single
;; characters. But not really working yet, as it does not remove the thing that
;; is below
;; (require 'cl)
;; (defun compose-string-to-region (start end string decomposingfunct)
;;   (loop for i from 0 to (- (length string) 1)
;; do (compose-region (+ i start) (+  start i 1) (substring string i (+ i 1) ) decomposingfunct)))


(defun substitute-patterns-with-unicode-symbol (patterns)
  "Mapping over PATTERNS, calling SUBSTITUTE-PATTERN-WITH-UNICODE for each of the patterns."
  (mapcar #'(lambda (x)
              (substitute-pattern-with-unicode-symbol (car x)
                                                      (cl-second x)))
          patterns))

(defun latex-escape-regex (str)
  "Gets a string, e.g. Alpha, returns the regexp matching the escaped
version of it in LaTeX code, with no chars in [a-z0-9A-Z] after it."
  (interactive "MString:")
  (concat "\\(\\\\" str "\\)[^a-z0-9A-Z]"))


(defun latex-escape-regexp-super-or-sub (str sup-or-sub backslash)
  "Gets a string, e.g. 1, a symbol 'sub or 'sup saying wether it
should be a superscript or subscript, and a boolean for
  backslash saying wether or not str should be backslashed (like
  \gamma). It returns the regexp matching the super/sub-scripted
  version of it in LaTeX code"
  ;; We can not use "(regexp-opt (list (concat "_" str) (concat "_{" str
  ;; "}")))", as it adds a "?:" after every group, which eveidently breaks the
  ;; font-locking engine in emacs. I assume the reason is like this: Normaly a
  ;; group (denoted with paranthesises) create a "backreference". This makes it
  ;; possible (I think) for the font-locking-engine no know where it actually
  ;; matched. The "?:" sais that we need to backreference. We have added one in
  ;; the innermost group, as we never need to know the location of the inner
  ;; matching, only the outermost. Adding "?:" where it can be done makes
  ;; matching more effecient, as the engine dont need to make a backreference
  (if backslash (setf str (concat "\\\\" str)))
  (cl-case sup-or-sub
    ('sub  (concat "\\(_\\(?:" str "\\|{" str "}\\)\\)"))
    ('sup  (concat "\\(\\^\\(?:" str "\\|{" str "}\\)\\)"))))

(defun latex-escape-regex-sub (str &optional backslash)
  "Gets a string, e.g. 1, returns the regexp matching the subscripted
version of it in LaTeX code."
  (interactive "MString:")
  (latex-escape-regexp-super-or-sub str 'sub backslash))

(defun latex-escape-regex-sup (str &optional backslash)
  "Gets a string, e.g. 1, returns the regexp matching the superscripted
version of it in LaTeX code."
  (interactive "MString:")
  (latex-escape-regexp-super-or-sub str 'sup backslash))

;;Goto http://www.fileformat.info/info/unicode/block/mathematical_operators/list.htm and copy the needed character
(defun latex-unicode-simplified ()
  "Adds a bunch of font-lock rules to display latex commands as
their unicode counterpart"
  (interactive)
  (substitute-patterns-with-unicode-symbol
   (list
    ;;These need to be on top, before the versions which are not subscriptet
    (list (latex-escape-regex-sub "beta" t)"ᵦ")
    (list (latex-escape-regex-sub "gamma" t)"ᵧ")
    (list (latex-escape-regex-sub "rho" t)"ᵨ")
    (list (latex-escape-regex-sub "phi" t)"ᵩ")
    (list (latex-escape-regex-sub "chi" t)"ᵪ")
    
    (list (latex-escape-regex "Alpha") "Α")
    (list (latex-escape-regex "Beta") "Β")
    (list (latex-escape-regex "Gamma")"Γ")
    (list (latex-escape-regex "Delta")"Δ")
    (list (latex-escape-regex "Epsilon")"Ε")
    (list (latex-escape-regex "Zeta")"Ζ")
    (list (latex-escape-regex "Eta")"Η")
    (list (latex-escape-regex "Theta")"Θ")
    (list (latex-escape-regex "Iota")"Ι")
    (list (latex-escape-regex "Kappa")"Κ")
    (list (latex-escape-regex "Lambda")"Λ")
    (list (latex-escape-regex "Mu")"Μ")
    (list (latex-escape-regex "Nu")"Ν")
    (list (latex-escape-regex "Xi")"Ξ")
    (list (latex-escape-regex "Omicron")"Ο")
    (list (latex-escape-regex "Pi")"Π")
    (list (latex-escape-regex "Rho")"Ρ")
    (list (latex-escape-regex "Sigma")"Σ")
    (list (latex-escape-regex "Tau")"Τ")
    (list (latex-escape-regex "Upsilon")"Υ")
    (list (latex-escape-regex "Phi")"Φ")
    (list (latex-escape-regex "Chi")"Χ")
    (list (latex-escape-regex "Psi")"Ψ")
    (list (latex-escape-regex "Omega")"Ω")
    (list (latex-escape-regex "alpha")"α")
    (list (latex-escape-regex "beta")"β")
    (list (latex-escape-regex "gamma")"γ")
    (list (latex-escape-regex "delta")"δ")
    (list (latex-escape-regex "epsilon")"ε")
    (list (latex-escape-regex "zeta")"ζ")
    (list (latex-escape-regex "eta")"η")
    (list (latex-escape-regex "theta")"θ")
    (list (latex-escape-regex "iota")"ι")
    (list (latex-escape-regex "kappa")"κ")
    (list (latex-escape-regex "lambda")"λ")
    (list (latex-escape-regex "mu")"μ")
    (list (latex-escape-regex "nu")"ν")
    (list (latex-escape-regex "xi")"ξ")
    (list (latex-escape-regex "omicron")"ο")
    (list (latex-escape-regex "pi")"π")
    (list (latex-escape-regex "rho")"ρ")
    (list (latex-escape-regex "sigma")"σ")
    (list (latex-escape-regex "tau")"τ")
    (list (latex-escape-regex "upsilon")"υ")
    (list (latex-escape-regex "phi") "ϕ")
    (list (latex-escape-regex "chi")"χ")
    (list (latex-escape-regex "psi")"ψ")
    (list (latex-escape-regex "omega")"ω")

    ;; relations
    (list (latex-escape-regex "geq")"≥")
    (list (latex-escape-regex "ge")"≥")
    (list (latex-escape-regex "leq")"≤")
    (list (latex-escape-regex "le")"≤")
    (list (latex-escape-regex "neq")"≠")
    ;;
    (list (latex-escape-regex "lhd")"⊲")
    (list (latex-escape-regex "rhd")"⊳")

    ;; logical ops
    (list (latex-escape-regex "land")"∧")
    (list (latex-escape-regex "lor")"∨")
    (list (latex-escape-regex "neg")"¬")
    (list (latex-escape-regex "rightarrow")"→")
    (list (latex-escape-regex "to")"→")
    (list (latex-escape-regex "xrightarrow")"→")
    (list (latex-escape-regex "leftarrow")"←")
    (list (latex-escape-regex "gets")"←")
    (list (latex-escape-regex "leftrightarrow")"↔")
    (list (latex-escape-regex "Rightarrow")"⇒")
    (list (latex-escape-regex "Leftarrow")"⇐")
    (list(latex-escape-regex "Leftrightarrow")"⇔")
    (list (latex-escape-regex "forall")"∀")
    (list (latex-escape-regex "exists")"∃")
    (list (latex-escape-regex "Diamond")"⋄")
    (list (latex-escape-regex "Box")"□")
    (list (latex-escape-regex "models")"⊧")
    (list (latex-escape-regex "bot")"⊥")
    (list (latex-escape-regex "top")"⊤")
    
    ;; infty before in
    (list (latex-escape-regex "infty")"∞")
    
    ;; set ops
    ;;Here I have chosen to have \} display as ⎬, to easy reading of set building opperations. Slightly uncertain
    (list "\\(\\\\}\\)" "⎬")
    (list "\\(\\\\{\\)" "⎨")
    
    (list (latex-escape-regex "mid")"|")
    (list (latex-escape-regex "in")"∊")
    (list (latex-escape-regex "not\\in")"∉")
    (list (latex-escape-regex "notin")"∉")
    (list (latex-escape-regex "cup")"∪")
    (list (latex-escape-regex "cap")"∩")
    (list (latex-escape-regex "setminus")"∖")
    (list (latex-escape-regex "minus")"∖")
    (list (latex-escape-regex "subseteq")"⊆")
    (list (latex-escape-regex "subset")"⊂")
    (list (latex-escape-regex "emptyset")"∅")
    (list (latex-escape-regex "ni")"∋")
    
    ;; generic math
    (list (latex-escape-regex "dots")"…")
    
    ;;Superscript
    (list (latex-escape-regex-sup "0")"⁰")
    (list (latex-escape-regex-sup "1")"¹")
    (list (latex-escape-regex-sup "2")"²")
    (list (latex-escape-regex-sup "3")"³")
    (list (latex-escape-regex-sup "4")"⁴")
    (list (latex-escape-regex-sup "5")"⁵")
    (list (latex-escape-regex-sup "6")"⁶")
    (list (latex-escape-regex-sup "7")"⁷")
    (list (latex-escape-regex-sup "8")"⁸")
    (list (latex-escape-regex-sup "9")"⁹")
    (list (latex-escape-regex-sup "-")"⁻")
    (list (latex-escape-regex-sup "=")"⁼")
    (list (latex-escape-regex-sup "\\+")"⁺")
    (list (latex-escape-regex-sup "a")"ᵃ")
    (list (latex-escape-regex-sup "b")"ᵇ")
    (list (latex-escape-regex-sup "c")"ᶜ")
    (list (latex-escape-regex-sup "d")"ᵈ")
    (list (latex-escape-regex-sup "e")"ᵉ")
    (list (latex-escape-regex-sup "f")"ᶠ")
    (list (latex-escape-regex-sup "g")"ᵍ")
    (list (latex-escape-regex-sup "h")"ʰ")
    (list (latex-escape-regex-sup "i")"ⁱ")
    (list (latex-escape-regex-sup "j")"ʲ")
    (list (latex-escape-regex-sup "k")"ᵏ")
    (list (latex-escape-regex-sup "l")"ˡ")
    (list (latex-escape-regex-sup "m")"ᵐ")
    (list (latex-escape-regex-sup "n")"ⁿ")
    (list (latex-escape-regex-sup "o")"ᵒ")
    (list (latex-escape-regex-sup "p")"ᵖ")
    (list (latex-escape-regex-sup "r")"ʳ")
    (list (latex-escape-regex-sup "s")"ˢ")
    (list (latex-escape-regex-sup "t")"ᵗ")
    (list (latex-escape-regex-sup "u")"ᵘ")
    (list (latex-escape-regex-sup "v")"ᵛ")
    (list (latex-escape-regex-sup "w")"ʷ")
    (list (latex-escape-regex-sup "x")"ˣ")
    (list (latex-escape-regex-sup "y")"ʸ")
    (list (latex-escape-regex-sup "z")"ᶻ")
    
    (list (latex-escape-regex-sup "A")"ᴬ")
    (list (latex-escape-regex-sup "B")"ᴮ")
    (list (latex-escape-regex-sup "D") "ᴰ")
    (list (latex-escape-regex-sup "E") "ᴱ")
    (list (latex-escape-regex-sup "G") "ᴳ")
    (list (latex-escape-regex-sup "H") "ᴴ")
    (list (latex-escape-regex-sup "I") "ᴵ")
    (list (latex-escape-regex-sup "J") "ᴶ")
    (list (latex-escape-regex-sup "K") "ᴷ")
    (list (latex-escape-regex-sup "L") "ᴸ")
    (list (latex-escape-regex-sup "M") "ᴹ")
    (list (latex-escape-regex-sup "N") "ᴺ")
    (list (latex-escape-regex-sup "O") "ᴼ")
    (list (latex-escape-regex-sup "P") "ᴾ")
    (list (latex-escape-regex-sup "R") "ᴿ")
    (list (latex-escape-regex-sup "T") "ᵀ")
    (list (latex-escape-regex-sup "U") "ᵁ")
    (list (latex-escape-regex-sup "V") "ⱽ")
    (list (latex-escape-regex-sup "W") "ᵂ")
    
    
    ;;Subscripts, unfortunately we lack important part of the subscriptet alphabet, most notably j and m
    (list (latex-escape-regex-sub "1")"₁")
    (list (latex-escape-regex-sub "2")"₂")
    (list (latex-escape-regex-sub "3")"₃")
    (list (latex-escape-regex-sub "4")"₄")
    (list (latex-escape-regex-sub "5")"₅")
    (list (latex-escape-regex-sub "6")"₆")
    (list (latex-escape-regex-sub "7")"₇")
    (list (latex-escape-regex-sub "8")"₈")
    (list (latex-escape-regex-sub "9")"₉")
    (list (latex-escape-regex-sub "x")"ₓ")
    (list (latex-escape-regex-sub "i")"ᵢ")
    (list (latex-escape-regex-sub "\\+")"₊")
    (list (latex-escape-regex-sub "-")"₋")
    (list (latex-escape-regex-sub "=")"₌")
    (list (latex-escape-regex-sub "a")"ₐ")
    (list (latex-escape-regex-sub "e")"ₑ")
    (list (latex-escape-regex-sub "o")"ₒ")
    (list (latex-escape-regex-sub "i")"ᵢ")
    (list (latex-escape-regex-sub "r")"ᵣ")
    (list (latex-escape-regex-sub "u")"ᵤ")
    (list (latex-escape-regex-sub "v")"ᵥ")
    (list (latex-escape-regex-sub "x")"ₓ")
    
    
    ;; (list (latex-escape-regex "\\.\\.\\.") 'dots)
    (list (latex-escape-regex "langle")"⟨")
    (list (latex-escape-regex "rangle")"⟩")
    (list (latex-escape-regex "mapsto")"↦")
    (list (latex-escape-regex "to")"→")
    (list (latex-escape-regex "times")"×")
    (list (latex-escape-regex "rtimes")"⋊")
    (list (latex-escape-regex "equiv")"≡")
    (list (latex-escape-regex "star")"★")
    (list (latex-escape-regex "nabla")"∇")
    (list (latex-escape-regex "qed")"□")
    (list (latex-escape-regex "lightning")"Ϟ")

    ;;New: some of my own abreviations:
    
    ;;Go to
    ;; http://www.fileformat.info/info/unicode/block/letterlike_symbols/list.htm
    ;; to find some leters, or
    ;; http://www.fileformat.info/info/unicode/block/mathematical_alphanumeric_symbols/list.htm
    ;;  My mathcal like ones are from "MATHEMATICAL BOLD SCRIPT CAPITAL", an alternative block is Letterlike symbols:
    ;;http://en.wikipedia.org/wiki/Letterlike_Symbols
    
    ;; (list (latex-escape-regex "impl") "→")
    ;; (list (latex-escape-regex "iff") "↔")
    ;; (list (latex-escape-regex "M") "𝓜")
    ;; (list (latex-escape-regex "Mo") "𝓜")
    ;; (list (latex-escape-regex "Fr") "𝓕")
    ;; (list (latex-escape-regex "gt") ">")
    ;; (list (latex-escape-regex "lt") "<")
    ;; (list (latex-escape-regex "from") ":")
    ;; (list (latex-escape-regex "Pow") "𝒫")
    ;;     ;"ℒ"
    ;; (list (latex-escape-regex "La") "𝓛")

    ;; ;;Does not work, as it pushes them all into one character
    ;; ;; (list (latex-escape-regex "atldiamond")"⟨⟨C⟩⟩")
    ;; ;Påls single letter abrevs:
    ;; (list (latex-escape-regex "L") "𝓛")
    ;; (list (latex-escape-regex "N") "𝓝")
    ;; (list (latex-escape-regex "E") "𝓔")
    ;; (list (latex-escape-regex "C") "𝓒")
    ;; (list (latex-escape-regex "D") "𝓓")


    ;;Wu's personal definition of commands
    ;;https://en.wikipedia.org/wiki/List_of_mathematical_symbols_by_subject
    ;;𝔸 𝔹 ℂ 𝔻 𝔼 𝔽 𝔾 ℍ 𝕀 𝕁 𝕂 𝕃 𝕄 ℕ 𝕆 ℙ ℚ ℝ 𝕊 𝕋 𝕌 𝕍 𝕎 𝕏 𝕐 ℤ
    (list (latex-escape-regex "A") "𝔸")
    (list (latex-escape-regex "B") "𝔹")
    (list (latex-escape-regex "C") "ℂ")
    (list (latex-escape-regex "D") "𝔻")
    (list (latex-escape-regex "E") "𝔼")
    (list (latex-escape-regex "F") "𝔽")
    (list (latex-escape-regex "G") "𝔾")
    (list (latex-escape-regex "H") "ℍ")
    (list (latex-escape-regex "I") "𝕀")
    (list (latex-escape-regex "J") "𝕁")
    (list (latex-escape-regex "K") "𝕂")
    (list (latex-escape-regex "L") "𝕃")
    (list (latex-escape-regex "M") "𝕄")
    (list (latex-escape-regex "N") "ℕ")
    (list (latex-escape-regex "O") "𝕆")
    (list (latex-escape-regex "P") "ℙ")
    (list (latex-escape-regex "Q") "ℚ")
    (list (latex-escape-regex "R") "ℝ")
    (list (latex-escape-regex "S") "𝕊")
    (list (latex-escape-regex "T") "𝕋")
    (list (latex-escape-regex "U") "𝕌")
    (list (latex-escape-regex "V") "𝕍")
    (list (latex-escape-regex "W") "𝕎")
    (list (latex-escape-regex "X") "𝕏")
    (list (latex-escape-regex "Y") "𝕐")
    (list (latex-escape-regex "Z") "ℤ")

    ;;𝔄 𝔅 ℭ 𝔇 𝔈 𝔉 𝔊 ℌ ℑ 𝔍 𝔎 𝔏 𝔐 𝔑 𝔒 𝔓 𝔔 ℜ 𝔖 𝔗 𝔘 𝔙 𝔚 𝔛 𝔜 ℨ
    (list (latex-escape-regex "fA") "𝔄")
    (list (latex-escape-regex "fB") "𝔅")
    (list (latex-escape-regex "fC") "ℭ")
    (list (latex-escape-regex "fD") "𝔇")
    (list (latex-escape-regex "fE") "𝔈")
    (list (latex-escape-regex "fF") "𝔉")
    (list (latex-escape-regex "fG") "𝔊")
    (list (latex-escape-regex "fH") "ℌ")
    (list (latex-escape-regex "fI") "ℑ")
    (list (latex-escape-regex "fJ") "𝔍")
    (list (latex-escape-regex "fK") "𝔎")
    (list (latex-escape-regex "fL") "𝔏")
    (list (latex-escape-regex "fM") "𝔐")
    (list (latex-escape-regex "fN") "𝔑")
    (list (latex-escape-regex "fO") "𝔒")
    (list (latex-escape-regex "fP") "𝔓")
    (list (latex-escape-regex "fQ") "𝔔")
    (list (latex-escape-regex "fR") "ℜ")
    (list (latex-escape-regex "fS") "𝔖")
    (list (latex-escape-regex "fT") "𝔗")
    (list (latex-escape-regex "fU") "𝔘")
    (list (latex-escape-regex "fV") "𝔙")
    (list (latex-escape-regex "fW") "𝔚")
    (list (latex-escape-regex "fX") "𝔛")
    (list (latex-escape-regex "fY") "𝔜")
    (list (latex-escape-regex "fZ") "ℨ")

    (list (latex-escape-regex "fa") "𝔞")
    (list (latex-escape-regex "fb") "𝔟")
    (list (latex-escape-regex "fc") "𝔠")
    (list (latex-escape-regex "fd") "𝔡")
    (list (latex-escape-regex "fe") "𝔢")
    (list (latex-escape-regex "ff") "𝔣")
    (list (latex-escape-regex "fg") "𝔤")
    (list (latex-escape-regex "fh") "𝔥")
    (list (latex-escape-regex "fi") "𝔦")
    (list (latex-escape-regex "fj") "𝔧")
    (list (latex-escape-regex "fk") "𝔨")
    (list (latex-escape-regex "fl") "𝔩")
    (list (latex-escape-regex "fm") "𝔪")
    (list (latex-escape-regex "fn") "𝔫")
    (list (latex-escape-regex "fo") "𝔬")
    (list (latex-escape-regex "fp") "𝔭")
    (list (latex-escape-regex "fq") "𝔮")
    (list (latex-escape-regex "fr") "𝔯")
    (list (latex-escape-regex "fs") "𝔰")
    (list (latex-escape-regex "ft") "𝔱")
    (list (latex-escape-regex "fu") "𝔲")
    (list (latex-escape-regex "fv") "𝔳")
    (list (latex-escape-regex "fw") "𝔴")
    (list (latex-escape-regex "fx") "𝔵")
    (list (latex-escape-regex "fy") "𝔶")
    (list (latex-escape-regex "fz") "𝔷")

    ;;𝒜 ℬ 𝒞 𝒟 ℰ ℱ 𝒢 ℋ ℐ 𝒥 𝒦 ℒ ℳ 𝒩 𝒪 𝒫 𝒬 ℛ 𝒮 𝒯 𝒰 𝒱 𝒲 𝒳 𝒴 𝒵
    ;;𝓐 𝓑 𝓒 𝓓 𝓔 𝓕 𝓖 𝓗 𝓘 𝓙 𝓚 𝓛 𝓜 𝓝 𝓞 𝓟 𝓠 𝓡 𝓢 𝓣 𝓤 𝓥 𝓦 𝓧 𝓨 𝓩
    ;;MATHEMATICAL BOLD SCRIPT CAPITAL
    (list (latex-escape-regex "cala") "𝓐")
    (list (latex-escape-regex "calb") "𝓑")
    (list (latex-escape-regex "calc") "𝓒")
    (list (latex-escape-regex "cald") "𝓓")
    (list (latex-escape-regex "cale") "𝓔")
    (list (latex-escape-regex "calf") "𝓕")
    (list (latex-escape-regex "calg") "𝓖")
    (list (latex-escape-regex "calh") "𝓗")
    (list (latex-escape-regex "cali") "𝓘")
    (list (latex-escape-regex "calj") "𝓙")
    (list (latex-escape-regex "calk") "𝓚")
    (list (latex-escape-regex "call") "𝓛")
    (list (latex-escape-regex "calm") "𝓜")
    (list (latex-escape-regex "caln") "𝓝")
    (list (latex-escape-regex "calo") "𝓞")
    (list (latex-escape-regex "calp") "𝓟")
    (list (latex-escape-regex "calq") "𝓠")
    (list (latex-escape-regex "calr") "𝓡")
    (list (latex-escape-regex "cals") "𝓢")
    (list (latex-escape-regex "calt") "𝓣")
    (list (latex-escape-regex "calu") "𝓤")
    (list (latex-escape-regex "calv") "𝓥")
    (list (latex-escape-regex "calw") "𝓦")
    (list (latex-escape-regex "calx") "𝓧")
    (list (latex-escape-regex "caly") "𝓨")
    (list (latex-escape-regex "calz") "𝓩")


    (list (latex-escape-regex "bA") "𝐀")
    (list (latex-escape-regex "bB") "𝐁")
    (list (latex-escape-regex "bC") "𝐂")
    (list (latex-escape-regex "bD") "𝐃")
    (list (latex-escape-regex "bE") "𝐄")
    (list (latex-escape-regex "bF") "𝐅")
    (list (latex-escape-regex "bG") "𝐆")
    (list (latex-escape-regex "bH") "𝐇")
    (list (latex-escape-regex "bI") "𝐈")
    (list (latex-escape-regex "bJ") "𝐉")
    (list (latex-escape-regex "bK") "𝐊")
    (list (latex-escape-regex "bL") "𝐋")
    (list (latex-escape-regex "bM") "𝐌")
    (list (latex-escape-regex "bN") "𝐍")
    (list (latex-escape-regex "bO") "𝐎")
    (list (latex-escape-regex "bP") "𝐏")
    (list (latex-escape-regex "bQ") "𝐐")
    (list (latex-escape-regex "bR") "𝐑")
    (list (latex-escape-regex "bS") "𝐒")
    (list (latex-escape-regex "bT") "𝐓")
    (list (latex-escape-regex "bU") "𝐔")
    (list (latex-escape-regex "bV") "𝐕")
    (list (latex-escape-regex "bW") "𝐖")
    (list (latex-escape-regex "bX") "𝐗")
    (list (latex-escape-regex "bX") "𝐘")
    (list (latex-escape-regex "bZ") "𝐙")


    (list (latex-escape-regex "ba") "𝐚")
    (list (latex-escape-regex "bb") "𝐛")
    (list (latex-escape-regex "bc") "𝐜")
    (list (latex-escape-regex "bd") "𝐝")
    (list (latex-escape-regex "be") "𝐞")
    (list (latex-escape-regex "bf") "𝐟")
    (list (latex-escape-regex "bg") "𝐠")
    (list (latex-escape-regex "bh") "𝐡")
    (list (latex-escape-regex "bi") "𝐢")
    (list (latex-escape-regex "bj") "𝐣")
    (list (latex-escape-regex "bk") "𝐤")
    (list (latex-escape-regex "bl") "𝐥")
    (list (latex-escape-regex "bm") "𝐦")
    (list (latex-escape-regex "bn") "𝐧")
    (list (latex-escape-regex "bo") "𝐨")
    (list (latex-escape-regex "bp") "𝐩")
    (list (latex-escape-regex "bq") "𝐪")
    (list (latex-escape-regex "br") "𝐫")
    (list (latex-escape-regex "bs") "𝐬")
    (list (latex-escape-regex "bt") "𝐭")
    (list (latex-escape-regex "bu") "𝐮")
    (list (latex-escape-regex "bv") "𝐯")
    (list (latex-escape-regex "bw") "𝐰")
    (list (latex-escape-regex "bx") "𝐱")
    (list (latex-escape-regex "by") "𝐲")
    (list (latex-escape-regex "bz") "𝐳")



    ;; (list (latex-escape-regex "G") "𝓖")
    ;; (list (latex-escape-regex "X") "𝓧")
    ;; (list (latex-escape-regex "U") "𝓤")
    ;; (list (latex-escape-regex "Q") "𝓠")
    
    
    ;;The following are not really working perfect
    ;; (list (latex-escape-regex "overline{R}") "R̄")
    ;; (list (latex-escape-regex "overline{X}") "X̄")
    ;; (list (latex-escape-regex "overline{G}") "Ḡ")
    
    
    
    ;;The following is some ugly fucks, as it has to match brackets! This makes
    ;;$\pair[A,B]$ into $⟨A,B⟩$, but can not handle nesting of the pair command,
    ;;then it does not convert the last "]" as it should. One can make one
    ;;regexp matching level of stacking, but my mind blows after even 1
    ;;level. Regular expressions can not do general, arbitrary depth,
    ;;paranthesis matching, but maybe emacs's "regexps" are expressiable enough for
    ;;this?
    ;;good listing
    ;;https://www.w3.org/2001/06/utf-8-test/TeX.html
    (list  "\\(\\\\pair\\[\\)" "⟨")
    (list  "\\(?:\\\\pair\\[[^\]]*\\(]\\)\\)" "⟩")
    
    (list (latex-escape-regex "dagger") "†" )
    (list (latex-escape-regex "vDash") "⊨" )
    (list (latex-escape-regex "wedge") "∧" )
    (list (latex-escape-regex "bigwedge") "⋀" )
    (list (latex-escape-regex "vee") "∨" )
    (list (latex-escape-regex "bigvee") "⋁" )
    ;;(list (latex-escape-regex "bigvee") "⋁" )
    ;;(list (latex-escape-regex "bigwedge") "⋀" )
    (list (latex-escape-regex "biguplus") "⨄" )
    (list (latex-escape-regex "bigcap") "⋂" )
    (list (latex-escape-regex "bigcup") "⋃" )
    (list (latex-escape-regex "ss") "ß")
    (list (latex-escape-regex "ae") "æ")
    (list (latex-escape-regex "oe") "œ")
    (list (latex-escape-regex "o") "ø")
    (list (latex-escape-regex "AE") "Æ")
    (list (latex-escape-regex "OE") "Œ")
    (list (latex-escape-regex "O") "Ø")
    (list (latex-escape-regex "aa") "å")
    (list (latex-escape-regex "AA") "Å")
    (list (latex-escape-regex "dag") "†")
    (list (latex-escape-regex "ddag") "‡")
    (list (latex-escape-regex "S") "§")
    (list (latex-escape-regex "l") "ł")
    (list (latex-escape-regex "L") "Ł")
    (list (latex-escape-regex "copyright") "©")
    (list (latex-escape-regex "epsilon") "ϵ")
    (list (latex-escape-regex "varphi") "φ")
    (list (latex-escape-regex "vartheta") "ϑ")
    (list (latex-escape-regex "varpi") "ϖ")
    (list (latex-escape-regex "varrho") "ϱ")
    (list (latex-escape-regex "varsigma") "ς")
    (list (latex-escape-regex "aleph") "ℵ")
    (list (latex-escape-regex "beth") "ℶ")
    (list (latex-escape-regex "hbar") "ℏ")
    (list (latex-escape-regex "ell") "ℓ")
    (list (latex-escape-regex "wp") "℘")
    (list (latex-escape-regex "Re") "ℜ")
    (list (latex-escape-regex "Im") "ℑ")
    (list (latex-escape-regex "partial") "∂")
    (list (latex-escape-regex "surd") "√")
    (list (latex-escape-regex "angle") "∠")
    (list (latex-escape-regex "triangle") "△")
    (list (latex-escape-regex "flat") "♭")
    (list (latex-escape-regex "natural") "♮")
    (list (latex-escape-regex "sharp") "♯")
    (list (latex-escape-regex "clubsuit") "♣")
    (list (latex-escape-regex "diamondsuit") "♢")
    (list (latex-escape-regex "heartsuit") "♡")
    (list (latex-escape-regex "spadesuit") "♠")
    (list (latex-escape-regex "coprod") "∐")
    (list (latex-escape-regex "int") "∫")
    (list (latex-escape-regex "prod") "∏")
    (list (latex-escape-regex "sum") "∑")
    (list (latex-escape-regex "bigotimes") "⨂")
    (list (latex-escape-regex "bigoplus") "⨁")
    (list (latex-escape-regex "bigodot") "⨀")
    (list (latex-escape-regex "oint") "∮")
    (list (latex-escape-regex "bigsqcup") "⨆")
    (list (latex-escape-regex "triangleleft") "◁")
    (list (latex-escape-regex "triangleright") "▷")
    (list (latex-escape-regex "bigtriangleup") "△")
    (list (latex-escape-regex "bigtriangledown") "▽")
    (list (latex-escape-regex "sqcap") "⊓")
    (list (latex-escape-regex "sqcup") "⊔")
    (list (latex-escape-regex "uplus") "⊎")
    (list (latex-escape-regex "amalg") "⨿")
    (list (latex-escape-regex "bullet") "∙")
    (list (latex-escape-regex "wr") "≀")
    (list (latex-escape-regex "div") "÷")
    (list (latex-escape-regex "odot") "⊙")
    (list (latex-escape-regex "oslash") "⊘")
    (list (latex-escape-regex "otimes") "⊗")
    (list (latex-escape-regex "ominus") "⊖")
    (list (latex-escape-regex "oplus") "⊕")
    (list (latex-escape-regex "mp") "∓")
    (list (latex-escape-regex "pm") "±")
    (list (latex-escape-regex "circ") "∘")
    (list (latex-escape-regex "circ") "○")
    (list (latex-escape-regex "bigcirc") "◯")
    (list (latex-escape-regex "cdot") "⋅")
    (list (latex-escape-regex "State") "⋅")
    (list (latex-escape-regex "ast") "∗")
    (list (latex-escape-regex "star") "⋆")
    (list (latex-escape-regex "propto") "∝")
    (list (latex-escape-regex "sqsubseteq") "⊑")
    (list (latex-escape-regex "sqsupseteq") "⊒")
    (list (latex-escape-regex "parallel") "∥")
    (list (latex-escape-regex "dashv") "⊣")
    (list (latex-escape-regex "vdash") "⊢")
    (list (latex-escape-regex "nearrow") "↗")
    (list (latex-escape-regex "searrow") "↘")
    (list (latex-escape-regex "nwarrow") "↖")
    (list (latex-escape-regex "swarrow") "↙")
    (list (latex-escape-regex "succ") "≻")
    (list (latex-escape-regex "prec") "≺")
    (list (latex-escape-regex "approx") "≈")
    (list (latex-escape-regex "succeq") "≽")
    (list (latex-escape-regex "preceq") "≼")
    (list (latex-escape-regex "supset") "⊃")
    (list (latex-escape-regex "supseteq") "⊇")
    (list (latex-escape-regex "in") "∈")
    (list (latex-escape-regex "gg") "≫")
    (list (latex-escape-regex "ll") "≪")
    (list (latex-escape-regex "sim") "∼")
    (list (latex-escape-regex "simeq") "≃")
    (list (latex-escape-regex "asymp") "≍")
    (list (latex-escape-regex "smile") "⌣")
    (list (latex-escape-regex "frown") "⌢")
    (list (latex-escape-regex "leftharpoonup") "↼")
    (list (latex-escape-regex "leftharpoondown") "↽")
    (list (latex-escape-regex "rightharpoonup") "⇀")
    (list (latex-escape-regex "rightharpoondown") "⇁")
    (list (latex-escape-regex "hookrightarrow") "↪")
    (list (latex-escape-regex "hookleftarrow") "↩")
    (list (latex-escape-regex "bowtie") "⋈")
    (list (latex-escape-regex "models") "⊧")
    (list (latex-escape-regex "Longrightarrow") "⟹")
    (list (latex-escape-regex "longrightarrow") "⟶")
    (list (latex-escape-regex "longleftarrow") "⟵")
    (list (latex-escape-regex "Longleftarrow") "⟸")
    (list (latex-escape-regex "longmapsto") "⟼")
    (list (latex-escape-regex "longleftrightarrow") "⟷")
    (list (latex-escape-regex "Longleftrightarrow") "⟺")
    (list (latex-escape-regex "rightrightarrows") "⇉")
    (list (latex-escape-regex "leftleftarrows") "⇇")
    (list (latex-escape-regex "upuparrows") "⇈")
    (list (latex-escape-regex "leftrightarrows") "⇆")
    (list (latex-escape-regex "rightleftarrows") "⇄")
    (list (latex-escape-regex "rightsquigarrow") "⇝")
    (list (latex-escape-regex "leftsquigarrow") "⇜")
    (list (latex-escape-regex "twoheadleftarrow") "↞")
    (list (latex-escape-regex "twoheadrightarrow") "↠")
    (list (latex-escape-regex "cdots") "⋯")
    (list (latex-escape-regex "vdots") "⋮")
    (list (latex-escape-regex "ddots") "⋱")
    (list (latex-escape-regex "Vert") "∥")
    (list (latex-escape-regex "uparrow") "↑")
    (list (latex-escape-regex "downarrow") "↓")
    (list (latex-escape-regex "updownarrow") "↕")
    (list (latex-escape-regex "Uparrow") "⇑")
    (list (latex-escape-regex "Downarrow") "⇓")
    (list (latex-escape-regex "Updownarrow") "⇕")
    (list (latex-escape-regex "rceil") "⌉")
    (list (latex-escape-regex "lceil") "⌈")
    (list (latex-escape-regex "rfloor") "⌋")
    (list (latex-escape-regex "lfloor") "⌊")
    (list (latex-escape-regex "cong") "≅")
    (list (latex-escape-regex "rightleftharpoons") "⇌")
    (list (latex-escape-regex "doteq") "≐")

    (list (latex-escape-regex "quad") "␣")

    (list (latex-escape-regex "sqsubset") "⊏")
    (list (latex-escape-regex "sqsupset") "⊐")

    (list (latex-escape-regex "la") "⟨")
    (list (latex-escape-regex "ra") "⟩")
    (list (latex-escape-regex "backslash") "\\")

    )))

;;AUCTeX
(add-hook 'LaTeX-mode-hook 'latex-unicode-simplified)

;;latex-mode
(add-hook 'latex-mode-hook 'latex-unicode-simplified)
(provide 'latex-pretty-symbols)

;;; latex-pretty-symbols.el ends here
