Require Import Fcore.

Section Fcalc_digits.

Variable beta : radix.
Notation bpow e := (bpow beta e).

Variable fexp : Z -> Z.
Hypothesis prop_exp : valid_exp fexp.
Notation format := (generic_format beta fexp).

Fixpoint digits2_Pnat (n : positive) : nat :=
  match n with
  | xH => O
  | xO p => S (digits2_Pnat p)
  | xI p => S (digits2_Pnat p)
  end.

Theorem digits2_Pnat_correct :
  forall n,
  let d := digits2_Pnat n in
  (Zpower_nat 2 d <= Zpos n < Zpower_nat 2 (S d))%Z.
Proof.
intros n d. unfold d. clear.
assert (Hp: forall m, (Zpower_nat 2 (S m) = 2 * Zpower_nat 2 m)%Z) by easy.
induction n ; simpl.
rewrite Zpos_xI, 2!Hp.
omega.
rewrite (Zpos_xO n), 2!Hp.
omega.
now split.
Qed.

Section digits_aux.

Variable p : Z.
Hypothesis Hp : (0 <= p)%Z.

Fixpoint digits_aux (nb pow : Z) (n : nat) { struct n } : Z :=
  match n with
  | O => nb
  | S n => if Zlt_bool p pow then nb else digits_aux (nb + 1) (Zmult (radix_val beta) pow) n
  end.

Lemma digits_aux_invariant :
  forall k n nb,
  (0 <= nb)%Z ->
  (Zpower (radix_val beta) (nb + Z_of_nat k - 1) <= p)%Z ->
  digits_aux (nb + Z_of_nat k) (Zpower (radix_val beta) (nb + Z_of_nat k)) n =
  digits_aux nb (Zpower (radix_val beta) nb) (n + k).
Proof.
induction k ; intros n nb Hnb.
now rewrite Zplus_0_r, plus_0_r.
rewrite inj_S.
unfold Zsucc.
intros H.
rewrite (Zplus_comm _ 1), Zplus_assoc.
rewrite IHk.
rewrite <- plus_n_Sm.
simpl.
generalize (Zlt_cases p (Zpower (radix_val beta) nb)).
case Zlt_bool ; intros Hpp.
elim (Zlt_irrefl p).
apply Zlt_le_trans with (1 := Hpp).
apply Zle_trans with (2 := H).
replace (nb + (Z_of_nat k + 1) - 1)%Z with (nb + Z_of_nat k)%Z by ring.
apply le_Z2R.
rewrite Z2R_Zpower with (1 := Hnb).
rewrite Z2R_Zpower.
apply -> bpow_le.
omega.
omega.
rewrite Zpower_exp.
unfold Zpower at 2, Zpower_pos, iter_pos.
rewrite Zmult_1_r.
now rewrite Zmult_comm.
now apply Zle_ge.
easy.
omega.
now rewrite <- Zplus_assoc, (Zplus_comm 1).
Qed.

End digits_aux.

Definition digits n :=
  match n with
  | Z0 => Z0
  | Zneg p => digits_aux (Zpos p) 1 (radix_val beta) (digits2_Pnat p)
  | Zpos p => digits_aux n 1 (radix_val beta) (digits2_Pnat p)
  end.

Theorem digits_abs :
  forall n, digits (Zabs n) = digits n.
Proof.
now intros [|n|n].
Qed.

Theorem digits_ln_beta :
  forall n,
  n <> Z0 ->
  digits n = projT1 (ln_beta beta (Z2R n)).
Proof.
intros n Hn.
destruct (ln_beta beta (Z2R n)) as (e, He).
simpl.
specialize (He (Z2R_neq _ _ Hn)).
rewrite <- abs_Z2R in He.
assert (Hn': (0 < Zabs n)%Z).
destruct n ; try easy.
now elim Hn.
rewrite <- digits_abs.
destruct (Zabs n) as [|p|p] ; try (now elim Hn').
clear n Hn Hn'.
simpl.
assert (He1: (0 <= e - 1)%Z).
apply Zlt_0_le_0_pred.
apply <- bpow_lt.
apply Rle_lt_trans with (2 := proj2 He).
apply (Z2R_le 1).
now apply (Zlt_le_succ 0).
assert (He2: (Z_of_nat (Zabs_nat (e - 1)) = e - 1)%Z).
rewrite inj_Zabs_nat.
now apply Zabs_eq.
replace (radix_val beta) with (Zpower (radix_val beta) 1).
replace (digits2_Pnat p) with (digits2_Pnat p - Zabs_nat (e - 1) + Zabs_nat (e - 1)).
rewrite <- digits_aux_invariant.
rewrite He2.
ring_simplify (1 + (e - 1))%Z.
destruct (digits2_Pnat p - Zabs_nat (e - 1)) as [|n].
easy.
simpl.
generalize (Zlt_cases (Zpos p) (Zpower (radix_val beta) e)).
case Zlt_bool ; intros Hpp.
easy.
elim Rlt_not_le with (1 := proj2 He).
rewrite <- Z2R_Zpower.
apply Z2R_le.
now apply Zge_le.
omega.
easy.
rewrite He2.
ring_simplify (1 + (e - 1) - 1)%Z.
apply le_Z2R.
now rewrite Z2R_Zpower.
rewrite plus_comm.
apply le_plus_minus_r.
apply inj_le_rev.
rewrite He2.
cut (e - 1 < Z_of_nat (S (digits2_Pnat p)))%Z.
rewrite inj_S.
omega.
apply <- bpow_lt.
apply Rle_lt_trans with (1 := proj1 He).
apply Rlt_le_trans with (Z2R (Zpower_nat 2 (S (digits2_Pnat p)))).
apply Z2R_lt.
exact (proj2 (digits2_Pnat_correct p)).
rewrite <- Z2R_Zpower.
apply Z2R_le.
rewrite Zpower_Zpower_nat.
rewrite Zabs_nat_Z_of_nat.
clear.
induction (S (digits2_Pnat p)).
easy.
change (2 * Zpower_nat 2 n <= radix_val beta * Zpower_nat (radix_val beta) n)%Z.
apply Zmult_le_compat ; try easy.
apply beta.
now apply Zpower_NR0.
apply Zle_0_nat.
apply Zle_0_nat.
apply Zmult_1_r.
Qed.

Theorem digits_shift :
  forall m e,
  m <> Z0 -> (0 <= e)%Z ->
  digits (m * Zpower (radix_val beta) e) = (digits m + e)%Z.
Proof.
intros m e Hm He.
rewrite 2!digits_ln_beta.
rewrite mult_Z2R.
rewrite Z2R_Zpower with (1 := He).
change (Z2R m * bpow e)%R with (F2R (Float beta m e)).
apply ln_beta_F2R.
exact Hm.
exact Hm.
contradict Hm.
apply Zmult_integral_l with (2 := Hm).
apply neq_Z2R.
rewrite Z2R_Zpower with (1 := He).
apply Rgt_not_eq.
apply bpow_gt_0.
Qed.

Theorem digits_le :
  forall x y,
  (0 < x)%Z -> (x <= y)%Z ->
  (digits x <= digits y)%Z.
Proof.
intros x y Hx Hxy.
assert (Hy: (y <> 0)%Z).
apply sym_not_eq.
apply Zlt_not_eq.
now apply Zlt_le_trans with x.
rewrite 2!digits_ln_beta.
destruct (ln_beta beta (Z2R x)) as (ex, Hex). simpl.
specialize (Hex (Rgt_not_eq _ _ (Z2R_lt _ _ Hx))).
destruct (ln_beta beta (Z2R y)) as (ey, Hey). simpl.
specialize (Hey (Z2R_neq _ _ Hy)).
eapply bpow_lt_bpow.
apply Rle_lt_trans with (1 := proj1 Hex).
apply Rle_lt_trans with (Rabs (Z2R y)).
rewrite Rabs_pos_eq.
apply Rle_trans with (Z2R y).
now apply Z2R_le.
apply RRle_abs.
apply (Z2R_le 0).
now apply Zlt_le_weak.
apply Hey.
exact Hy.
apply sym_not_eq.
now apply Zlt_not_eq.
Qed.

Theorem digits_lt :
  forall x y,
  (0 < y)%Z ->
  (digits x < digits y)%Z ->
  (x < y)%Z.
Proof.
intros x y Hy.
cut (y <= x -> digits y <= digits x)%Z. omega.
now apply digits_le.
Qed.

Theorem digits_mult_strong :
  forall x y,
  (0 < x)%Z -> (0 < y)%Z ->
  (digits (x + y + x * y) <= digits x + digits y)%Z.
Proof.
intros x y Hx Hy.
assert (Hxy: (0 < Z2R (x + y + x * y))%R).
apply (Z2R_lt 0).
change Z0 with (0 + 0 + 0)%Z.
apply Zplus_lt_compat.
now apply Zplus_lt_compat.
now apply Zmult_lt_0_compat.
rewrite 3!digits_ln_beta ; try now (apply sym_not_eq ; apply Zlt_not_eq).
destruct (ln_beta beta (Z2R (x + y + x * y))) as (exy, Hexy). simpl.
specialize (Hexy (Rgt_not_eq _ _ Hxy)).
destruct (ln_beta beta (Z2R x)) as (ex, Hex). simpl.
specialize (Hex (Rgt_not_eq _ _ (Z2R_lt _ _ Hx))).
destruct (ln_beta beta (Z2R y)) as (ey, Hey). simpl.
specialize (Hey (Rgt_not_eq _ _ (Z2R_lt _ _ Hy))).
eapply bpow_lt_bpow.
apply Rlt_le_trans with (Z2R (x + 1) * Z2R (y + 1))%R.
apply Rle_lt_trans with (Z2R (x + y + x * y)).
rewrite <- (Rabs_pos_eq _ (Rlt_le _ _ Hxy)).
apply Hexy.
rewrite <- mult_Z2R.
apply Z2R_lt.
apply Zplus_lt_reg_r with (- (x + y + x * y + 1))%Z.
now ring_simplify.
rewrite bpow_add.
apply Rmult_le_compat ; try (apply (Z2R_le 0) ; omega).
rewrite <- (Rmult_1_r (Z2R (x + 1))).
change (F2R (Float beta (x + 1) 0) <= bpow ex)%R.
apply F2R_p1_le_bpow.
exact Hx.
unfold F2R. rewrite Rmult_1_r.
apply Rle_lt_trans with (Rabs (Z2R x)).
apply RRle_abs.
apply Hex.
rewrite <- (Rmult_1_r (Z2R (y + 1))).
change (F2R (Float beta (y + 1) 0) <= bpow ey)%R.
apply F2R_p1_le_bpow.
exact Hy.
unfold F2R. rewrite Rmult_1_r.
apply Rle_lt_trans with (Rabs (Z2R y)).
apply RRle_abs.
apply Hey.
apply neq_Z2R.
now apply Rgt_not_eq.
Qed.

End Fcalc_digits.