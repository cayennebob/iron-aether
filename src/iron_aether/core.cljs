(ns ^:figwheel-always iron-aether.core
  (:require [iron-aether.model.app :as app]
            [iron-aether.view.app :as view-app]
            [om.core :as om :include-macros true]))

(defonce app-state (atom app/initial-state))

(if-let [target (. js/document (getElementById "app"))] ;; so tests don't error
  (om/root
    view-app/app-view
    app-state
    {:target target}))

; debugging

(enable-console-print!)
