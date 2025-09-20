
;; title: CreativeCompetition
;; version: 1.0.0
;; summary: A peer-judged platform for design contests and artistic merit evaluation
;; description: Smart contract for managing creative competitions where participants submit entries and peers judge submissions

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u401))
(define-constant ERR-CONTEST-NOT-FOUND (err u404))
(define-constant ERR-CONTEST-ENDED (err u405))
(define-constant ERR-CONTEST-ACTIVE (err u406))
(define-constant ERR-ALREADY-SUBMITTED (err u407))
(define-constant ERR-ALREADY-JUDGED (err u408))
(define-constant ERR-INSUFFICIENT-FUNDS (err u409))
(define-constant ERR-INVALID-ENTRY (err u410))
(define-constant ERR-CANNOT-JUDGE-OWN-ENTRY (err u411))

;; Data Variables
(define-data-var next-contest-id uint u1)
(define-data-var next-entry-id uint u1)

;; Data Maps
(define-map contests
  { contest-id: uint }
  {
    creator: principal,
    title: (string-ascii 100),
    description: (string-ascii 500),
    prize-pool: uint,
    entry-fee: uint,
    start-block: uint,
    end-block: uint,
    judging-end-block: uint,
    min-judges: uint,
    status: (string-ascii 20)
  }
)

(define-map entries
  { entry-id: uint }
  {
    contest-id: uint,
    creator: principal,
    title: (string-ascii 100),
    description: (string-ascii 500),
    content-hash: (string-ascii 64),
    submission-block: uint,
    total-score: uint,
    judge-count: uint
  }
)

(define-map contest-entries
  { contest-id: uint, creator: principal }
  { entry-id: uint }
)

(define-map judgments
  { entry-id: uint, judge: principal }
  { score: uint, feedback: (string-ascii 200) }
)

(define-map contest-participants
  { contest-id: uint }
  { participant-count: uint }
)

;; Public Functions

;; Create a new contest
(define-public (create-contest
  (title (string-ascii 100))
  (description (string-ascii 500))
  (prize-pool uint)
  (entry-fee uint)
  (duration-blocks uint)
  (judging-duration-blocks uint)
  (min-judges uint))
  (let
    (
      (contest-id (var-get next-contest-id))
      (start-block block-height)
      (end-block (+ block-height duration-blocks))
      (judging-end-block (+ end-block judging-duration-blocks))
    )
    (try! (stx-transfer? prize-pool tx-sender (as-contract tx-sender)))
    (map-set contests
      { contest-id: contest-id }
      {
        creator: tx-sender,
        title: title,
        description: description,
        prize-pool: prize-pool,
        entry-fee: entry-fee,
        start-block: start-block,
        end-block: end-block,
        judging-end-block: judging-end-block,
        min-judges: min-judges,
        status: "active"
      }
    )
    (map-set contest-participants { contest-id: contest-id } { participant-count: u0 })
    (var-set next-contest-id (+ contest-id u1))
    (ok contest-id)
  )
)

;; Submit an entry to a contest
(define-public (submit-entry
  (contest-id uint)
  (title (string-ascii 100))
  (description (string-ascii 500))
  (content-hash (string-ascii 64)))
  (let
    (
      (contest (unwrap! (map-get? contests { contest-id: contest-id }) ERR-CONTEST-NOT-FOUND))
      (entry-id (var-get next-entry-id))
      (existing-entry (map-get? contest-entries { contest-id: contest-id, creator: tx-sender }))
    )
    ;; Check if contest is active and within submission period
    (asserts! (is-eq (get status contest) "active") ERR-CONTEST-ENDED)
    (asserts! (<= block-height (get end-block contest)) ERR-CONTEST-ENDED)
    (asserts! (is-none existing-entry) ERR-ALREADY-SUBMITTED)

    ;; Pay entry fee
    (try! (stx-transfer? (get entry-fee contest) tx-sender (as-contract tx-sender)))

    ;; Create entry
    (map-set entries
      { entry-id: entry-id }
      {
        contest-id: contest-id,
        creator: tx-sender,
        title: title,
        description: description,
        content-hash: content-hash,
        submission-block: block-height,
        total-score: u0,
        judge-count: u0
      }
    )

    ;; Link entry to contest
    (map-set contest-entries
      { contest-id: contest-id, creator: tx-sender }
      { entry-id: entry-id }
    )

    ;; Update participant count
    (let ((participants (default-to { participant-count: u0 }
                        (map-get? contest-participants { contest-id: contest-id }))))
      (map-set contest-participants
        { contest-id: contest-id }
        { participant-count: (+ (get participant-count participants) u1) }
      )
    )

    (var-set next-entry-id (+ entry-id u1))
    (ok entry-id)
  )
)

;; Judge an entry (score 1-10)
(define-public (judge-entry
  (entry-id uint)
  (score uint)
  (feedback (string-ascii 200)))
  (let
    (
      (entry (unwrap! (map-get? entries { entry-id: entry-id }) ERR-INVALID-ENTRY))
      (contest (unwrap! (map-get? contests { contest-id: (get contest-id entry) }) ERR-CONTEST-NOT-FOUND))
      (existing-judgment (map-get? judgments { entry-id: entry-id, judge: tx-sender }))
    )
    ;; Validation checks
    (asserts! (and (>= score u1) (<= score u10)) (err u412))
    (asserts! (> block-height (get end-block contest)) ERR-CONTEST-ACTIVE)
    (asserts! (<= block-height (get judging-end-block contest)) ERR-CONTEST-ENDED)
    (asserts! (not (is-eq tx-sender (get creator entry))) ERR-CANNOT-JUDGE-OWN-ENTRY)
    (asserts! (is-none existing-judgment) ERR-ALREADY-JUDGED)

    ;; Record judgment
    (map-set judgments
      { entry-id: entry-id, judge: tx-sender }
      { score: score, feedback: feedback }
    )

    ;; Update entry scores
    (map-set entries
      { entry-id: entry-id }
      (merge entry {
        total-score: (+ (get total-score entry) score),
        judge-count: (+ (get judge-count entry) u1)
      })
    )

    (ok true)
  )
)

;; Finalize contest and distribute prizes
(define-public (finalize-contest (contest-id uint))
  (let
    (
      (contest (unwrap! (map-get? contests { contest-id: contest-id }) ERR-CONTEST-NOT-FOUND))
    )
    ;; Only contest creator can finalize
    (asserts! (is-eq tx-sender (get creator contest)) ERR-NOT-AUTHORIZED)
    ;; Contest must be past judging period
    (asserts! (> block-height (get judging-end-block contest)) ERR-CONTEST-ACTIVE)
    (asserts! (is-eq (get status contest) "active") ERR-CONTEST-ENDED)

    ;; Mark contest as finalized
    (map-set contests
      { contest-id: contest-id }
      (merge contest { status: "finalized" })
    )

    ;; TODO: Implement prize distribution logic based on scores
    (ok true)
  )
)

;; Read-only Functions

;; Get contest details
(define-read-only (get-contest (contest-id uint))
  (map-get? contests { contest-id: contest-id })
)

;; Get entry details
(define-read-only (get-entry (entry-id uint))
  (map-get? entries { entry-id: entry-id })
)

;; Get user's entry for a contest
(define-read-only (get-user-entry (contest-id uint) (user principal))
  (map-get? contest-entries { contest-id: contest-id, creator: user })
)

;; Get judgment for an entry by a judge
(define-read-only (get-judgment (entry-id uint) (judge principal))
  (map-get? judgments { entry-id: entry-id, judge: judge })
)

;; Calculate average score for an entry
(define-read-only (get-average-score (entry-id uint))
  (match (map-get? entries { entry-id: entry-id })
    entry (if (> (get judge-count entry) u0)
            (ok (/ (get total-score entry) (get judge-count entry)))
            (ok u0))
    ERR-INVALID-ENTRY
  )
)

;; Get contest participant count
(define-read-only (get-participant-count (contest-id uint))
  (default-to { participant-count: u0 }
    (map-get? contest-participants { contest-id: contest-id }))
)

;; Check if contest is in judging phase
(define-read-only (is-judging-phase (contest-id uint))
  (match (map-get? contests { contest-id: contest-id })
    contest (and
              (> block-height (get end-block contest))
              (<= block-height (get judging-end-block contest)))
    false
  )
)
