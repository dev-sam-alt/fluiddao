;; FluidDAO Protocol - Liquid Democracy Governance System
;; A comprehensive liquid democracy system with quadratic voting, delegation chains, and specialized councils

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-PROPOSAL (err u101))
(define-constant ERR-INSUFFICIENT-TOKENS (err u102))
(define-constant ERR-DELEGATION-CYCLE (err u103))
(define-constant ERR-PROPOSAL-EXPIRED (err u104))
(define-constant ERR-ALREADY-VOTED (err u105))
(define-constant ERR-INVALID-COUNCIL (err u106))
(define-constant ERR-INSUFFICIENT-REPUTATION (err u107))
(define-constant ERR-DELEGATION-DEPTH-EXCEEDED (err u108))
(define-constant ERR-INVALID-INPUT (err u109))

;; System Configuration
(define-constant MIN-PROPOSAL-THRESHOLD u1000)
(define-constant MAX-DELEGATION-DEPTH u5)
(define-constant QUADRATIC-SCALING-FACTOR u2)
(define-constant COUNCIL-TERM-LENGTH u90) ;; days in blocks (assuming ~144 blocks/day)
(define-constant BASE-QUORUM-PERCENTAGE u15)
(define-constant VOICE-CREDITS-PER-CYCLE u100)
(define-constant EMERGENCY-VOTING-WINDOW u144) ;; ~24 hours in blocks
(define-constant MIN-VOTING-DURATION u144) ;; minimum 1 day
(define-constant MAX-VOTING-DURATION u20160) ;; maximum 2 weeks
(define-constant MAX-COUNCIL-MEMBERS u20)
(define-constant MAX-BET-AMOUNT u1000000) ;; 1M STX max bet

;; Data Maps

;; Delegation Registry: Maps delegator to delegatee by topic
(define-map delegation-registry 
  { delegator: principal, topic: (string-ascii 64) }
  { delegatee: principal, timestamp: uint })

;; Delegation Chains: Cached resolved chains to prevent cycles
(define-map delegation-chains
  { voter: principal, topic: (string-ascii 64) }
  { final-delegate: principal, chain-length: uint })

;; Proposals Storage
(define-map proposals
  { proposal-id: uint }
  {
    creator: principal,
    title: (string-utf8 256),
    description: (string-utf8 2048),
    topic: (string-ascii 64),
    stage: (string-ascii 32), ;; "draft", "review", "voting", "executed", "rejected"
    creation-block: uint,
    voting-deadline: uint,
    quorum-required: uint,
    for-votes: uint,
    against-votes: uint,
    quadratic-for: uint,
    quadratic-against: uint,
    executed: bool
  })

;; Vote Records: Track who voted on what
(define-map vote-records
  { proposal-id: uint, voter: principal }
  { 
    vote-weight: uint,
    voice-credits-used: uint,
    vote-type: (string-ascii 16), ;; "for", "against", "abstain"
    timestamp: uint
  })

;; Voice Credits: Quadratic voting budget per user per cycle
(define-map voice-credits
  { user: principal, cycle: uint }
  { 
    total-credits: uint,
    used-credits: uint,
    last-allocation: uint
  })

;; Governance Councils
(define-map councils
  { council-id: (string-ascii 64) }
  {
    name: (string-utf8 128),
    description: (string-utf8 512),
    members: (list 20 principal),
    term-start: uint,
    term-end: uint,
    min-reputation: uint,
    veto-power: bool
  })

;; Council Memberships
(define-map council-members
  { council-id: (string-ascii 64), member: principal }
  {
    reputation-score: uint,
    join-block: uint,
    performance-rating: uint,
    active: bool
  })

;; User Reputation and Participation
(define-map user-profiles
  { user: principal }
  {
    governance-reputation: uint,
    total-proposals-created: uint,
    total-votes-cast: uint,
    delegation-trust-score: uint,
    last-activity: uint
  })

;; Prediction Markets for Proposals
(define-map prediction-markets
  { proposal-id: uint }
  {
    total-staked-for: uint,
    total-staked-against: uint,
    resolved: bool,
    actual-outcome: (optional bool)
  })

;; Individual Prediction Bets
(define-map prediction-bets
  { proposal-id: uint, bettor: principal }
  {
    amount-staked: uint,
    predicted-outcome: bool, ;; true = proposal passes
    timestamp: uint,
    claimed: bool
  })

;; System State Variables
(define-data-var proposal-counter uint u0)
(define-data-var governance-cycle uint u1)
(define-data-var system-paused bool false)
(define-data-var total-governance-tokens uint u0)

;; Input Validation Functions

;; Validate string is not empty and within bounds
(define-private (is-valid-string-utf8 (input (string-utf8 256)))
  (and (> (len input) u0) (<= (len input) u256)))

;; Validate description is not empty and within bounds
(define-private (is-valid-description (input (string-utf8 2048)))
  (and (> (len input) u0) (<= (len input) u2048)))

;; Validate ASCII string is not empty and within bounds
(define-private (is-valid-string-ascii (input (string-ascii 64)))
  (and (> (len input) u0) (<= (len input) u64)))

;; Validate council name
(define-private (is-valid-council-name (input (string-utf8 128)))
  (and (> (len input) u0) (<= (len input) u128)))

;; Validate council description
(define-private (is-valid-council-desc (input (string-utf8 512)))
  (and (> (len input) u0) (<= (len input) u512)))

;; Validate voting duration
(define-private (is-valid-voting-duration (duration uint))
  (and (>= duration MIN-VOTING-DURATION) (<= duration MAX-VOTING-DURATION)))

;; Validate proposal ID exists
(define-private (is-valid-proposal-id (proposal-id uint))
  (and (> proposal-id u0) (<= proposal-id (var-get proposal-counter))))

;; Validate amount is reasonable
(define-private (is-valid-amount (amount uint))
  (and (> amount u0) (<= amount MAX-BET-AMOUNT)))

;; Validate list length
(define-private (is-valid-member-list (members (list 20 principal)))
  (and (> (len members) u0) (<= (len members) MAX-COUNCIL-MEMBERS)))

;; Helper Functions

;; Calculate quadratic voting cost
(define-private (calculate-quadratic-cost (votes uint))
  (* votes votes))

;; Check if user has sufficient voice credits
(define-private (has-sufficient-credits (user principal) (credits-needed uint))
  (let ((cycle (var-get governance-cycle)))
    (match (map-get? voice-credits { user: user, cycle: cycle })
      user-credits 
        (>= (- (get total-credits user-credits) (get used-credits user-credits)) credits-needed)
      false)))

;; Calculate dynamic quorum based on participation history
(define-private (calculate-dynamic-quorum (proposal-id uint))
  (let (
    (base-quorum BASE-QUORUM-PERCENTAGE)
    (total-tokens (var-get total-governance-tokens))
  )
    (/ (* total-tokens base-quorum) u100)))

;; Public Functions

;; Create a new governance proposal
(define-public (submit-proposal 
  (title (string-utf8 256))
  (description (string-utf8 2048)) 
  (topic (string-ascii 64))
  (voting-duration uint))
  (let (
    (proposal-id (+ (var-get proposal-counter) u1))
    (creator tx-sender)
    (creation-block block-height)
    (voting-deadline (+ block-height voting-duration))
    (quorum (calculate-dynamic-quorum proposal-id))
  )
    ;; Input validation
    (asserts! (is-valid-string-utf8 title) ERR-INVALID-INPUT)
    (asserts! (is-valid-description description) ERR-INVALID-INPUT) 
    (asserts! (is-valid-string-ascii topic) ERR-INVALID-INPUT)
    (asserts! (is-valid-voting-duration voting-duration) ERR-INVALID-INPUT)
    
    ;; Check if user has minimum tokens to create proposal
    (asserts! (>= (stx-get-balance tx-sender) MIN-PROPOSAL-THRESHOLD) ERR-INSUFFICIENT-TOKENS)
    
    ;; Create the proposal
    (map-set proposals 
      { proposal-id: proposal-id }
      {
        creator: creator,
        title: title,
        description: description,
        topic: topic,
        stage: "review",
        creation-block: creation-block,
        voting-deadline: voting-deadline,
        quorum-required: quorum,
        for-votes: u0,
        against-votes: u0,
        quadratic-for: u0,
        quadratic-against: u0,
        executed: false
      })
    
    ;; Update proposal counter
    (var-set proposal-counter proposal-id)
    
    ;; Update user stats
    (match (map-get? user-profiles { user: creator })
      profile 
        (map-set user-profiles 
          { user: creator }
          (merge profile { 
            total-proposals-created: (+ (get total-proposals-created profile) u1),
            last-activity: block-height
          }))
      (map-set user-profiles 
        { user: creator }
        {
          governance-reputation: u100,
          total-proposals-created: u1,
          total-votes-cast: u0,
          delegation-trust-score: u100,
          last-activity: block-height
        }))
    
    (ok proposal-id)))

;; Revoke delegation for a specific topic
(define-public (revoke-delegation (topic (string-ascii 64)))
  (let ((delegator tx-sender))
    ;; Input validation
    (asserts! (is-valid-string-ascii topic) ERR-INVALID-INPUT)
    
    (map-delete delegation-registry { delegator: delegator, topic: topic })
    (map-delete delegation-chains { voter: delegator, topic: topic })
    (ok true)))

;; Create a specialized governance council
(define-public (create-council 
  (council-id (string-ascii 64))
  (name (string-utf8 128))
  (description (string-utf8 512))
  (initial-members (list 20 principal))
  (min-reputation uint)
  (has-veto-power bool))
  (begin
    ;; Input validation
    (asserts! (is-valid-string-ascii council-id) ERR-INVALID-INPUT)
    (asserts! (is-valid-council-name name) ERR-INVALID-INPUT)
    (asserts! (is-valid-council-desc description) ERR-INVALID-INPUT)
    (asserts! (is-valid-member-list initial-members) ERR-INVALID-INPUT)
    (asserts! (> min-reputation u0) ERR-INVALID-INPUT)
    
    ;; Only contract owner can create councils initially
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    
    (map-set councils
      { council-id: council-id }
      {
        name: name,
        description: description,
        members: initial-members,
        term-start: block-height,
        term-end: (+ block-height (* COUNCIL-TERM-LENGTH u144)),
        min-reputation: min-reputation,
        veto-power: has-veto-power
      })
    
    (ok true)))

;; Place a prediction bet on a proposal outcome
(define-public (place-prediction-bet (proposal-id uint) (amount uint) (predicted-outcome bool))
  (let ((bettor tx-sender))
    ;; Input validation
    (asserts! (is-valid-proposal-id proposal-id) ERR-INVALID-INPUT)
    (asserts! (is-valid-amount amount) ERR-INVALID-INPUT)
    
    ;; Check if proposal exists
    (asserts! (is-some (map-get? proposals { proposal-id: proposal-id })) ERR-INVALID-PROPOSAL)
    
    ;; Check if user has sufficient balance
    (asserts! (>= (stx-get-balance bettor) amount) ERR-INSUFFICIENT-TOKENS)
    
    ;; Check if user hasn't already bet on this proposal
    (asserts! (is-none (map-get? prediction-bets { proposal-id: proposal-id, bettor: bettor })) ERR-ALREADY-VOTED)
    
    ;; Record the bet
    (map-set prediction-bets
      { proposal-id: proposal-id, bettor: bettor }
      {
        amount-staked: amount,
        predicted-outcome: predicted-outcome,
        timestamp: block-height,
        claimed: false
      })
    
    ;; Update market totals
    (match (map-get? prediction-markets { proposal-id: proposal-id })
      market-data
        (if predicted-outcome
          (map-set prediction-markets 
            { proposal-id: proposal-id }
            (merge market-data { total-staked-for: (+ (get total-staked-for market-data) amount) }))
          (map-set prediction-markets 
            { proposal-id: proposal-id }
            (merge market-data { total-staked-against: (+ (get total-staked-against market-data) amount) })))
      (map-set prediction-markets
        { proposal-id: proposal-id }
        {
          total-staked-for: (if predicted-outcome amount u0),
          total-staked-against: (if predicted-outcome u0 amount),
          resolved: false,
          actual-outcome: none
        }))
    
    (ok true)))

;; Execute a passed proposal (simplified implementation)
(define-public (execute-proposal (proposal-id uint))
  (begin
    ;; Input validation
    (asserts! (is-valid-proposal-id proposal-id) ERR-INVALID-INPUT)
    
    (match (map-get? proposals { proposal-id: proposal-id })
      proposal-data
        (let (
          (total-quadratic-votes (+ (get quadratic-for proposal-data) (get quadratic-against proposal-data)))
          (quorum-met (>= total-quadratic-votes (get quorum-required proposal-data)))
          (proposal-passed (> (get quadratic-for proposal-data) (get quadratic-against proposal-data)))
        )
          (asserts! (is-eq (get stage proposal-data) "voting") ERR-INVALID-PROPOSAL)
          (asserts! (>= block-height (get voting-deadline proposal-data)) ERR-PROPOSAL-EXPIRED)
          (asserts! quorum-met ERR-INSUFFICIENT-TOKENS)
          (asserts! proposal-passed ERR-INVALID-PROPOSAL)
          (asserts! (not (get executed proposal-data)) ERR-INVALID-PROPOSAL)
          
          ;; Mark as executed
          (map-set proposals 
            { proposal-id: proposal-id }
            (merge proposal-data { 
              executed: true,
              stage: "executed"
            }))
          
          ;; Resolve prediction market
          (match (map-get? prediction-markets { proposal-id: proposal-id })
            market-data
              (map-set prediction-markets
                { proposal-id: proposal-id }
                (merge market-data { 
                  resolved: true,
                  actual-outcome: (some true)
                }))
            true)
          
          (ok true))
      ERR-INVALID-PROPOSAL)))

;; Read-only functions

;; Get proposal details
(define-read-only (get-proposal (proposal-id uint))
  (map-get? proposals { proposal-id: proposal-id }))

;; Get user's delegation for a topic
(define-read-only (get-delegation (user principal) (topic (string-ascii 64)))
  (map-get? delegation-registry { delegator: user, topic: topic }))

;; Get user's voice credits for current cycle
(define-read-only (get-voice-credits (user principal))
  (map-get? voice-credits { user: user, cycle: (var-get governance-cycle) }))

;; Get user's governance profile
(define-read-only (get-user-profile (user principal))
  (map-get? user-profiles { user: user }))

;; Get council information
(define-read-only (get-council (council-id (string-ascii 64)))
  (map-get? councils { council-id: council-id }))

;; Get prediction market data
(define-read-only (get-prediction-market (proposal-id uint))
  (map-get? prediction-markets { proposal-id: proposal-id }))

;; Get system statistics
(define-read-only (get-system-stats)
  {
    total-proposals: (var-get proposal-counter),
    current-cycle: (var-get governance-cycle),
    system-paused: (var-get system-paused),
    total-tokens: (var-get total-governance-tokens)
  })

;; Admin functions (for initial setup and emergency use)

;; Allocate initial governance tokens
(define-public (allocate-governance-tokens (amount uint))
  (begin
    ;; Input validation
    (asserts! (> amount u0) ERR-INVALID-INPUT)
    (asserts! (<= amount u1000000000) ERR-INVALID-INPUT) ;; max 1B tokens
    
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (var-set total-governance-tokens (+ (var-get total-governance-tokens) amount))
    (ok true)))

;; Emergency pause system
(define-public (pause-system (paused bool))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (var-set system-paused paused)
    (ok true)))

;; Start new governance cycle
(define-public (start-new-cycle)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (var-set governance-cycle (+ (var-get governance-cycle) u1))
    (ok true)))