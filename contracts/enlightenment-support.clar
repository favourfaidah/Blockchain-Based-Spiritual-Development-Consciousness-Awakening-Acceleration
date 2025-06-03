;; Enlightenment Support Contract
;; Supports consciousness enlightenment journey

(define-constant ERR_NOT_AUTHORIZED (err u500))
(define-constant ERR_JOURNEY_NOT_FOUND (err u501))
(define-constant ERR_INVALID_STAGE (err u502))

;; Enlightenment stages
(define-constant AWAKENING u1)
(define-constant PURIFICATION u2)
(define-constant ILLUMINATION u3)
(define-constant INTEGRATION u4)
(define-constant EMBODIMENT u5)

;; Journey tracking
(define-map enlightenment-journeys
  { user: principal }
  {
    current-stage: uint,
    stage-progress: uint,
    journey-started: uint,
    last-breakthrough: uint,
    support-sessions: uint,
    insights-recorded: uint,
    challenges-overcome: uint
  }
)

;; Support sessions
(define-map support-sessions
  { session-id: uint }
  {
    user: principal,
    guide-id: uint,
    session-type: (string-ascii 50),
    duration-minutes: uint,
    breakthrough-achieved: bool,
    insights: (string-ascii 1000),
    next-steps: (string-ascii 500),
    session-date: uint
  }
)

;; Breakthrough records
(define-map breakthroughs
  { breakthrough-id: uint }
  {
    user: principal,
    stage: uint,
    description: (string-ascii 1000),
    integration-period: uint,
    verified: bool,
    recorded-at: uint
  }
)

(define-data-var next-session-id uint u1)
(define-data-var next-breakthrough-id uint u1)

;; Begin enlightenment journey
(define-public (begin-journey)
  (match (map-get? enlightenment-journeys { user: tx-sender })
    existing-journey (ok false) ;; Already started
    (begin
      (map-set enlightenment-journeys
        { user: tx-sender }
        {
          current-stage: AWAKENING,
          stage-progress: u0,
          journey-started: block-height,
          last-breakthrough: u0,
          support-sessions: u0,
          insights-recorded: u0,
          challenges-overcome: u0
        }
      )
      (ok true)
    )
  )
)

;; Record support session
(define-public (record-support-session
  (guide-id uint)
  (session-type (string-ascii 50))
  (duration-minutes uint)
  (breakthrough-achieved bool)
  (insights (string-ascii 1000))
  (next-steps (string-ascii 500)))
  (let ((session-id (var-get next-session-id)))
    (map-set support-sessions
      { session-id: session-id }
      {
        user: tx-sender,
        guide-id: guide-id,
        session-type: session-type,
        duration-minutes: duration-minutes,
        breakthrough-achieved: breakthrough-achieved,
        insights: insights,
        next-steps: next-steps,
        session-date: block-height
      }
    )
    (var-set next-session-id (+ session-id u1))
    (try! (update-journey-progress breakthrough-achieved))
    (ok session-id)
  )
)

;; Record breakthrough
(define-public (record-breakthrough
  (stage uint)
  (description (string-ascii 1000))
  (integration-period uint))
  (let ((breakthrough-id (var-get next-breakthrough-id)))
    (if (and (>= stage u1) (<= stage u5))
      (begin
        (map-set breakthroughs
          { breakthrough-id: breakthrough-id }
          {
            user: tx-sender,
            stage: stage,
            description: description,
            integration-period: integration-period,
            verified: false,
            recorded-at: block-height
          }
        )
        (var-set next-breakthrough-id (+ breakthrough-id u1))
        (try! (advance-stage-if-ready stage))
        (ok breakthrough-id)
      )
      ERR_INVALID_STAGE
    )
  )
)

;; Update journey progress
(define-private (update-journey-progress (breakthrough-achieved bool))
  (match (map-get? enlightenment-journeys { user: tx-sender })
    journey-data
    (let ((new-sessions (+ (get support-sessions journey-data) u1))
          (new-last-breakthrough (if breakthrough-achieved block-height (get last-breakthrough journey-data))))
      (map-set enlightenment-journeys
        { user: tx-sender }
        (merge journey-data {
          support-sessions: new-sessions,
          last-breakthrough: new-last-breakthrough
        })
      )
      (ok true)
    )
    ERR_JOURNEY_NOT_FOUND
  )
)

;; Advance stage if ready
(define-private (advance-stage-if-ready (breakthrough-stage uint))
  (match (map-get? enlightenment-journeys { user: tx-sender })
    journey-data
    (let ((current-stage (get current-stage journey-data)))
      (if (and (is-eq breakthrough-stage current-stage) (< current-stage u5))
        (map-set enlightenment-journeys
          { user: tx-sender }
          (merge journey-data {
            current-stage: (+ current-stage u1),
            stage-progress: u0
          })
        )
        true ;; No advancement needed
      )
      (ok true)
    )
    ERR_JOURNEY_NOT_FOUND
  )
)

;; Get journey status
(define-read-only (get-journey (user principal))
  (map-get? enlightenment-journeys { user: user })
)

;; Get support session
(define-read-only (get-support-session (session-id uint))
  (map-get? support-sessions { session-id: session-id })
)

;; Get breakthrough
(define-read-only (get-breakthrough (breakthrough-id uint))
  (map-get? breakthroughs { breakthrough-id: breakthrough-id })
)
