(ns ^:figwheel-always iron-aether.battle
  (:require [iron-aether.dice :as dice]
            [om.core :as om :include-macros true]
            [sablono.core :refer-macros [html]]))

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

;; views

(defn maybe-ability-button-view
  [{:keys [battle ability]} owner]
  (reify
    om/IRender
    (render [_]
      (when ((-> ability abilities :is-available-fn) battle)
        (html
          [:button
           {:onClick (fn []
                       (om/transact! battle
                                     #((-> ability abilities :fn) % :player :enemy))
                       (om/transact! battle enemy-turn))}
           (-> ability abilities :name)])))))

(defn menu-buttons-view
  [battle owner]
  (reify
    om/IRender
    (render [_]
      (html [:div {:style {:display "flex" :flex-direction "row"}}
             (om/build-all maybe-ability-button-view
                           (map #(array-map :battle battle :ability %)
                                (-> battle :player :abilities)))]))))

(defn combat-state-view
  [battle owner]
  (reify
    om/IRender
    (render [_]
      (html [:div
             (case (combat-state battle)
               :lost "Lost"
               :won "Won"
               :in-progress "In Progress")]))))

(defn character-view
  [character owner]
  (reify
    om/IRender
    (render [_]
      (html [:div {:style {:display "flex" :flex-direction "column"}}
             [:div "[picture of " (:name character) "]"]
             [:div (:hp character) " / " (:max-hp character)]]))))

(defn event-log-view
  [log owner]
  (reify
    om/IRender
    (render [_]
      (html [:ul
             {:style {:margin "0px 10px"}}
             (->> log
                  (take-last 12)
                  (map #(conj [:li] %)))]))))

(defn battle-view
  [app owner]
  (reify
    om/IWillMount
    (will-mount [_]
      (when-not (:battle app)
        (om/update! app [:battle] (new-battle :character-name (:name @app)))))
    om/IRender
    (render [_]
      (html [:div
             (om/build menu-buttons-view (:battle app))
             (om/build combat-state-view (:battle app))
             [:div {:style {:display "flex" :flex-direction "row"}}
              (om/build character-view (-> app :battle :player))
              (om/build event-log-view (-> app :battle :events))
              (om/build character-view (-> app :battle :enemy))]]))))
