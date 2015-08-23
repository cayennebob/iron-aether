(ns iron-aether.dice)

(defn basic-roll
  "Roll two D10s and sum the result"
  []
  (+ 2 ;; because the rands are 0-indexed
     (rand-int 10)
     (rand-int 10)))
