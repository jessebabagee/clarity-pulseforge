;; PulseForge Core Contract

;; Data Variables
(define-map projects 
  { project-id: uint }
  {
    name: (string-utf8 64),
    owner: principal,
    created-at: uint,
    status: (string-utf8 16)
  }
)

(define-map team-members
  { project-id: uint, member: principal }
  { 
    role: (string-utf8 32),
    joined-at: uint
  }
)

;; Project Counter
(define-data-var project-counter uint u0)

;; Error Constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-PROJECT-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-MEMBER (err u102))

;; Create New Project
(define-public (create-project (name (string-utf8 64)))
  (let
    ((project-id (+ (var-get project-counter) u1)))
    (var-set project-counter project-id)
    (map-set projects
      { project-id: project-id }
      {
        name: name,
        owner: tx-sender,
        created-at: block-height,
        status: "active"
      }
    )
    (ok project-id)
  )
)

;; Add Team Member
(define-public (add-team-member (project-id uint) (member principal) (role (string-utf8 32)))
  (let 
    ((project (unwrap! (get-project project-id) ERR-PROJECT-NOT-FOUND)))
    (asserts! (is-eq (get owner project) tx-sender) ERR-NOT-AUTHORIZED)
    (ok (map-set team-members
      { project-id: project-id, member: member }
      { 
        role: role,
        joined-at: block-height
      }
    ))
  )
)

;; Get Project Details
(define-read-only (get-project (project-id uint))
  (map-get? projects { project-id: project-id })
)

;; Get Team Member Details
(define-read-only (get-team-member (project-id uint) (member principal))
  (map-get? team-members { project-id: project-id, member: member })
)
