(define (domain grid)
 (:requirements :typing :fluents :equality)
 (:types
         cell
         side)
 (:constants up - side
             down - side
             left - side
             right - side)
 (:predicates
               (dispenser ?c - cell)
               (proc ?c - cell)

	       (busy ?p - cell) ;; proc is busy handling a hot job
	       (newjob ?c - cell) ;; proc has received a new hot job (either to handle or pass on)
	       (available ?c - cell) ;; cannot handle any hot job

               (bar-neighs ?c - cell)

	       (request ?c - cell ?dir - side)
	       (accept ?c - cell ?dir - side)
	       (reject ?c - cell ?dir - side)
               (sending ?c - cell ?dir - side)
               (recd ?c - cell ?dir - side)

	       (threshold-exceed ?c - cell) ;; too many neighbours have hot jobs= so i cannot accept any
	       (threshold-reach ?c - cell) ;; cannot have any more neighbours take up hot jobs

	       (neighbour ?dir - side ?c1 - cell ?c2 - cell) ;; (neigbour left c1 c2) == (c1 is left neighbour of c2)

	       (job0) ;; 1 live job in system
	       (job1) ;; 2 live jobs in system
	       (job2)
	       (job3)
	       (job4)
	       (job5)
	       (job6)
	       (job7)
	       (job8)
	       (job9)
	       (job10)
	       (job11)
	       (job12)
	       (job13)
	       (job14) ;; 15 live jobs in system
	       )
 
 

 ;; ========================================
 ;; marking threshold - this is required to
 ;; to implement the policy "cannot allow more than two busy neighbours if i'm busy"
 ;;==============================================

 (:action control-mark-threshold-reach
  :parameters (?c - cell ?n1 - cell ?s1 - side ?n2 - cell ?s2 - side)
  :precondition (and 
                     (proc ?c)
                     (proc ?n1)
                     (proc ?n2)
                     (neighbour ?s1 ?n1 ?c)
                     (neighbour ?s2 ?n2 ?c)
                     (busy ?n1)
                     (busy ?n2)
                     (not (= ?n1 ?n2))
		     (not (threshold-reach ?c)))
  :effect (and (threshold-reach ?c))
 )

 ;; unmarking threshold - atleast three are free

 (:action control-unmark-threshold-reach
  :parameters (?c - cell ?n1 - cell ?s1 - side ?n2 - cell ?s2 - side ?n3 - cell ?s3 - side)
  :precondition (and 
                     (proc ?c)
                     (neighbour ?s1 ?n1 ?c)
                     (neighbour ?s2 ?n2 ?c)
                     (neighbour ?s3 ?n3 ?c)
                     (not (busy ?n1))
                     (not (busy ?n2))
                     (not (busy ?n3))
                     (not (= ?n1 ?n2))
                     (not (= ?n2 ?n3))
                     (not (= ?n3 ?n1))
		     (threshold-reach ?c))
  :effect (and (not (threshold-reach ?c)))
 )

 ;; ===========================================
 ;; threshold exceeded (atleast three neighbours busy)
 ;; required to implement same policy as above -- "cannot allow more than two busy neighbours if i'm busy"=
 ;; Basically, required to avoid accepting a job
 ;; when three or more neighbours are busy
 ;; =======================================



 (:action control-mark-threshold-exceed
  :parameters (?c - cell ?n1 - cell ?s1 - side ?n2 - cell ?s2 - side ?n3 - cell ?s3 - side)
  :precondition (and (proc ?c)
                     (proc ?n1)
                     (proc ?n2)
                     (proc ?n3)
                     (neighbour ?s1 ?n1 ?c)
                     (neighbour ?s2 ?n2 ?c)
                     (neighbour ?s3 ?n3 ?c)
                     (busy ?n1)
                     (busy ?n2)
                     (busy ?n3)
                     (not (= ?n1 ?n2))
                     (not (= ?n2 ?n3))
                     (not (= ?n3 ?n1))
		     (not (threshold-exceed ?c)))
  :effect (and (threshold-exceed ?c))
 )

 ;;===============================================================================
 ;; unmark threshold exceed (atleast two neighbours not busy), can take up hot jobs
 ;; ================================================================================

 (:action control-unmark-exceed
  :parameters (?c - cell ?n1 - cell ?s1 - side ?n2 - cell ?s2 - side)
  :precondition (and (proc ?c)
                     (neighbour ?s1 ?n1 ?c)
                     (neighbour ?s2 ?n2 ?c)
                     (not (busy ?n1))
                     (not (busy ?n2))
                     (not (= ?n1 ?n2))
		     (threshold-exceed ?c))
  :effect (and (not (threshold-exceed ?c)))
 )

 ;; ===============================================
 ;; mark unavailable when busy with hot job
 ;; ========================================

 (:action control-mark-unavailable-busy
  :parameters (?c - cell)
  :precondition (and (busy ?c)
                     (available ?c))
  :effect (and (not (available ?c)))
 )

 ;; ===============================================
 ;; mark unavailable when busy self threshold exceeded
 ;; ========================================

 (:action control-mark-unavailable-threshold-exceed
  :parameters (?c - cell)
  :precondition (and (threshold-exceed ?c)
                     (available ?c))
  :effect (and (not (available ?c)))
 )

 ;; ========================================
 ;; mark unavailable when neighbours threshold reached
 ;; ========================================

 (:action control-bar-neighs-avail
  :parameters (?c - cell)
  :precondition (and (busy ?c)
                     (threshold-reach ?c)
                     (not (bar-neighs ?c)))
  :effect (and (bar-neighs ?c)))


 (:action control-mark-unavailable-neighbour-threshold-reached
  :parameters (?c - cell ?n - cell ?s - side)
  :precondition (and (neighbour ?s ?c ?n)
                     (bar-neighs ?n)
                     (available ?c))
  :effect (and (not (available ?c)))
 )

 ;; ========================================
 ;; mark available when not busy, threshold not exceeded and neighbours ok too
 ;; ========================================


 (:action control-unbar-neighs-not-busy
  :parameters (?c - cell)
  :precondition (and (not (busy ?c))
                     (bar-neighs ?c))
  :effect (and (not (bar-neighs ?c))))

 (:action control-unbar-neighs-not-threshold-reach
  :parameters (?c - cell)
  :precondition (and (not (threshold-reach ?c))
                     (bar-neighs ?c))
  :effect (and (not (bar-neighs ?c))))

 (:action control-mark-available
  :parameters (?c - cell ?n1 - cell ?n2 - cell ?n3 - cell ?n4 - cell)
  :precondition (and (proc ?c)
                     (not (busy ?c))
                     (neighbour left ?n1 ?c)
                     (neighbour up ?n2 ?c)
                     (neighbour right ?n3 ?c)
                     (neighbour down ?n4 ?c)
		     (not (bar-neighs ?n1))
		     (not (bar-neighs ?n2))
		     (not (bar-neighs ?n3))
		     (not (bar-neighs ?n4))
                     (not (threshold-exceed ?c))
                     (not (available ?c)))
  :effect (and (available ?c))
 )

 ;; ========================================
 ;; propagate the request if cannot take the job
 ;; ========================================

 (:action control-request-passon-left
  :parameters (?p - cell ?n1 - cell)
  :precondition (and (proc ?p)
                     (not (available ?p))
                     (neighbour left ?n1 ?p)
                     (request ?n1 right)
                     (not (request ?p left))
                     (not (request ?p right))
                     (not (request ?p up))
                     (not (request ?p down)))
  :effect (and  (request ?p right)
                (request ?p up)
                (request ?p down))
 )

 (:action control-request-passon-right
  :parameters (?p - cell ?n1 - cell)
  :precondition (and (proc ?p)
                     (not (available ?p))
                     (neighbour right ?n1 ?p)
                     (request ?n1 left)
                     (not (request ?p left))
                     (not (request ?p right))
                     (not (request ?p up))
                     (not (request ?p down)))
  :effect (and  (request ?p left)
                (request ?p up)
                (request ?p down))
 )

 (:action control-request-passon-up
  :parameters (?p - cell ?n1 - cell)
  :precondition (and (proc ?p)
                     (not (available ?p))
                     (neighbour up ?n1 ?p)
                     (request ?n1 down)
                     (not (request ?p left))
                     (not (request ?p right))
                     (not (request ?p up))
                     (not (request ?p down)))
  :effect (and  (request ?p left)
                (request ?p right)
                (request ?p down))
 )

 (:action control-request-passon-down
  :parameters (?p - cell ?n1 - cell)
  :precondition (and (proc ?p)
                     (not (available ?p))
                     (neighbour down ?n1 ?p)
                     (request ?n1 up)
                     (not (request ?p left))
                     (not (request ?p right))
                     (not (request ?p up))
                     (not (request ?p down)))
  :effect (and  (request ?p left)
                (request ?p right)
                (request ?p up))
 )


 ;; ========================================
 ;; ========= accept the request if can take the job
 ;; ========================================

 (:action control-accept
  :parameters (?p - cell ?n1 - cell ?s1 - side ?s1op - side)
  :precondition (and (proc ?p)
                     (available ?p)
                     (neighbour ?s1 ?n1 ?p)
                     (neighbour ?s1op ?p ?n1)
                     (request ?n1 ?s1op)
                     (not (accept ?p left))
                     (not (accept ?p right))
                     (not (accept ?p up))
                     (not (accept ?p down)))
  :effect (and (accept ?p ?s1))
 )

 ;; ========================================
 ;; propagate the accept back to the source
 ;; ========================================

 (:action control-accept-passon
  :parameters (?c - cell ?n2 - cell ?s1 - side ?s1op - side ?sparent - side) 
           ;; c is where request came from; n2 is where it was accepted
  :precondition (and (proc ?c)
                     (neighbour ?s1 ?n2 ?c) ;; n2 is upper neighbour
                     (neighbour ?s1op ?c ?n2) ;;
		     (request ?c ?s1)
		     (accept ?n2 ?s1op)
                     (not (request ?c ?sparent)) ;; whoever I've not requested to
                                                 ;; has to be the parent
		     (not (accept ?c left))
		     (not (accept ?c right))
		     (not (accept ?c up))
		     (not (accept ?c down)))
  :effect (and (accept ?c ?sparent))
 )

 ;; ========================================
 ;; reject to any non-parent requester
 ;; ===============================

 (:action control-reject-non-parent
  :parameters (?c - cell ?n2 - cell ?s1 - side ?s1op - side) 
           ;; c is where request came from; n2 is where it was accepted
  :precondition (and (proc ?c)
                     (neighbour ?s1 ?n2 ?c) ;; n2 is
                     (neighbour ?s1op ?c ?n2) ;;
		     (request ?c ?s1) ;; I have requested
		     (request ?n2 ?s1op) ;; Neighbour is requesting too
                     (not (reject ?c ?s1)))
  :effect (and (reject ?c ?s1))
 )

 ;; ========================================
 ;; reject to parent requester
 ;; ========================================

 (:action control-reject-parent-left
  :parameters (?c - cell ?n1 - cell ?n2 - cell ?n3 - cell) 
           ;; c is where request came from; n2 is where it was accepted
  :precondition (and (proc ?c)
                     (neighbour up ?n1 ?c)
                     (neighbour down ?n2 ?c)
                     (neighbour right ?n3 ?c)
                     (request ?c up)
                     (request ?c down)
                     (request ?c right)
                     (reject ?n1 down)
                     (reject ?n2 up)
                     (reject ?n3 left)
                     (not (reject ?c left)))
  :effect (and (reject ?c left))
 )

 (:action control-reject-parent-right
  :parameters (?c - cell ?n1 - cell ?n2 - cell ?n3 - cell) 
           ;; c is where request came from; n2 is where it was accepted
  :precondition (and (proc ?c)
                     (neighbour up ?n1 ?c)
                     (neighbour down ?n2 ?c)
                     (neighbour left ?n3 ?c)
                     (request ?c up)
                     (request ?c down)
                     (request ?c left)
                     (reject ?n1 down)
                     (reject ?n2 up)
                     (reject ?n3 right)
                     (not (reject ?c right)))
  :effect (and (reject ?c right))
 )

 (:action control-reject-parent-up
  :parameters (?c - cell ?n1 - cell ?n2 - cell ?n3 - cell) 
           ;; c is where request came from; n2 is where it was accepted
  :precondition (and (proc ?c)
                     (neighbour left ?n1 ?c)
                     (neighbour right ?n2 ?c)
                     (neighbour down ?n3 ?c)
                     (request ?c left)
                     (request ?c right)
                     (request ?c down)
                     (reject ?n1 right)
                     (reject ?n2 left)
                     (reject ?n3 up)
                     (not (reject ?c up)))
  :effect (and (reject ?c up))
 )

 (:action control-reject-parent-down
  :parameters (?c - cell ?n1 - cell ?n2 - cell ?n3 - cell) 
           ;; c is where request came from; n2 is where it was accepted
  :precondition (and (proc ?c)
                     (neighbour left ?n1 ?c)
                     (neighbour right ?n2 ?c)
                     (neighbour up ?n3 ?c)
                     (request ?c left)
                     (request ?c right)
                     (request ?c up)
                     (reject ?n1 right)
                     (reject ?n2 left)
                     (reject ?n3 down)
                     (not (reject ?c down)))
  :effect (and (reject ?c down))
 )

 ;; ===========================================
 ;; initiate sending job to accepting neighbour
 ;; ===========================================

 (:action control-send
  :parameters (?p - cell ?n1 - cell ?s1 - side ?s1op - side)
  :precondition (and (neighbour ?s1 ?n1 ?p)
                     (neighbour ?s1op ?p ?n1)
                     (request ?p ?s1)
                     (accept ?n1 ?s1op)
                     (newjob ?p)
                     (not (available ?p))
                     (not (sending ?p left))
                     (not (sending ?p right))
                     (not (sending ?p up))
                     (not (sending ?p down)))
  :effect (and (sending ?p ?s1))
 )

 ;; ===========================================
 ;; receive job from neighbour
 ;; ===========================================


 (:action control-recv
  :parameters (?p - cell ?n1 - cell ?s1 - side ?s1op - side)
  :precondition (and (proc ?p)
                     (neighbour ?s1 ?n1 ?p)
                     (neighbour ?s1op ?p ?n1)
                     (sending ?n1 ?s1op)
                     (not (recd ?p ?s1))
                     (not (newjob ?p)))
  :effect (and (newjob ?p)
               (recd ?p ?s1))
 )

 ;; ===========================================
 ;; mark receive job from neighbour
 ;; ===========================================

 (:action control-mark-sent
  :parameters (?p - cell ?n1 - cell ?s1 - side ?s1op - side)
  :precondition (and (proc ?n1)
                     (neighbour ?s1 ?n1 ?p)
                     (neighbour ?s1op ?p ?n1)
                     (sending ?p ?s1)
                     (recd ?n1 ?s1op))
  :effect (and (not (newjob ?p))
               (not (sending ?p ?s1))
               (not (request ?p left))
               (not (request ?p right))
               (not (request ?p up))
               (not (request ?p down))
               (not (accept ?p left))
               (not (accept ?p right))
               (not (accept ?p up))
               (not (accept ?p down))
               (not (reject ?p left))
               (not (reject ?p right))
               (not (reject ?p up))
               (not (reject ?p down)))
 )

 ;; ================================
 ;; termination of job send protocol
 ;; ================================


 (:action control-finish-recd
  :parameters (?p - cell ?n1 - cell ?s1 - side ?s1op - side)
  :precondition (and (proc ?p)
                     (neighbour ?s1 ?n1 ?p)
                     (neighbour ?s1op ?p ?n1)
                     (not (sending ?n1 ?s1op))
                     (recd ?p ?s1))
  :effect (and (not (recd ?p ?s1)))
 )


 (:action control-lost-request
  :parameters (?p - cell ?n1 - cell ?s1 - side ?s1op - side)
  :precondition (and (proc ?p)
                     (neighbour ?s1 ?n1 ?p)
                     (neighbour ?s1op ?p ?n1)
                     (request ?p ?s1op)
                     (not (request ?p ?s1)) ;; These two conditions ensure
                                            ;; that n1 is parent for request.
                     (not (request ?n1 ?s1op)) ;; i.e. request has been lost.
                     (not (newjob ?p))
                     )
  :effect (and (not (request ?p left))
               (not (request ?p right))
               (not (request ?p up))
               (not (request ?p down))
               (not (accept ?p left))
               (not (accept ?p right))
               (not (accept ?p up))
               (not (accept ?p down))
               (not (reject ?p left))
               (not (reject ?p right))
               (not (reject ?p up))
               (not (reject ?p down)))
 )

 (:action control-lost-accepted-request
  :parameters (?p - cell ?n1 - cell ?s1 - side ?s1op - side)
  :precondition (and (proc ?p)
                     (neighbour ?s1 ?n1 ?p)
                     (neighbour ?s1op ?p ?n1)
                     (accept ?p ?s1) ;; accepted
                     (not (request ?n1 ?s1op)) ;; but request has been lost.
                     (not (newjob ?p))
                     )
  :effect (and (not (request ?p left))
               (not (request ?p right))
               (not (request ?p up))
               (not (request ?p down))
               (not (accept ?p left))
               (not (accept ?p right))
               (not (accept ?p up))
               (not (accept ?p down))
               (not (reject ?p left))
               (not (reject ?p right))
               (not (reject ?p up))
               (not (reject ?p down)))
 )


 ;; ========================================
 ;; =========== taking up new job ==============
 ;; ========================================

 (:action control-newjob-get-busy
  :parameters (?c - cell)
  :precondition (and (proc ?c)
                     (newjob ?c)
                     (not (recd ?c left))
                     (available ?c))
  :effect (and (not (newjob ?c))
               (busy ?c))
 )

 ;; ========================================
 ;; =========== environment actions below ======
 ;; ========================================

 (:action env-create-newjob-dispenser-1
  :parameters (?d - cell ?n1 - cell ?s1 - side)
  :precondition (and (dispenser ?d)
                     (neighbour ?s1 ?n1 ?d)
                     (not (newjob ?d))
                     (not (job0)))
  :effect (and (job0)
               (request ?d ?s1)
               (newjob ?d))
 )

 (:action env-create-newjob-dispenser-2
  :parameters (?d - cell ?n1 - cell ?s1 - side)
  :precondition (and (dispenser ?d)
                     (neighbour ?s1 ?n1 ?d)
                     (not (newjob ?d))
                     (job0)
                     (not (job1)))
  :effect (and (job1)
               (request ?d ?s1)
               (newjob ?d))
 )

 (:action env-create-newjob-dispenser-3
  :parameters (?d - cell ?n1 - cell ?s1 - side)
  :precondition (and (dispenser ?d)
                     (neighbour ?s1 ?n1 ?d)
                     (not (newjob ?d))
                     (job1)
                     (not (job2)))
  :effect (and (job2)
               (request ?d ?s1)
               (newjob ?d))
 )

 (:action env-create-newjob-dispenser-4
  :parameters (?d - cell ?n1 - cell ?s1 - side)
  :precondition (and (dispenser ?d)
                     (neighbour ?s1 ?n1 ?d)
                     (not (newjob ?d))
                     (job2)
                     (not (job3)))
  :effect (and (job3)
               (request ?d ?s1)
               (newjob ?d))
 )

 (:action env-create-newjob-dispenser-5
  :parameters (?d - cell ?n1 - cell ?s1 - side)
  :precondition (and (dispenser ?d)
                     (neighbour ?s1 ?n1 ?d)
                     (not (newjob ?d))
                     (job3)
                     (not (job4)))
  :effect (and (job4)
               (request ?d ?s1)
               (newjob ?d))
 )

 (:action env-create-newjob-dispenser-6
  :parameters (?d - cell ?n1 - cell ?s1 - side)
  :precondition (and (dispenser ?d)
                     (neighbour ?s1 ?n1 ?d)
                     (not (newjob ?d))
                     (job4)
                     (not (job5)))
  :effect (and (job5)
               (request ?d ?s1)
               (newjob ?d))
 )

 (:action env-create-newjob-dispenser-7
  :parameters (?d - cell ?n1 - cell ?s1 - side)
  :precondition (and (dispenser ?d)
                     (neighbour ?s1 ?n1 ?d)
                     (not (newjob ?d))
                     (job5)
                     (not (job6)))
  :effect (and (job6)
               (request ?d ?s1)
               (newjob ?d))
 )

 (:action env-create-newjob-dispenser-8
  :parameters (?d - cell ?n1 - cell ?s1 - side)
  :precondition (and (dispenser ?d)
                     (neighbour ?s1 ?n1 ?d)
                     (not (newjob ?d))
                     (job6)
                     (not (job7)))
  :effect (and (job7)
               (request ?d ?s1)
               (newjob ?d))
 )

 (:action env-create-newjob-dispenser-9
  :parameters (?d - cell ?n1 - cell ?s1 - side)
  :precondition (and (dispenser ?d)
                     (neighbour ?s1 ?n1 ?d)
                     (not (newjob ?d))
                     (job7)
                     (not (job8)))
  :effect (and (job8)
               (request ?d ?s1)
               (newjob ?d))
 )

 (:action env-create-newjob-dispenser-10
  :parameters (?d - cell ?n1 - cell ?s1 - side)
  :precondition (and (dispenser ?d)
                     (neighbour ?s1 ?n1 ?d)
                     (not (newjob ?d))
                     (job8)
                     (not (job9)))
  :effect (and (job9)
               (request ?d ?s1)
               (newjob ?d))
 )

 (:action env-create-newjob-dispenser-11
  :parameters (?d - cell ?n1 - cell ?s1 - side)
  :precondition (and (dispenser ?d)
                     (neighbour ?s1 ?n1 ?d)
                     (not (newjob ?d))
                     (job9)
                     (not (job10)))
  :effect (and (job10)
               (request ?d ?s1)
               (newjob ?d))
 )

 (:action env-create-newjob-dispenser-12
  :parameters (?d - cell ?n1 - cell ?s1 - side)
  :precondition (and (dispenser ?d)
                     (neighbour ?s1 ?n1 ?d)
                     (not (newjob ?d))
                     (job10)
                     (not (job11)))
  :effect (and (job11)
               (request ?d ?s1)
               (newjob ?d))
 )

 (:action env-create-newjob-dispenser-13
  :parameters (?d - cell ?n1 - cell ?s1 - side)
  :precondition (and (dispenser ?d)
                     (neighbour ?s1 ?n1 ?d)
                     (not (newjob ?d))
                     (job11)
                     (not (job12)))
  :effect (and (job12)
               (request ?d ?s1)
               (newjob ?d))
 )

 (:action env-create-newjob-dispenser-14
  :parameters (?d - cell ?n1 - cell ?s1 - side)
  :precondition (and (dispenser ?d)
                     (neighbour ?s1 ?n1 ?d)
                     (not (newjob ?d))
                     (job12)
                     (not (job13)))
  :effect (and (job13)
               (request ?d ?s1)
               (newjob ?d))
 )

 (:action env-create-newjob-dispenser-15
  :parameters (?d - cell ?n1 - cell ?s1 - side)
  :precondition (and (dispenser ?d)
                     (neighbour ?s1 ?n1 ?d)
                     (not (newjob ?d))
                     (job13)
                     (not (job14)))
  :effect (and (job14)
               (request ?d ?s1)
               (newjob ?d))
 )

 ;; ======= finish job ===

 (:action env-finish-job-14
  :parameters (?c - cell)
  :precondition (and (proc ?c)
                     (job14)
                     (busy ?c))
  :effect (and (not (job14))
               (not (busy ?c)))
 )

 (:action env-finish-newjob-13
  :parameters (?c - cell)
  :precondition (and (proc ?c)
                     (not (job14))
                     (job13)
                     (busy ?c))
  :effect (and (not (job13))
               (not (busy ?c)))
 )

 (:action env-finish-newjob-12
  :parameters (?c - cell)
  :precondition (and (proc ?c)
                     (not (job13))
                     (job12)
                     (busy ?c))
  :effect (and (not (job12))
               (not (busy ?c)))
 )

 (:action env-finish-newjob-11
  :parameters (?c - cell)
  :precondition (and (proc ?c)
                     (not (job12))
                     (job11)
                     (busy ?c))
  :effect (and (not (job11))
               (not (busy ?c)))
 )

 (:action env-finish-newjob-10
  :parameters (?c - cell)
  :precondition (and (proc ?c)
                     (not (job11))
                     (job10)
                     (busy ?c))
  :effect (and (not (job10))
               (not (busy ?c)))
 )

 (:action env-finish-newjob-9
  :parameters (?c - cell)
  :precondition (and (proc ?c)
                     (not (job10))
                     (job9)
                     (busy ?c))
  :effect (and (not (job9))
               (not (busy ?c)))
 )

 (:action env-finish-newjob-8
  :parameters (?c - cell)
  :precondition (and (proc ?c)
                     (not (job9))
                     (job8)
                     (busy ?c))
  :effect (and (not (job8))
               (not (busy ?c)))
 )

 (:action env-finish-newjob-7
  :parameters (?c - cell)
  :precondition (and (proc ?c)
                     (not (job8))
                     (job7)
                     (busy ?c))
  :effect (and (not (job7))
               (not (busy ?c)))
 )

 (:action env-finish-newjob-6
  :parameters (?c - cell)
  :precondition (and (proc ?c)
                     (not (job7))
                     (job6)
                     (busy ?c))
  :effect (and (not (job6))
               (not (busy ?c)))
 )

 (:action env-finish-newjob-5
  :parameters (?c - cell)
  :precondition (and (proc ?c)
                     (not (job6))
                     (job5)
                     (busy ?c))
  :effect (and (not (job5))
               (not (busy ?c)))
 )

 (:action env-finish-newjob-4
  :parameters (?c - cell)
  :precondition (and (proc ?c)
                     (not (job5))
                     (job4)
                     (busy ?c))
  :effect (and (not (job4))
               (not (busy ?c)))
 )

 (:action env-finish-newjob-3
  :parameters (?c - cell)
  :precondition (and (proc ?c)
                     (not (job4))
                     (job3)
                     (busy ?c))
  :effect (and (not (job3))
               (not (busy ?c)))
 )

 (:action env-finish-newjob-2
  :parameters (?c - cell)
  :precondition (and (proc ?c)
                     (not (job3))
                     (job2)
                     (busy ?c))
  :effect (and (not (job2))
               (not (busy ?c)))
 )

 (:action env-finish-newjob-1
  :parameters (?c - cell)
  :precondition (and (proc ?c)
                     (not (job2))
                     (job1)
                     (busy ?c))
  :effect (and (not (job1))
               (not (busy ?c)))
 )

 (:action env-finish-newjob-0
  :parameters (?c - cell)
  :precondition (and (proc ?c)
                     (not (job1))
                     (job0)
                     (busy ?c))
  :effect (and (not (job0))
               (not (busy ?c)))
 )

)

