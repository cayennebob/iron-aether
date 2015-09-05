(ns iron-aether.run-all-tests
  (:require [iron-aether.model.test-battle]
            [cljs.test :refer-macros [run-all-tests]]))

(enable-console-print!)
(run-all-tests #".*iron-aether.*test-.*")
(.exit js/phantom 0); TODO: non-zero exit code for failures
