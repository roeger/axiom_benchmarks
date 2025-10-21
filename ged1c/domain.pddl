
;; Split relational single-step domain formulation, with ITT operations.

;; This domain formulation breaks each of the edit operations into a
;; fixed number of actions, as follows:
;;
;; transpose:
;;   begin-transpose, do-unlink-left, do-unlink-right, do-close-gap,
;;   do-break-after, do-insert-link-left, do-insert-link-right,
;;   end-transpose.
;;
;; invert:
;;   begin-invert, do-unlink2-left, do-unlink2-right, do-insert-link-left,
;;   do-insert-link-right, do-invert-segment, end-invert.
;;
;; transvert:
;;   begin-transvert, do-unlink-left, do-unlink-right, do-close-gap,
;;   do-break-after, do-insert-link-left, do-insert-link-right,
;;   do-invert-segment, end-transvert.
;;
;; The order of the actions part of each operation is not completely fixed.
;;
;; The actions involved in an inversion are all given a cost of 1, so the
;; total cost of an inversion is 7. To enforce a relative weighting of 2
;; for transpositions/transversions to 1 for inversions, the total cost
;; of those operations must equal 14. This is done by adding the extra cost
;; of 5 to begin-transpose and 4 to begin-transvert. Thus, to get the actual
;; weighted edit distance from a plan generated from this domain, the plan
;; cost should be divided by 7.

(define (domain genome-edit-distance)
  (:requirements :adl :derived-predicates :fluents)

  (:predicates
   ;; Static predicate, identifies duplicate copies of genes.
   ;; The "duplicate" relation is symmetric; "swappable" is an
   ;; asymmetric subrelation (used to eliminate symmetric
   ;; instantiations of the swapping operator).
   ;;
   ;; Note: These predicates are not used in the domain version
   ;; with ITT operations only. They are declared only for
   ;; interoperability with problem files that use them.
   (duplicate ?x ?y)
   (swappable ?x ?y)

   ;; Genome representation: The genome is a cycle, represented
   ;; by the relation cw ("clockwise"). Each gene in the genome
   ;; is either "normal" or "inverted".
   (cw ?x ?y)
   (normal ?x)
   (inverted ?x)
   (present ?x)

   ;; Control predicates
   (idle)
   (transposing)
   (transverting)
   (inverting)
   (todo-unlink-left ?x)
   (todo-unlink-right ?x)
   (todo-unlink2-left ?x)
   (todo-unlink2-right ?x)
   (todo-break-after ?x)
   (todo-insert-1 ?x)
   (todo-insert-2 ?x)
   (todo-close-gap-left ?x)
   (todo-close-gap-right ?x)
   (todo-link-right ?x)
   (todo-link-left ?x)
   (done-cut)
   (done-insert-1)
   (done-insert-2)
   (todo-invert-segment ?x ?y)
   (done-invert-segment)

   ;; Derived predicates:

   ;; ?z is between ?x and ?y
   (between ?x ?y ?z)

   ;; ?z is not between ?x and ?y
   (not-between ?x ?y ?z)
   )

  (:functions
   (total-cost)
   )

  ;; Axioms

  ;; Note: These axiom definitions work only for the case when all genes
  ;; (i.e., all objects) are part of the genome. They are not correct for
  ;; problems with possibly non-present (free or deleted) genes.

  ;; ?z is between ?x and ?y, inclusive.
  ;; This is true iff
  ;; a) ?z is equal to ?x or ?y; or
  ;; b) ?w is next from ?x, ?w is not equal to ?y and ?z is between
  ;;  ?w and ?y.
  ;;
  ;; Note: when ?x = ?y, there are two interpretations of what is "the
  ;; segment between ?x and ?y"; it may be the segment consisting of
  ;; ?x/?y only, or the whole genome (starting from ?x going clockwise
  ;; until back at ?x). The intended meaning is the former, i.e., that
  ;; (between ?x ?x ?z) holds only for ?z = ?x.

  (:derived (between ?x ?y ?z)
	    (or (= ?z ?x) (= ?z ?y)))
  (:derived (between ?x ?y ?z)
	    (and (not (= ?x ?y))
		 (exists (?w) (and (cw ?x ?w)
				   (not (= ?y ?w))
				   (between ?w ?y ?z)))))

  ;; ?z is not between ?x and ?y, inclusive.
  ;; This is true iff
  ;; 1) ?z is not equal or ?x or ?y; and
  ;; 2a) ?x is equal to ?y; or
  ;; 2b) ?w is next from ?x, ?w is not equal to ?z and ?z is
  ;;    not-between ?w and ?y
  (:derived (not-between ?x ?y ?z)
	    (and (not (= ?x ?z)) (not (= ?y ?z)) (= ?x ?y)))
  (:derived (not-between ?x ?y ?z)
	    (and (not (= ?x ?z))
		 (not (= ?y ?z))
		 (exists (?w)
			 (and (cw ?x ?w)
			      (not (= ?z ?w))
			      (not-between ?w ?y ?z)))))


  ;; Actions

  ;; Transpose removes the segment between ?x and ?y, inclusive (?x
  ;; may be equal to ?y, if the segment consists of a single gene)
  ;; and inserts it after ?z; ?z must be not-between ?x and ?y (and
  ;; thus distinct from ?x and ?y).

  (:action begin-transpose
   :parameters (?x ?y ?z)
   :precondition (and (not-between ?x ?y ?z)
		      (idle))
   :effect (and (not (idle))
		(transposing)
		(todo-unlink-left ?x)
		(todo-unlink-right ?y)
		(todo-break-after ?z)
		(todo-insert-1 ?x)
		(todo-insert-2 ?y)
		(increase (total-cost) 6)) ;; 1 + 5
   )

  (:action do-unlink-left
   :parameters (?x-pre ?x)
   :precondition (and (cw ?x-pre ?x)
		      (todo-unlink-left ?x))
   :effect (and (not (cw ?x-pre ?x))
		(not (todo-unlink-left ?x))
		(todo-close-gap-right ?x-pre)
		(increase (total-cost) 1))
   )

  (:action do-unlink-right
   :parameters (?x ?x-post)
   :precondition (and (cw ?x ?x-post)
		      (todo-unlink-right ?x))
   :effect (and (not (cw ?x ?x-post))
		(not (todo-unlink-right ?x))
		(todo-close-gap-left ?x-post)
		(increase (total-cost) 1))
   )

  (:action do-close-gap
   :parameters (?x ?y)
   :precondition (and (todo-close-gap-right ?x)
		      (todo-close-gap-left ?y))
   :effect (and (cw ?x ?y)
		(not (todo-close-gap-right ?x))
		(not (todo-close-gap-left ?y))
		(done-cut)
		(increase (total-cost) 1))
   )

  (:action do-break-after
   :parameters (?x ?x-post)
   :precondition (and (cw ?x ?x-post)
		      (done-cut)
		      (todo-break-after ?x))
   :effect (and (not (cw ?x ?x-post))
		(not (todo-break-after ?x))
		(todo-link-right ?x)
		(todo-link-left ?x-post)
		(increase (total-cost) 1))
   )

  (:action do-insert-link-right
   :parameters (?x ?y)
   :precondition (and (todo-link-right ?x)
		      (todo-insert-1 ?y))
   :effect (and (cw ?x ?y)
		(not (todo-link-right ?x))
		(not (todo-insert-1 ?y))
		(done-insert-1)
		(increase (total-cost) 1))
   )

  (:action do-insert-link-left
   :parameters (?x ?y)
   :precondition (and (todo-link-left ?y)
		      (todo-insert-2 ?x))
   :effect (and (cw ?x ?y)
		(not (todo-link-left ?y))
		(not (todo-insert-2 ?x))
		(done-insert-2)
		(increase (total-cost) 1))
   )

  (:action end-transpose
   :parameters ()
   :precondition (and (transposing)
		      (done-cut)
		      (done-insert-1)
		      (done-insert-2))
   :effect (and (not (transposing))
		(not (done-cut))
		(not (done-insert-1))
		(not (done-insert-2))
		(idle)
		(increase (total-cost) 1))
   )

  ;; Transvert

  (:action begin-transvert
   :parameters (?x ?y ?z)
   :precondition (and (not-between ?x ?y ?z)
		      (idle))
   :effect (and (not (idle))
		(transverting)
		(todo-unlink-left ?x)
		(todo-unlink-right ?y)
		(todo-break-after ?z)
		(todo-insert-1 ?y)
		(todo-insert-2 ?x)
		(todo-invert-segment ?x ?y)
		(increase (total-cost) 5)) ;; 1 + 4
   )

  (:action end-transvert
   :parameters ()
   :precondition (and (transverting)
		      (done-cut)
		      (done-insert-1)
		      (done-insert-2)
		      (done-invert-segment))
   :effect (and (not (transverting))
		(not (done-cut))
		(not (done-insert-1))
		(not (done-insert-2))
		(not (done-invert-segment))
		(idle)
		(increase (total-cost) 1))
   )

  ;; Invert

  (:action begin-invert
   :parameters (?x ?y)
   :precondition (and (idle))
   :effect (and (not (idle))
		(inverting)
		(todo-unlink2-left ?x)
		(todo-unlink2-right ?y)
		(todo-insert-1 ?y)
		(todo-insert-2 ?x)
		(todo-invert-segment ?x ?y)
		(increase (total-cost) 1))
   )

  (:action do-unlink2-left
   :parameters (?x-pre ?x)
   :precondition (and (cw ?x-pre ?x)
		      (todo-unlink2-left ?x))
   :effect (and (not (cw ?x-pre ?x))
		(not (todo-unlink-left ?x))
		(todo-link-right ?x-pre)
		(increase (total-cost) 1))
   )

  (:action do-unlink2-right
   :parameters (?x ?x-post)
   :precondition (and (cw ?x ?x-post)
		      (todo-unlink-right ?x))
   :effect (and (not (cw ?x ?x-post))
		(not (todo-unlink-right ?x))
		(todo-link-left ?x-post)
		(increase (total-cost) 1))
   )

  (:action end-invert
   :parameters ()
   :precondition (and (inverting)
		      (done-insert-1)
		      (done-insert-2)
		      (done-invert-segment))
   :effect (and (not (inverting))
		(not (done-insert-1))
		(not (done-insert-2))
		(not (done-invert-segment))
		(idle)
		(increase (total-cost) 1))
   )

  ;; Invert the segment between ?x and ?y, inclusive; this action only
  ;; takes care of inverting the segment "internally", i.e., flipping
  ;; the orientation of each gene in the segment and reversing the
  ;; cw relation between genes in the segment.

  (:action do-invert-segment
   :parameters (?x ?y)
   :precondition (and (todo-invert-segment ?x ?y))
   :effect (and
	    ;; each gene ?w that is between ?x and ?y (including ?x
	    ;; and ?y) will have its orientation inverted; i.e., if
	    ;; it was normal it becomes inverted, and if it was
	    ;; inverted, it becomes normal.
	    (forall (?w) (when (and (between ?x ?y ?w)
				    (normal ?w))
			   (and (not (normal ?w))
				(inverted ?w))))
	    (forall (?w) (when (and (between ?x ?y ?w)
				    (inverted ?w))
			   (and (not (inverted ?w))
				(normal ?w))))
	    ;; each pair of genes ?v and ?w such that both are
	    ;; between ?x and ?y, and (cw ?v ?w) holds, will have
	    ;; their relationship reversed, i.e., (cw ?w ?v) will
	    ;; hold instead.
	    (forall (?v ?w) (when (and (cw ?v ?w)
				       (between ?x ?y ?v)
				       (between ?x ?y ?w))
			      (and (not (cw ?v ?w))
				   (cw ?w ?v))))
	    (not (todo-invert-segment ?x ?y))
	    (done-invert-segment)
	    (increase (total-cost) 1))
   )

  )
