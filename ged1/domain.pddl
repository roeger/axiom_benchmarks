
;; Relational single-step domain formulation, with ITT operations.

(define (domain genome-edit-distance)
  (:requirements :adl :derived-predicates :action-costs)

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

   ;; Declare the idle predicate so we can use the same instance
   ;; files as the STRIPS version
   (idle)

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

  (:action transpose
   :parameters (?x-pre ?x ?y ?y-post ?z ?z-post)
   :precondition (and (not (= ?x-pre ?x))
		      (not (= ?y ?y-post))
		      (not (= ?z ?z-post))
		      (not (= ?z-post ?x))
		      (not (= ?x ?z))
		      (not (= ?y ?z))
		      (not-between ?x ?y ?z)
		      (cw ?x-pre ?x)
		      (cw ?y ?y-post)
		      (cw ?z ?z-post))
   :effect (and
	    ;; the gene ?x-pre that was before ?x will not be;
	    (not (cw ?x-pre ?x))
	    ;; the gene ?y-post that was after ?y will not be;
	    (not (cw ?y ?y-post))
	    ;; and (cw ?x-pre ?y-post) will hold;
	    (cw ?x-pre ?y-post)
	    ;; the gene ?z-post that was after ?z will not be;
	    (not (cw ?z ?z-post))
	    ;; ?x will be after ?z, and ?y before ?z-post
	    (cw ?z ?x)
	    (cw ?y ?z-post)
	    (increase (total-cost) 2))
   )

  ;; Invert the segment between ?x and ?y, inclusive. ?x may not equal
  ;; ?y: inversion of a single gene is done by the invert-single-gene
  ;; action; the ?x-?y segment can also not be the entire genome, but
  ;; can be all-but-one; in this case, ?x-pre = ?y-post

  (:action invert
   :parameters (?x-pre ?x ?y ?y-post)
   :precondition (and (not (= ?x ?y))
		      (not (= ?x-pre ?x))
		      (not (= ?y ?y-post))
		      (not (= ?y-post ?x))
		      (not (= ?x-pre ?y))
		      (cw ?x-pre ?x)
		      (cw ?y ?y-post))
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
	    ;; the gene ?x-pre that was before ?x will be before ?y, and
	    ;; the gene ?y-post that was after ?y will be after ?x; if these
	    ;; two are the same (which happens if we invert a segment
	    ;; consisting of all genes but one), this effect is
	    ;; redundant/contradictory, and thus will not trigger
	    (when (not (= ?x-pre ?y-post))
	      (and (not (cw ?x-pre ?x))
		   (cw ?x-pre ?y)
		   (not (cw ?y ?y-post))
		   (cw ?x ?y-post)))
	    (increase (total-cost) 1))
   )

  ;; Invert a single gene ?x. This does not change the position of ?x
  ;; relative to any other gene, only the orientation of ?x.

  (:action invert-single-gene
   :parameters (?x)
   :precondition (and (= ?x ?x)) ; dummy precondition
   :effect (and
	    (when (normal ?x)
	      (and (not (normal ?x)) (inverted ?x)))
	    (when (inverted ?x)
	      (and (not (inverted ?x)) (normal ?x)))
	    (increase (total-cost) 1))
   )


  ;; Transpose and invert the segment between ?x and ?y, inclusive,
  ;; inserting it after ?z. This action has the same effects as
  ;; transpose, except that in the resulting state ?y will be after
  ;; ?z and ?x before ?z-post, plus the "interior" effects of invert.
  ;; This action is applicable to a single-gene segment.

  (:action transvert
   :parameters (?x-pre ?x ?y ?y-post ?z ?z-post)
   :precondition (and (not (= ?x-pre ?x))
		      (not (= ?y ?y-post))
		      (not (= ?z ?z-post))
		      (not (= ?z-post ?x))
		      (not (= ?x ?z))
		      (not (= ?y ?z))
		      (not-between ?x ?y ?z)
		      (cw ?x-pre ?x)
		      (cw ?y ?y-post)
		      (cw ?z ?z-post))
   :effect (and
	    ;; Transposition effects:
	    ;; the gene ?x-pre that was before ?x will not be;
	    (not (cw ?x-pre ?x))
	    ;; the gene ?y-post that was after ?y will not be;
	    (not (cw ?y ?y-post))
	    ;; and (cw ?x-pre ?y-post) will hold;
	    (cw ?x-pre ?y-post)
	    ;; the gene ?z-post that was after ?z will not be;
	    (not (cw ?z ?z-post))
	    ;; ?y will be after ?z, and ?x before ?z-post
	    (cw ?z ?y)
	    (cw ?x ?z-post)
	    ;; Inversion effects:
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
	    (increase (total-cost) 2))
   )

  )
