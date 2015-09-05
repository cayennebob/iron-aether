(ns iron-aether.view.app
  (:require [iron-aether.view.battle :as battle]
            [om.core :as om :include-macros true]
            [sablono.core :refer-macros [html]]))

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
