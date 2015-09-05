(defproject iron-aether "0.1.0-SNAPSHOT"
  :description "A (currently?) (extremely) simple RPG"
  :url "https://github.com/cayennebob/iron-aether"
  :license {:name "BSD 3-clause"}

  :dependencies [[org.clojure/clojure "1.7.0"]
                 [org.clojure/clojurescript "1.7.48"]
                 [org.clojure/core.async "0.1.346.0-17112a-alpha"]
                 [sablono "0.3.6"]
                 [org.omcljs/om "0.9.0"]]

  :plugins [[lein-cljsbuild "1.0.5"]
            [lein-figwheel "0.3.7"]]

  :hooks [leiningen.cljsbuild]

  :source-paths ["src"]

  :clean-targets ^{:protect false} ["resources/public/js/compiled"
                                    "test-resources/public/js/compiled"
                                    "target"]

  :cljsbuild {:test-commands {"unit" ["phantomjs" "test-resources/public/js/compiled/iron_aether.js"]}
              :builds [{:id "dev"
                        :source-paths ["src"]
                        :figwheel true
                        :compiler {:main iron-aether.core
                                   :asset-path "js/compiled/out"
                                   :output-to "resources/public/js/compiled/iron_aether.js"
                                   :output-dir "resources/public/js/compiled/out"
                                   :source-map-timestamp true }}
                       {:id "release"
                        :source-paths ["src"]
                        :compiler {:output-to "resources/public/js/compiled/iron_aether.js"
                                   :main iron-aether.core
                                   :optimizations :advanced
                                   :pretty-print false}}
                       {:id "test"
                        :source-paths ["src" "test"]
                        :notify-command ["phantomjs" "test-resources/public/js/compiled/iron_aether.js"]
                        :compiler {:main iron-aether.run-all-tests
                                   :asset-path "js/compiled/out"
                                   :output-to "test-resources/public/js/compiled/iron_aether.js"
                                   :output-dir "test-resources/public/js/compiled/out"
                                   :source-map-timestamp true}}]}

  :figwheel {:server-port 3429})
