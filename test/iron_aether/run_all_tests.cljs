(ns iron-aether.run-all-tests
  (:require [iron-aether.model.test-battle]
            [cljs.test :as test :refer-macros [run-all-tests]]))

(def successful? (atom nil))

(defmethod test/report [:cljs.test/default :end-run-tests]
  [m]
  (reset! successful? (test/successful? m)))

(enable-console-print!)
(run-all-tests #".*iron-aether.*test-.*")

(.exit js/phantom (if @successful? 0 1))
