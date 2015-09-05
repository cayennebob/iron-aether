(ns ^:figwheel-always iron-aether.core
  (:require [iron-aether.model.app :as app]
            [iron-aether.view.app :as view-app]
            [om.core :as om :include-macros true]))

(defonce app-state (atom app/initial-state))

(om/root
  view-app/app-view
  app-state
  {:target (. js/document (getElementById "app"))})

; debugging

(enable-console-print!)
