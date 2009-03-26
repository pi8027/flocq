Require Import Flocq_Raux.
Require Import Flocq_defs.
Require Import Flocq_rnd_ex.

Section RND_generic.

Variable beta : radix.

Notation bpow := (epow beta).

Variable fexp : Z -> Z.

Variable valid_fexp :
 forall k : Z,
 ( (fexp k < k)%Z -> (fexp (k + 1) <= k)%Z ) /\
 ( (k <= fexp k)%Z ->
   (fexp (fexp k + 1) <= fexp k)%Z /\
   forall l : Z, (l <= fexp k)%Z -> fexp l = fexp k ).

Definition generic_format (x : R) :=
  exists f : float beta,
  x = F2R f /\ (x = R0 \/
  forall H: (0 < Rabs x)%R, Fexp f = fexp (projT1 (ln_beta beta _ H))).

Theorem generic_format_satisfies_any :
  satisfies_any generic_format.
Proof.
refine ((fun D => Satisfies_any _ _ _ (projT1 D) (projT2 D)) _).
(* symmetric set *)
exists (Float beta 0 0).
split.
unfold F2R.
now rewrite Rmult_0_l.
now left.
intros x ((m,e),(H1,H2)).
exists (Float beta (-m) e).
split.
rewrite H1.
unfold F2R.
simpl.
now rewrite opp_Z2R, Ropp_mult_distr_l_reverse.
destruct H2.
left.
rewrite H.
now rewrite Ropp_0.
right.
rewrite Rabs_Ropp.
intros H0.
specialize (H H0).
now rewrite <- H.
(* rounding down *)
assert (Hxx : forall x, (0 > x)%R -> (0 < -x)%R).
intros.
now apply Ropp_0_gt_lt_contravar.
exists (fun x =>
  match total_order_T 0 x with
  | inleft (left Hx) =>
    let e := fexp (projT1 (ln_beta beta _ Hx)) in
    F2R (Float beta (up (x * bpow (Zopp e)) - 1) e)
  | inleft (right _) => R0
  | inright Hx =>
    let e := fexp (projT1 (ln_beta beta _ (Hxx _ Hx))) in
    F2R (Float beta (up (x * bpow (Zopp e)) - 1) e)
  end).
intros x.
destruct (total_order_T 0 x) as [[Hx|Hx]|Hx].
(* positive *)
clear Hxx.
destruct (ln_beta beta x Hx) as (ex, (Hx1, Hx2)).
simpl.
destruct (Z_lt_le_dec (fexp ex) ex) as [He1|He1].
(* - positive big enough *)
assert (Hbl : (bpow (ex - 1)%Z <= F2R (Float beta (up (x * bpow (- fexp ex)%Z) - 1) (fexp ex)))%R).
(* - . bounded left *)
clear Hx2.
unfold F2R.
simpl.
replace (ex - 1)%Z with ((ex - 1 - fexp ex) + fexp ex)%Z by ring.
rewrite epow_add.
apply Rmult_le_compat_r.
apply epow_ge_0.
assert (bpow (ex - 1 - fexp ex)%Z < Z2R (up (x * bpow (- fexp ex)%Z)))%R.
rewrite Z2R_IZR.
apply Rle_lt_trans with (2 := proj1 (archimed _)).
unfold Zminus.
rewrite epow_add.
apply Rmult_le_compat_r.
apply epow_ge_0.
exact Hx1.
case_eq (ex - 1 - fexp ex)%Z.
intros He2.
change (bpow 0%Z) with (Z2R 1).
apply Z2R_le.
change 1%Z at 1 with (1 + 1 - 1)%Z.
apply Zplus_le_compat_r.
apply (Zlt_le_succ 1).
apply lt_Z2R.
now rewrite He2 in H.
intros ep He2.
simpl.
apply Z2R_le.
replace (Zpower_pos (radix_val beta) ep) with (Zpower_pos (radix_val beta) ep + 1 - 1)%Z by ring.
apply Zplus_le_compat_r.
apply Zlt_le_succ.
apply lt_Z2R.
change (bpow (Zpos ep) < Z2R (up (x * bpow (- fexp ex)%Z)))%R.
now rewrite <- He2.
clear H Hx1.
intros.
assert (ex - 1 - fexp ex < 0)%Z.
now rewrite H.
apply False_ind.
omega.
split.
(* - . rounded *)
eexists ; split ; [ reflexivity | right ].
intros He9.
simpl.
apply f_equal.
apply sym_eq.
apply ln_beta_unique.
clear He9.
rewrite Rabs_right.
split.
exact Hbl.
(* - . . bounded right *)
clear Hbl.
apply Rle_lt_trans with (2 := Hx2).
unfold F2R.
simpl.
pattern x at 2 ; replace x with ((x * bpow (- fexp ex)%Z) * bpow (fexp ex))%R.
generalize (x * bpow (- fexp ex)%Z)%R.
clear.
intros x.
apply Rmult_le_compat_r.
apply epow_ge_0.
rewrite minus_Z2R.
rewrite Z2R_IZR.
simpl.
apply Rplus_le_reg_l with (- x + 1)%R.
ring_simplify.
rewrite Rplus_comm.
exact (proj2 (archimed x)).
rewrite Rmult_assoc.
rewrite <- epow_add.
rewrite Zplus_opp_l.
apply Rmult_1_r.
(* - . . *)
apply Rle_ge.
apply Rle_trans with (2 := Hbl).
apply epow_ge_0.
split.
(* - . smaller *)
unfold F2R.
simpl.
generalize (fexp ex).
clear.
intros e.
pattern x at 2 ; rewrite <- Rmult_1_r.
change R1 with (bpow Z0).
rewrite <- (Zplus_opp_l e).
rewrite epow_add, <- Rmult_assoc.
apply Rmult_le_compat_r.
apply epow_ge_0.
rewrite minus_Z2R.
rewrite Z2R_IZR.
simpl.
apply Rplus_le_reg_l with (1 - x * bpow (-e)%Z)%R.
ring_simplify.
rewrite Rplus_comm.
rewrite Ropp_mult_distr_l_reverse.
exact (proj2 (archimed _)).
(* - . biggest *)
intros g ((gm, ge), (Hg1, Hg2)) Hgx.
destruct (Rle_or_lt g R0) as [Hg3|Hg3].
apply Rle_trans with (2 := Hbl).
apply Rle_trans with (1 := Hg3).
apply epow_ge_0.
destruct Hg2 as [Hg2|Hg2].
rewrite Hg2 in Hg3.
elim (Rlt_irrefl _ Hg3).
rewrite (Rabs_pos_eq _ (Rlt_le _ _ Hg3)) in Hg2.
specialize (Hg2 Hg3).
apply Rnot_lt_le.
intros Hrg.
assert (bpow (ex - 1)%Z <= g < bpow ex)%R.
split.
apply Rle_trans with (1 := Hbl).
now apply Rlt_le.
now apply Rle_lt_trans with (1 := Hgx).
rewrite ln_beta_unique with (1 := H) in Hg2.
simpl in Hg2.
apply Rlt_not_le with (1 := Hrg).
rewrite Hg1, Hg2.
unfold F2R. simpl.
apply Rmult_le_compat_r.
apply epow_ge_0.
apply Z2R_le.
cut (gm < up (x * bpow (- fexp ex)%Z))%Z.
omega.
apply lt_IZR.
apply Rle_lt_trans with (2 := proj1 (archimed _)).
apply Rmult_le_reg_r with (bpow (fexp ex)).
apply epow_gt_0.
rewrite <- Hg2 at 1.
rewrite <- Z2R_IZR.
rewrite Rmult_assoc.
rewrite <- epow_add.
rewrite Zplus_opp_l.
rewrite Rmult_1_r.
unfold F2R in Hg1.
simpl in Hg1.
now rewrite <- Hg1.
(* - positive too small *)
cutrewrite (up (x * bpow (- fexp ex)%Z) = 1%Z).
(* - . rounded *)
unfold F2R. simpl.
rewrite Rmult_0_l.
split.
exists (Float beta Z0 (fexp ex)).
split.
unfold F2R. simpl.
now rewrite Rmult_0_l.
now left.
split.
now apply Rlt_le.
(* - . biggest *)
intros g ((gm, ge), (Hg1, Hg2)) Hgx.
apply Rnot_lt_le.
intros Hg3.
destruct Hg2 as [Hg2|Hg2].
rewrite Hg2 in Hg3.
elim (Rlt_irrefl _ Hg3).
rewrite (Rabs_pos_eq _ (Rlt_le _ _ Hg3)) in Hg2.
specialize (Hg2 Hg3).
destruct (ln_beta beta g Hg3) as (ge', Hg4).
simpl in Hg2.
apply (Rlt_not_le _ _ (Rle_lt_trans _ _ _ Hgx Hx2)).
apply Rle_trans with (bpow ge).
apply -> epow_le.
rewrite Hg2.
rewrite (proj2 (proj2 (valid_fexp ex) He1) ge').
exact He1.
apply Zle_trans with (2 := He1).
cut (ge' - 1 < ex)%Z.
omega.
apply <- epow_lt.
apply Rle_lt_trans with (2 := Hx2).
apply Rle_trans with (2 := Hgx).
exact (proj1 Hg4).
rewrite Hg1.
unfold F2R. simpl.
pattern (bpow ge) at 1 ; rewrite <- Rmult_1_l.
apply Rmult_le_compat_r.
apply epow_ge_0.
apply (Z2R_le 1).
apply (Zlt_le_succ 0).
apply lt_Z2R.
apply Rmult_lt_reg_r with (bpow ge).
apply epow_gt_0.
rewrite Rmult_0_l.
unfold F2R in Hg1. simpl in Hg1.
now rewrite <- Hg1.
(* - . . *)
apply sym_eq.
rewrite <- (Zplus_0_l 1).
apply up_tech.
apply Rlt_le.
apply Rmult_lt_0_compat.
exact Hx.
apply epow_gt_0.
change (IZR (0 + 1)) with (bpow Z0).
rewrite <- (Zplus_opp_r (fexp ex)).
rewrite epow_add.
apply Rmult_lt_compat_r.
apply epow_gt_0.
apply Rlt_le_trans with (1 := Hx2).
now apply -> epow_le.
(* zero *)
split.
exists (Float beta 0 0).
split.
unfold F2R.
now rewrite Rmult_0_l.
now left.
rewrite <- Hx.
split.
apply Rle_refl.
intros g _ H.
exact H.
(* negative *)
destruct (ln_beta beta (- x) (Hxx x Hx)) as (ex, (Hx1, Hx2)).
simpl.
clear Hxx.
assert (Hbr : (F2R (Float beta (up (x * bpow (- fexp ex)%Z) - 1) (fexp ex)) <= x)%R).
(* - bounded right *)
unfold F2R. simpl.
pattern x at 2 ; rewrite <- Rmult_1_r.
change R1 with (bpow Z0).
rewrite <- (Zplus_opp_l (fexp ex)).
rewrite epow_add.
rewrite <- Rmult_assoc.
generalize (x * bpow (- fexp ex)%Z)%R.
clear.
intros x.
apply Rmult_le_compat_r.
apply epow_ge_0.
rewrite minus_Z2R.
simpl.
rewrite Z2R_IZR.
apply Rplus_le_reg_l with (-x + 1)%R.
ring_simplify.
rewrite Rplus_comm.
exact (proj2 (archimed x)).
destruct (Z_lt_le_dec (fexp ex) ex) as [He1|He1].
(* - negative big enough *)
assert (Hbl : (- bpow ex <= F2R (Float beta (up (x * bpow (- fexp ex)%Z) - 1) (fexp ex)))%R).
(* - . bounded left *)
unfold F2R. simpl.
pattern ex at 1 ; replace ex with (ex - fexp ex + fexp ex)%Z by ring.
rewrite epow_add.
rewrite <- Ropp_mult_distr_l_reverse.
apply Rmult_le_compat_r.
apply epow_ge_0.
cut (0 < ex - fexp ex)%Z. 2: omega.
case_eq (ex - fexp ex)%Z ; try (intros ; discriminate H0).
intros ep Hp _.
simpl.
rewrite <- opp_Z2R.
apply Z2R_le.
cut (- Zpower_pos (radix_val beta) ep < up (x * bpow (- fexp ex)%Z))%Z.
omega.
apply lt_Z2R.
apply Rle_lt_trans with (x * bpow (- fexp ex)%Z)%R.
rewrite opp_Z2R.
change (- bpow (Zpos ep) <= x * bpow (- fexp ex)%Z)%R.
rewrite <- Hp.
apply Rmult_le_reg_r with (bpow (fexp ex)).
apply epow_gt_0.
rewrite Rmult_assoc.
rewrite <- epow_add.
rewrite Zplus_opp_l.
rewrite Rmult_1_r.
rewrite Ropp_mult_distr_l_reverse.
rewrite <- epow_add.
replace (ex - fexp ex + fexp ex)%Z with ex by ring.
rewrite <- (Ropp_involutive x).
apply Ropp_le_contravar.
now apply Rlt_le.
rewrite Z2R_IZR.
exact (proj1 (archimed _)).
split.
(* - . rounded *)
destruct (Rle_lt_or_eq_dec _ _ Hbl) as [Hbl2|Hbl2].
(* - . . not a radix power *)
eexists ; split ; [ reflexivity | idtac ].
right.
rewrite Rabs_left.
intros Hr.
simpl.
apply f_equal.
apply sym_eq.
apply ln_beta_unique.
split.
rewrite <- (Ropp_involutive (bpow (ex - 1)%Z)).
apply Ropp_le_contravar.
apply Rle_trans with (1 := Hbr).
rewrite <- (Ropp_involutive x).
now apply Ropp_le_contravar.
rewrite <- (Ropp_involutive (bpow ex)).
now apply Ropp_lt_contravar.
apply Rle_lt_trans with (1 := Hbr).
exact Hx.
(* - . . a radix power *)
rewrite <- Hbl2.
generalize (proj1 (valid_fexp _) He1).
clear.
intros He2.
exists (Float beta (- Zpower (radix_val beta) (ex - fexp (ex + 1))) (fexp (ex + 1))).
unfold F2R. simpl.
split.
clear -He2.
pattern ex at 1 ; replace ex with (ex - fexp (ex + 1) + fexp (ex + 1))%Z by ring.
rewrite epow_add.
rewrite <- Ropp_mult_distr_l_reverse.
rewrite opp_Z2R.
apply (f_equal (fun x => (- x * _)%R)).
cut (0 <= ex - fexp (ex + 1))%Z. 2: omega.
case (ex - fexp (ex + 1))%Z ; trivial.
intros ep H.
now elim H.
right.
rewrite Rabs_Ropp.
rewrite Rabs_right.
intros H9.
apply f_equal.
apply sym_eq.
apply ln_beta_unique.
split.
apply -> epow_le.
omega.
apply -> epow_lt.
apply Zlt_succ.
apply Rle_ge.
apply epow_ge_0.
split.
exact Hbr.
(* - . biggest *)
intros g ((gm, ge), (Hg1, Hg2)) Hgx.
apply Rnot_lt_le.
intros Hg3.
assert (Hg4 : (g < 0)%R).
now apply Rle_lt_trans with (1 := Hgx).
destruct Hg2 as [Hg2|Hg2].
rewrite Hg2 in Hg4.
elim (Rlt_irrefl _ Hg4).
rewrite (Rabs_left _ Hg4) in Hg2.
assert (Hg5 := Ropp_0_gt_lt_contravar _ Hg4).
specialize (Hg2 Hg5).
simpl in Hg2.
destruct (ln_beta beta (- g) Hg5) as (ge', Hge).
simpl in Hg2.
apply Rlt_not_le with (1 := Hg3).
rewrite Hg1.
unfold F2R. simpl.
rewrite Hg2.
assert (Hge' : ge' = ex).
apply epow_unique with (1 := Hge).
split.
apply Rle_trans with (1 := Hx1).
now apply Ropp_le_contravar.
apply Ropp_lt_cancel.
apply Rle_lt_trans with (1 := Hbl).
now rewrite Ropp_involutive.
rewrite Hge'.
apply Rmult_le_compat_r.
apply epow_ge_0.
apply Z2R_le.
cut (gm < up (x * bpow (- fexp ex)%Z))%Z.
omega.
apply lt_IZR.
apply Rle_lt_trans with (2 := proj1 (archimed _)).
rewrite <- Z2R_IZR.
apply Rmult_le_reg_r with (bpow (fexp ex)).
apply epow_gt_0.
rewrite Rmult_assoc.
rewrite <- epow_add.
rewrite Zplus_opp_l.
rewrite Rmult_1_r.
rewrite <- Hge'.
rewrite <- Hg2.
unfold F2R in Hg1. simpl in Hg1.
now rewrite <- Hg1.
(* - negative too small *)
cutrewrite (up (x * bpow (- fexp ex)%Z) = 0%Z).
unfold F2R. simpl.
rewrite Ropp_mult_distr_l_reverse.
rewrite Rmult_1_l.
(* - . rounded *)
split.
destruct (proj2 (valid_fexp _) He1) as (He2, _).
exists (Float beta (- Zpower (radix_val beta) (fexp ex - fexp (fexp ex + 1))) (fexp (fexp ex + 1))).
unfold F2R. simpl.
split.
rewrite opp_Z2R.
pattern (fexp ex) at 1 ; replace (fexp ex) with (fexp ex - fexp (fexp ex + 1) + fexp (fexp ex + 1))%Z by ring.
rewrite epow_add.
rewrite Ropp_mult_distr_l_reverse.
apply (f_equal (fun x => (- (x * _))%R)).
cut (0 <= fexp ex - fexp (fexp ex + 1))%Z. 2: omega.
clear.
case (fexp ex - fexp (fexp ex + 1))%Z ; trivial.
intros ep Hp.
now elim Hp.
right.
rewrite Rabs_Ropp.
rewrite Rabs_right.
intros H9.
apply f_equal.
apply sym_eq.
apply ln_beta_unique.
split.
replace (fexp ex + 1 - 1)%Z with (fexp ex) by ring.
apply Rle_refl.
apply -> epow_lt.
apply Zlt_succ.
apply Rle_ge.
apply epow_ge_0.
split.
(* - . smaller *)
rewrite <- (Ropp_involutive x).
apply Ropp_le_contravar.
apply Rlt_le.
apply Rlt_le_trans with (1 := Hx2).
now apply -> epow_le.
(* - . biggest *)
intros g ((gm, ge), (Hg1, Hg2)) Hgx.
apply Rnot_lt_le.
intros Hg3.
assert (Hg4 : (g < 0)%R).
now apply Rle_lt_trans with (1 := Hgx).
destruct Hg2 as [Hg2|Hg2].
rewrite Hg2 in Hg4.
elim (Rlt_irrefl _ Hg4).
rewrite (Rabs_left _ Hg4) in Hg2.
assert (Hg5 := Ropp_0_gt_lt_contravar _ Hg4).
specialize (Hg2 Hg5).
simpl in Hg2.
destruct (ln_beta beta (- g) Hg5) as (ge', Hge).
simpl in Hg2.
assert (Hge' : (ge' <= fexp ex)%Z).
cut (ge' - 1 < fexp ex)%Z. omega.
apply <- epow_lt.
apply Rle_lt_trans with (1 := proj1 Hge).
apply Ropp_lt_cancel.
now rewrite Ropp_involutive.
rewrite (proj2 (proj2 (valid_fexp _) He1) _ Hge') in Hg2.
rewrite <- Hg2 in Hge'.
apply Rlt_not_le with (1 := proj2 Hge).
rewrite Hg1.
unfold F2R. simpl.
rewrite <- Ropp_mult_distr_l_reverse.
replace ge with (ge - ge' + ge')%Z by ring.
rewrite epow_add.
rewrite <- Rmult_assoc.
pattern (bpow ge') at 1 ; rewrite <- Rmult_1_l.
apply Rmult_le_compat_r.
apply epow_ge_0.
rewrite <- opp_Z2R.
assert (1 <= -gm)%Z.
apply (Zlt_le_succ 0).
apply lt_Z2R.
apply Rmult_lt_reg_r with (bpow ge).
apply epow_gt_0.
rewrite Rmult_0_l.
rewrite opp_Z2R.
rewrite Ropp_mult_distr_l_reverse.
unfold F2R in Hg1. simpl in Hg1.
now rewrite <- Hg1.
apply Rle_trans with (1 * bpow (ge - ge')%Z)%R.
rewrite Rmult_1_l.
cut (0 <= ge - ge')%Z. 2: omega.
clear.
case (ge - ge')%Z.
intros _.
apply Rle_refl.
intros ep _.
simpl.
apply (Z2R_le 1).
apply (Zlt_le_succ 0).
apply Zpower_pos_lt.
now apply Zlt_le_trans with (2 := radix_prop beta).
intros ep Hp. now elim Hp.
apply Rmult_le_compat_r.
apply epow_ge_0.
now apply (Z2R_le 1).
(* - . . *)
apply sym_eq.
apply (up_tech _ (-1)).
apply Ropp_le_cancel.
simpl.
rewrite Ropp_involutive.
change R1 with (bpow Z0).
rewrite <- (Zplus_opp_r (fexp ex)).
rewrite epow_add.
rewrite <- Ropp_mult_distr_l_reverse.
apply Rmult_le_compat_r.
apply epow_ge_0.
apply Rlt_le.
apply Rlt_le_trans with (1 := Hx2).
now apply -> epow_le.
simpl.
rewrite <- (Rmult_0_l (bpow (- fexp ex)%Z)).
apply Rmult_lt_compat_r.
apply epow_gt_0.
exact Hx.
Qed.

End RND_generic.