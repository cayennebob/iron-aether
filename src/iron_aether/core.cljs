(ns ^:figwheel-always iron-aether.core
    (:require [iron-aether.battle :as battle]
              [om.core :as om :include-macros true]
              [sablono.core :refer-macros [html]]))

(defonce app-state (atom {:name nil
                          :battle nil}))

(defn start-game-view
  [app owner]
  (reify
    om/IRender
    (render [_]
      (html
        [:div
         "Enter Name: "
         [:input {:ref "name"}]
         " "
         [:button
          {:onClick #(om/update! app [:name]
                                 (.-value (om/get-node owner "name")))}
          "Battle!"]]))))

(defn app-view
  [app owner]
  (reify
    om/IRender
    (render [_]
      (if-not (:name app)
        (om/build start-game-view app)
        (om/build battle/battle-view app)))))

(om/root
  app-view
  app-state
  {:target (. js/document (getElementById "app"))})

; debugging

(enable-console-print!)
