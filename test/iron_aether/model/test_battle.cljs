(ns iron-aether.model.test-battle
  (:require [iron-aether.model.battle :as battle]
            [cljs.test :refer-macros [deftest is testing]]))

(deftest combat-state
  (is (= :in-progress (battle/combat-state (battle/new-battle)))))
