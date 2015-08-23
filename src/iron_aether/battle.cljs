(ns ^:figwheel-always iron-aether.battle
  (:require [om.core :as om :include-macros true]
            [sablono.core :refer-macros [html]]))

(def something "something?")

(defn battle-view
  [app owner]
  (reify
    om/IRender
    (render [_]
      (html [:div "battle view goes here"]))))
