;; Awakening Protocol Contract
;; Manages consciousness awakening acceleration programs

(define-constant ERR_NOT_AUTHORIZED (err u200))
(define-constant ERR_PROGRAM_NOT_FOUND (err u201))
(define-constant ERR_ALREADY_ENROLLED (err u202))
(define-constant ERR_NOT_ENROLLED (err u203))

;; Awakening program structure
(define-map awakening-programs
  { program-id: uint }
  {
    guide-id: uint,
    title: (string-ascii 100),
    description: (string-ascii 500),
    duration-days: uint,
    difficulty-level: uint,
    active: bool,
    created-at: uint
  }
)

;; User enrollment tracking
(define-map user-enrollments
  { user: principal, program-id: uint }
  {
    enrolled-at: uint,
    progress-percentage: uint,
    completed: bool,
    completion-date: uint
  }
)

(define-data-var next-program-id uint u1)

;; Create awakening program
(define-public (create-program
  (guide-id uint)
  (title (string-ascii 100))
  (description (string-ascii 500))
  (duration-days uint)
  (difficulty-level uint))
  (let ((program-id (var-get next-program-id)))
    (map-set awakening-programs
      { program-id: program-id }
      {
        guide-id: guide-id,
        title: title,
        description: description,
        duration-days: duration-days,
        difficulty-level: difficulty-level,
        active: true,
        created-at: block-height
      }
    )
    (var-set next-program-id (+ program-id u1))
    (ok program-id)
  )
)

;; Enroll in awakening program
(define-public (enroll-in-program (program-id uint))
  (match (map-get? awakening-programs { program-id: program-id })
    program-data
    (if (get active program-data)
      (match (map-get? user-enrollments { user: tx-sender, program-id: program-id })
        existing-enrollment ERR_ALREADY_ENROLLED
        (begin
          (map-set user-enrollments
            { user: tx-sender, program-id: program-id }
            {
              enrolled-at: block-height,
              progress-percentage: u0,
              completed: false,
              completion-date: u0
            }
          )
          (ok true)
        )
      )
      (err u204) ;; Program not active
    )
    ERR_PROGRAM_NOT_FOUND
  )
)

;; Update progress
(define-public (update-progress (program-id uint) (progress-percentage uint))
  (match (map-get? user-enrollments { user: tx-sender, program-id: program-id })
    enrollment-data
    (begin
      (map-set user-enrollments
        { user: tx-sender, program-id: program-id }
        (merge enrollment-data {
          progress-percentage: progress-percentage,
          completed: (>= progress-percentage u100),
          completion-date: (if (>= progress-percentage u100) block-height u0)
        })
      )
      (ok true)
    )
    ERR_NOT_ENROLLED
  )
)

;; Get program details
(define-read-only (get-program (program-id uint))
  (map-get? awakening-programs { program-id: program-id })
)

;; Get user enrollment
(define-read-only (get-enrollment (user principal) (program-id uint))
  (map-get? user-enrollments { user: user, program-id: program-id })
)
