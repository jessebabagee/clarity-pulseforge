;; PulseForge Communications Contract

;; Data Variables
(define-map updates
  { project-id: uint, update-id: uint }
  {
    content: (string-utf8 1024),
    posted-by: principal,
    posted-at: uint,
    update-type: (string-utf8 16)
  }
)

;; Update Counter per Project
(define-map update-counters
  { project-id: uint }
  { counter: uint }
)

;; Post Update
(define-public (post-update 
  (project-id uint)
  (content (string-utf8 1024))
  (update-type (string-utf8 16))
)
  (let
    ((current-counter (default-to { counter: u0 } (map-get? update-counters { project-id: project-id })))
     (update-id (+ (get counter current-counter) u1)))
    
    (map-set update-counters
      { project-id: project-id }
      { counter: update-id }
    )
    
    (map-set updates
      { project-id: project-id, update-id: update-id }
      {
        content: content,
        posted-by: tx-sender,
        posted-at: block-height,
        update-type: update-type
      }
    )
    (ok update-id)
  )
)

;; Get Update
(define-read-only (get-update (project-id uint) (update-id uint))
  (map-get? updates { project-id: project-id, update-id: update-id })
)
