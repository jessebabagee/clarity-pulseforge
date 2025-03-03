;; PulseForge Communications Contract

;; Constants
(define-constant MAX_CONTENT_LENGTH u1024)
(define-constant MAX_TYPE_LENGTH u16)

;; Error Constants
(define-constant ERR-UPDATE-NOT-FOUND (err u300))
(define-constant ERR-NOT-AUTHORIZED (err u301))
(define-constant ERR-INVALID-CONTENT (err u302))

;; Data Variables
(define-map updates
  { project-id: uint, update-id: uint }
  {
    content: (string-utf8 1024),
    posted-by: principal,
    posted-at: uint,
    update-type: (string-utf8 16),
    edited: bool
  }
)

;; Update Counter per Project
(define-map update-counters
  { project-id: uint }
  { counter: uint }
)

;; Events
(define-public (print-update-posted (project-id uint) (update-id uint))
  (print { event: "update-posted", project-id: project-id, update-id: update-id, author: tx-sender })
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
    
    ;; Validate content
    (asserts! (> (len content) u0) ERR-INVALID-CONTENT)
    (asserts! (is-some (contract-call? .pulseforge-core get-team-member project-id tx-sender)) ERR-NOT-AUTHORIZED)
    
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
        update-type: update-type,
        edited: false
      }
    )
    
    (try! (print-update-posted project-id update-id))
    (ok update-id)
  )
)

;; Edit Update
(define-public (edit-update 
  (project-id uint)
  (update-id uint)
  (new-content (string-utf8 1024))
)
  (let
    ((update (unwrap! (get-update project-id update-id) ERR-UPDATE-NOT-FOUND)))
    
    (asserts! (is-eq (get posted-by update) tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (> (len new-content) u0) ERR-INVALID-CONTENT)
    
    (map-set updates
      { project-id: project-id, update-id: update-id }
      (merge update {
        content: new-content,
        edited: true
      })
    )
    
    (print { event: "update-edited", project-id: project-id, update-id: update-id })
    (ok true)
  )
)

;; Get Update
(define-read-only (get-update (project-id uint) (update-id uint))
  (map-get? updates { project-id: project-id, update-id: update-id })
)
