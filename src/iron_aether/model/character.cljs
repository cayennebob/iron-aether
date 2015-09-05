(ns ^:figwheel-always iron-aether.model.character
  )


(def all-commands
  [ :basic-attack
    #_:defend
    :heal-self
    #_:heal-any
    #_:retreat
    :no-action
    #_:fight-again
    #_:end-combat
    ])

(defn new-character
  [name & {:keys [friendly? max-hp attack defense abilities]}]
  {:name name
   :max-hp (or max-hp 70)
   :hp (or max-hp 70)
   :attack (or attack 10)
   :defense (or defense 10)
   :abilities (or abilities all-commands)})

