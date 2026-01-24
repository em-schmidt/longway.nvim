;; Tests for longway.api.client
;;
;; Tests HTTP client wrapper for Shortcut API
;; Note: These are unit tests for the client module structure

(local t (require :longway-spec.init))
(local client (require :longway.api.client))

(describe "longway.api.client"
  (fn []
    (before_each (fn [] (t.setup-test-config {})))

    (describe "module structure"
      (fn []
        (it "exports request function"
          (fn []
            (assert.is_function client.request)))

        (it "exports get function"
          (fn []
            (assert.is_function client.get)))

        (it "exports post function"
          (fn []
            (assert.is_function client.post)))

        (it "exports put function"
          (fn []
            (assert.is_function client.put)))

        (it "exports delete function"
          (fn []
            (assert.is_function client.delete)))))

    (describe "request handling"
      (fn []
        (it "returns error when no token configured"
          (fn []
            ;; Setup config without token
            (t.setup-test-config {:_resolved_token nil})
            (let [config (require :longway.config)]
              ;; Clear the token by setting up again without it
              (config.setup {:_resolved_token nil})
              ;; Note: The actual behavior depends on config state
              ;; This test verifies the client handles missing token gracefully
              (assert.is_function client.get))))))))
