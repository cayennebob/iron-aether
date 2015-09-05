(ns ^:figwheel-always iron-aether.model.battle
  (:require [iron-aether.model.dice :as dice]))

;; state etc.

(def default-abilities
  [:basic-attack #_:defend #_:heal #_:retreat :no-action #_:fight-again])

(defn new-character
  [name & {:keys [friendly? max-hp attack defense abilities]}]
  {:name name
   :max-hp (or max-hp 70)
   :hp (or max-hp 70)
   :attack (or attack 10)
   :defense (or defense 10)
   :abilities (or abilities default-abilities)})

(defn new-battle
  [& {:keys [character-name] :or {character-name "Skuld"}}]
  {:player (new-character character-name
                          :friendly? true
                          :max-hp 100)
   :enemy (new-character "Goblin")
   :events ["Begin!"]})

(defn alive?
  "takes a character map and indicates whether the character is alive"
  [{:keys [hp]}]
  (> hp 0))

(defn combat-state
  "combat state of given battle state map"
  [{:keys [player enemy]}]
  (cond
    (not (alive? player)) :lost
    (not (alive? enemy)) :won
    :else :in-progress))

;; abilities

(defn do-no-action
  [battle actor _]
  (update-in battle [:events]
             #(conj % (str (-> battle actor :name) " does nothing"))))

(defn do-basic-attack
  [battle actor target]
  (let [roll (dice/basic-roll)
        damage (max 0 (+ roll
                         (-> battle actor :attack)
                         (* -1 (:defense target))
                         5))
        message (str (-> battle actor :name)
                     " attacks " (-> battle target :name)
                     " for " damage " damage")]
    (-> battle
        (update-in [target :hp] #(- % damage))
        (update-in [:events] #(conj % message)))))

(def abilities
  {:basic-attack {:fn do-basic-attack
                  :name "Basic Attack"
                  :is-available-fn #(= :in-progress (combat-state %))}
   :no-action {:fn do-no-action
               :name "Do Nothing"
               :is-available-fn (constantly true)}})

(defn enemy-turn
  [battle]
  (if (-> battle :enemy alive?)
    (do-basic-attack battle :enemy :player)
    battle))

(defn available-abilities
  "abilities currently available to the player"
  ; in the future this will take an additional argument for the character, but
  ; we don't know how multiple chararacters will be modeled/identified yet
  [battle]
  (->> battle
       :player
       :abilities
       (filter #((-> % abilities :is-available-fn) battle))))
