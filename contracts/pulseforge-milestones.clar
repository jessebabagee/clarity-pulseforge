;; PulseForge Milestones Contract

;; Data Variables
(define-map milestones
  { project-id: uint, milestone-id: uint }
  {
    title: (string-utf8 64),
    description: (string-utf8 256),
    deadline: uint,
    status: (string-utf8 16),
    created-by: principal
  }
)

;; Milestone Counter per Project
(define-map milestone-counters
  { project-id: uint }
  { counter: uint }
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
        created-by: tx-sender
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
    (map-set milestones
      { project-id: project-id, milestone-id: milestone-id }
      (merge milestone { status: new-status })
    )
    (ok true)
  )
)

;; Get Milestone Details
(define-read-only (get-milestone (project-id uint) (milestone-id uint))
  (map-get? milestones { project-id: project-id, milestone-id: milestone-id })
)
