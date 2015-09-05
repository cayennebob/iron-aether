(ns ^:figwheel-always iron-aether.view.battle
  (:require [iron-aether.model.battle :as battle]
            [om.core :as om :include-macros true]
            [sablono.core :refer-macros [html]]))


;; views

(defn maybe-ability-button-view
  [{:keys [battle ability]} owner]
  (reify
    om/IRender
    (render [_]
      (when ((-> ability battle/abilities :is-available-fn) battle)
        (html
          [:button
           {:onClick (fn []
                       (om/transact! battle
                                     #((-> ability battle/abilities :fn) % :player :enemy))
                       (om/transact! battle battle/enemy-turn))}
           (-> ability battle/abilities :name)])))))

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
             (case (battle/combat-state battle)
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
        (om/update! app [:battle] (battle/new-battle :character-name (:name @app)))))
    om/IRender
    (render [_]
      (html [:div
             (om/build menu-buttons-view (:battle app))
             (om/build combat-state-view (:battle app))
             [:div {:style {:display "flex" :flex-direction "row"}}
              (om/build character-view (-> app :battle :player))
              (om/build event-log-view (-> app :battle :events))
              (om/build character-view (-> app :battle :enemy))]]))))
