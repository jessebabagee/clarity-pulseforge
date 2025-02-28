;; PulseForge Milestones Contract

;; Error Constants
(define-constant ERR-NOT-FOUND (err u200))
(define-constant ERR-NOT-AUTHORIZED (err u201))
(define-constant ERR-INVALID-STATUS (err u202))

;; Data Variables
(define-map milestones
  { project-id: uint, milestone-id: uint }
  {
    title: (string-utf8 64),
    description: (string-utf8 256),
    deadline: uint,
    status: (string-utf8 16),
    created-by: principal,
    completed-at: (optional uint)
  }
)

;; Milestone Counter per Project
(define-map milestone-counters
  { project-id: uint }
  { counter: uint }
)

;; Valid Status Types
(define-data-var valid-statuses (list 4 (string-utf8 16)) (list "pending" "in-progress" "completed" "cancelled"))

;; Helper Functions
(define-private (is-valid-status (status (string-utf8 16)))
  (unwrap! (index-of (var-get valid-statuses) status) false)
)

;; Create Milestone
(define-public (create-milestone 
  (project-id uint)
  (title (string-utf8 64))
  (description (string-utf8 256))
  (deadline uint)
)
  (let
    ((current-counter (default-to { counter: u0 } (map-get? milestone-counters { project-id: project-id })))
     (milestone-id (+ (get counter current-counter) u1)))
    
    ;; Check project membership
    (asserts! (contract-call? .pulseforge-core get-team-member project-id tx-sender) ERR-NOT-AUTHORIZED)
    
    (map-set milestone-counters 
      { project-id: project-id }
      { counter: milestone-id }
    )
    
    (map-set milestones
      { project-id: project-id, milestone-id: milestone-id }
      {
        title: title,
        description: description,
        deadline: deadline,
        status: "pending",
        created-by: tx-sender,
        completed-at: none
      }
    )
    (ok milestone-id)
  )
)

;; Update Milestone Status
(define-public (update-milestone-status
  (project-id uint)
  (milestone-id uint)
  (new-status (string-utf8 16))
)
  (let
    ((milestone (unwrap! (get-milestone project-id milestone-id) ERR-NOT-FOUND)))
    
    ;; Validate status
    (asserts! (is-valid-status new-status) ERR-INVALID-STATUS)
    ;; Check authorization
    (asserts! (contract-call? .pulseforge-core get-team-member project-id tx-sender) ERR-NOT-AUTHORIZED)
    
    (map-set milestones
      { project-id: project-id, milestone-id: milestone-id }
      (merge milestone { 
        status: new-status,
        completed-at: (if (is-eq new-status "completed") (some block-height) (get completed-at milestone))
      })
    )
    (ok true)
  )
)

;; Get Milestone Details
(define-read-only (get-milestone (project-id uint) (milestone-id uint))
  (map-get? milestones { project-id: project-id, milestone-id: milestone-id })
)
