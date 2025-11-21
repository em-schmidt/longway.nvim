;; Core functionality for longway.nvim

(local M {})

(fn M.hello []
  "Simple hello function"
  (print "Hello from longway.nvim!"))

(fn M.get-info []
  "Get plugin information"
  {:name "longway.nvim"
   :version "0.1.0"
   :author "Your Name"})

M
