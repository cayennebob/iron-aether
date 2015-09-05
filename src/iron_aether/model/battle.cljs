(ns ^:figwheel-always iron-aether.model.battle
  (:require [iron-aether.model.dice :as dice]
            [iron-aether.model.character :as mc]))

;; state etc.

(def default-abilities
  [:basic-attack #_:defend #_:heal #_:retreat :no-action #_:fight-again])

#_(defn new-character
  [name & {:keys [friendly? max-hp attack defense abilities]}]
  {:name name
   :max-hp (or max-hp 70)
   :hp (or max-hp 70)
   :attack (or attack 10)
   :defense (or defense 10)
   :abilities (or abilities default-abilities)})

(defn new-battle
  [& {:keys [character-name] :or {character-name "Skuld"}}]
  {:player (mc/new-character character-name
                          :friendly? true
                          :max-hp 100)
   :enemy (mc/new-character "Goblin")
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
        (update-in [target :hp] #(max 0 (- % damage)))
        (update-in [:events] #(conj % message)))))


(defn do-heal-action
  [battle actor target]
  (let [roll (dice/basic-roll)
        heal-amt roll
        message (str (-> battle actor :name)
                     " heals " (-> battle target :name)
                     " for " heal-amt " health")]
    (-> battle
        (update-in [target :hp] #(min (-> battle target :max-hp) (+ % heal-amt)))
        (update-in [:events] #(conj % message)))))

(defn do-heal-self
  [battle actor]
  (do-heal-action battle actor actor))



(def abilities
  {:basic-attack {:fn do-basic-attack
                  :name "Basic Attack"
                  :is-available-fn #(= :in-progress (combat-state %))}
   :no-action {:fn do-no-action
               :name "Do Nothing"
               :is-available-fn (constantly true)}
   :heal-self {:fn do-heal-self
               :name "Heal Self"
               :is-available-fn #(constantly true)}})

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

(defn available-abilities-character
  [battle character]
  (available-abilities battle))


