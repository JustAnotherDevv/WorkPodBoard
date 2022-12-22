
;; @title WorkBoard
;; @author Daniel047
;; @notice WorkBoard is a trully decentralized web3 freelance solution
;; @notice Lists of jobs, proposals and reviews are stored in this contract
;; @notice Detailed data related to jobs, proposals and reviews should be hosted on IPFS and linked as a hash
;; @dev This is experimental contract that was created during hackathon. This code is not production ready

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ERRORS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-constant err-job-not-found (err u100)) ;; Jobs does not exist or has different id
(define-constant err-wrong-var (err u101)) ;; Invalid variable value was given 
(define-constant err-ipfs (err u102)) ;; The given string is not a valid IPFS hash because it's too short
(define-constant err-no-proposals-for-job (err u103)) ;; Selected job has no proposals yet
(define-constant err-proposals-full (err u104)) ;; Proposal list for selected job is full(20 proposals)
(define-constant err-user (err u105)) ;; User who's not permitted to call function tried to use it
(define-constant err-review-not-found (err u106)) ;; Review does not exist or has different id

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CONSTANTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Sets owner of this contract during its creation
(define-constant admin-owner tx-sender)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; STATE VARS & MAPS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-map jobs 
  uint 
  {
    creator: principal, 
    ipfs-hash: (string-ascii 46), 
    payment-amount: uint, 
    completed: bool 
  }
)
;; @dev Currently for simplicity & spam prevention the amount of proposals for each job is limited to just 20
(define-map proposals 
  uint 
    (list 20 
      {
        employee: principal, 
        job-id: uint, 
        ipfs-hash: (string-ascii 46) 
      }
    )
)
;; @dev Currently for simplicity all of the reviews are stored together in one mapping
;; @dev In the future each review should be minted as soul-bound NFT and send to employee address
(define-map reviews 
  uint 
  {
    employee: principal, 
    employer: principal, 
    rating: uint, 
    ipfs-hash: (string-ascii 46) 
  }
)

;; Job ids and to check amount of currently available jobs
(define-data-var amount-of-jobs uint u0)
;; Reviews ids and to check amount of currently available reviews
(define-data-var amount-of-reviews uint u0)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; PRIVATE FUNCTIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; @notice Checks if tx-sender is valid creator of job
;; @param id Index of the job post to check
;; @returns Bool true if tx-sender is the owner
(define-private (is-creator (id uint)) 
  (let
    (
      (creator (unwrap! (get creator (map-get? jobs id)) err-job-not-found))
    )
  (ok (is-eq (unwrap-panic (get creator (map-get? jobs id))) tx-sender))
  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; READ-ONLY FUNCTIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; @notice Gets the amount of jobs in this smart contract
;; @returns Uint amount-of-jobs
(define-read-only (get-amount-of-jobs)
  (ok (var-get amount-of-jobs))
)

;; @notice Gets the amount of reviews  in this smart contract
;; @returns Uint amount-of-reviews
(define-read-only (get-amount-of-reviews)
  (ok (var-get amount-of-reviews))
)

;; @notice Get the job details by id
;; @param id Index of the job post to check
;; @returns Tuple {creator: principal, ipfs-hash: (string-ascii 46), payment-amount: uint, payment-currency: (string-ascii 3), is-completed: bool}
(define-read-only (get-job-by-id (id uint))
(let
    (
      (creator (unwrap! (get creator (map-get? jobs id)) err-job-not-found))
      (ipfs-hash (unwrap-panic (get ipfs-hash (map-get? jobs id))))
      (payment-amount (unwrap-panic (get payment-amount (map-get? jobs id))))
      (completed (unwrap-panic (get completed (map-get? jobs id))))
    )
     (ok {creator: creator, ipfs-hash: ipfs-hash, payment-amount: payment-amount, payment-currency: "STX", is-completed: completed})
)
)

;; @notice Get the proposal details by id
;; @param id Index of the job post to check
;; @returns List(max length 20) with tuples {employee: principal, job-id: uint, ipfs-hash: (string-ascii 46)}
(define-read-only (get-proposals-by-id (id uint))
(let
    (
      (proposalList (map-get? proposals id))
    )
    (asserts! (> (var-get amount-of-jobs) id) err-job-not-found)
    (asserts! (not (is-eq proposalList none )) err-no-proposals-for-job)
    (ok (unwrap-panic proposalList))
)
)

;; @notice Get the review details by id
;; @param id Index of the review to check
;; @returns Tuple {employee: principal, employer: principal, rating: uint, ipfs-hash: (string-ascii 46) }
(define-read-only (get-review-by-id (id uint))
(let
    (
      (employee (unwrap! (get employee (map-get? reviews id)) err-review-not-found))
      (employer (unwrap-panic (get employer (map-get? reviews id))))
      (ipfs-hash (unwrap-panic (get ipfs-hash (map-get? reviews id))))
      (rating (unwrap-panic (get rating (map-get? reviews id))))
    )
    (ok {employee: employee, employer: employer, rating: rating, ipfs-hash: ipfs-hash})
)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; PUBLIC FUNCTIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; @notice Adds new job
;; @param payment-amount Amount of STX that should be paid to the other user for completing the job
;; @param ipfs-hash Contains hash that should be used in the UI to access file with details stored in IPFS | File should contain data for job post, example data format should look like this:
;;{
;;  "Title": "",
;;  "Description": "",
;;  "Image": "",
;;  "category": "",
;;  "tags": [],
;;  "creator": "",
;;  "mail": "",
;;  "date-created": "",
;;  "date-expires": ""
;;}
;; @returns Bool true if function was executed correctly
(define-public (add-job (payment-amount uint) (ipfs-hash (string-ascii 46)))
(begin
    (asserts! (> payment-amount u0) err-wrong-var)
    ;;(asserts! (<= u46 (len ipfs-hash)) err-ipfs)
    (asserts! (is-eq (len ipfs-hash) u46 )  err-ipfs)
    (map-set jobs (var-get amount-of-jobs) {creator: tx-sender, ipfs-hash: ipfs-hash, payment-amount: payment-amount, completed: false})
    (var-set amount-of-jobs (+ (var-get amount-of-jobs) u1))
    (ok true)
)
)

;; @notice Adds new proposal
;; @param id Index of the job post this proposal should relate to
;; @param ipfs-hash Contains hash that should be used in the UI to access file with details stored in IPFS | File should contain data for proposal: its details, contact information etc
;; @returns Bool true if function was executed correctly
;; @dev Currently it's possible to create up to 20 proposal for each job
(define-public (add-proposal (id uint) (ipfs-hash (string-ascii 46)))
(begin
    (asserts! (> (var-get amount-of-jobs) id) err-job-not-found)
    (asserts! (is-eq (len ipfs-hash) u46 )  err-ipfs)
    (asserts! (not (try! (is-creator id))) err-user)
    (if (is-eq (map-get? proposals id) none)
    (map-set proposals id (list {employee: tx-sender, job-id: id, ipfs-hash: ipfs-hash}))

    (map-set proposals id  (unwrap! (as-max-len? (concat (unwrap-panic (map-get? proposals id)) (list {employee: tx-sender, job-id: id, ipfs-hash: ipfs-hash})) u20) err-proposals-full))
    )
    (ok true)
)
)

;; @notice Completes the job, sends payment to employee and creates new review for the job
;; @param id Index of the job post that should be completed
;; @param accepted-proposal-id Index of the proposal in the job post that was accepted by the employer
;; @param rating Rating for the review. Has to be between 1 - 10 or function will fail
;; @param ipfs-hash Contains hash that should be used in the UI to access file with details stored in IPFS | File should contain data for review
;; @returns Bool true if function was executed correctly
;; @dev Currently there is no escrow, the full amount is paid during job completition without ability to add milestones or negotiate the payment
(define-public (complete-job (id uint) (accepted-proposal-id uint) (rating uint) (ipfs-hash (string-ascii 46)))
(let
  (
    (payment (unwrap-panic (get payment-amount (map-get? jobs id))))
    (employee (unwrap! (get employee (element-at (unwrap-panic (map-get? proposals id)) accepted-proposal-id)) err-no-proposals-for-job))
  )
    (asserts! (> (var-get amount-of-jobs) id) err-job-not-found)
    (asserts! (and (> rating u0) (< rating u11)) err-wrong-var)
    (asserts! (try! (is-creator id)) err-user)
    (asserts! (is-eq (len ipfs-hash) u46 )  err-ipfs)
    (try! (stx-transfer? payment tx-sender employee))
    (map-set jobs id (merge (unwrap-panic (map-get? jobs id)) {completed: true}))
    (map-set reviews (var-get amount-of-reviews) {employee: employee, employer: tx-sender, rating: rating, ipfs-hash: ipfs-hash})
    (var-set amount-of-reviews (+ (var-get amount-of-reviews) u1))
    (ok true)
)
)