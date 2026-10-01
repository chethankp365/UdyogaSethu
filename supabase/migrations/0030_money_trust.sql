-- Migration: 0030_money_trust.sql
-- Description: Wallets, append-only ledger, wallet balances view, payments, payouts, KYC, face profiles,
--              verification attempts, consent logs, fraud flags, ratings/reviews, favourites, disputes,
--              emergency contacts, SOS incidents, and job protection claims.

-- 1. Custom Enums for Money
CREATE TYPE public.ledger_direction AS ENUM ('credit', 'debit');
CREATE TYPE public.ledger_bucket AS ENUM ('available', 'pending', 'escrow', 'reward');
CREATE TYPE public.payment_method AS ENUM ('upi', 'card', 'wallet', 'cash');
CREATE TYPE public.payment_status AS ENUM ('created', 'authorised', 'captured', 'held', 'released', 'refunded', 'failed');
CREATE TYPE public.payout_status AS ENUM ('requested', 'processing', 'completed', 'failed', 'cancelled');

-- 2. Custom Enums for Trust & Safety
CREATE TYPE public.doc_type AS ENUM ('aadhaar', 'pan', 'driving_licence', 'college_id', 'bank_account', 'upi');
CREATE TYPE public.verification_context AS ENUM ('login', 'job_start', 'mid_job', 'completion');
CREATE TYPE public.verification_attempt_result AS ENUM ('pass', 'fail', 'manual_review_required', 'error');
CREATE TYPE public.consent_purpose AS ENUM ('terms', 'kyc', 'face', 'gps', 'notifications', 'ads');
CREATE TYPE public.fraud_severity AS ENUM ('low', 'medium', 'high', 'critical');
CREATE TYPE public.fraud_flag_status AS ENUM ('open', 'reviewing', 'actioned', 'dismissed');
CREATE TYPE public.dispute_issue_type AS ENUM (
  'no_show',
  'incomplete_work',
  'poor_quality',
  'wrong_product',
  'payment_issue',
  'unsafe_conduct',
  'verification_problem'
);
CREATE TYPE public.dispute_status AS ENUM ('open', 'in_review', 'resolved', 'rejected');
CREATE TYPE public.sos_status AS ENUM ('active', 'resolved', 'false_alarm');
CREATE TYPE public.protection_claim_status AS ENUM ('submitted', 'under_review', 'approved', 'rejected');

-- ============================================================================
-- MONEY & WALLET TABLES
-- ============================================================================

-- 3. Table: wallets
CREATE TABLE public.wallets (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  user_id UUID UNIQUE NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. Table: ledger_entries (APPEND-ONLY)
CREATE TABLE public.ledger_entries (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  wallet_id UUID NOT NULL REFERENCES public.wallets(id) ON DELETE CASCADE,
  direction public.ledger_direction NOT NULL,
  amount_paise BIGINT NOT NULL CHECK (amount_paise > 0),
  bucket public.ledger_bucket NOT NULL DEFAULT 'available',
  ref_type TEXT,
  ref_id UUID,
  idempotency_key TEXT UNIQUE,
  note TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. Trigger Function enforcing Append-Only on ledger_entries
CREATE OR REPLACE FUNCTION public.prevent_ledger_entry_mutation()
RETURNS TRIGGER AS $$
BEGIN
  RAISE EXCEPTION 'Ledger entries are append-only. Updates and deletes are prohibited for audit safety.';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_prevent_ledger_mutation
  BEFORE UPDATE OR DELETE ON public.ledger_entries
  FOR EACH ROW EXECUTE FUNCTION public.prevent_ledger_entry_mutation();

-- 6. View: wallet_balances
CREATE OR REPLACE VIEW public.wallet_balances AS
SELECT
  w.id AS wallet_id,
  w.user_id,
  COALESCE(SUM(CASE WHEN l.bucket = 'available' AND l.direction = 'credit' THEN l.amount_paise WHEN l.bucket = 'available' AND l.direction = 'debit' THEN -l.amount_paise ELSE 0 END), 0) AS available_paise,
  COALESCE(SUM(CASE WHEN l.bucket = 'pending' AND l.direction = 'credit' THEN l.amount_paise WHEN l.bucket = 'pending' AND l.direction = 'debit' THEN -l.amount_paise ELSE 0 END), 0) AS pending_paise,
  COALESCE(SUM(CASE WHEN l.bucket = 'escrow' AND l.direction = 'credit' THEN l.amount_paise WHEN l.bucket = 'escrow' AND l.direction = 'debit' THEN -l.amount_paise ELSE 0 END), 0) AS escrow_paise,
  COALESCE(SUM(CASE WHEN l.bucket = 'reward' AND l.direction = 'credit' THEN l.amount_paise WHEN l.bucket = 'reward' AND l.direction = 'debit' THEN -l.amount_paise ELSE 0 END), 0) AS reward_paise,
  COALESCE(SUM(CASE WHEN l.direction = 'credit' THEN l.amount_paise ELSE -l.amount_paise END), 0) AS total_balance_paise
FROM public.wallets w
LEFT JOIN public.ledger_entries l ON w.id = l.wallet_id
GROUP BY w.id, w.user_id;

-- 7. Table: payments
CREATE TABLE public.payments (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  payer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  payee_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  ref_type TEXT NOT NULL,
  ref_id UUID NOT NULL,
  amount_paise BIGINT NOT NULL CHECK (amount_paise >= 0),
  platform_fee_paise BIGINT NOT NULL DEFAULT 0 CHECK (platform_fee_paise >= 0),
  method public.payment_method NOT NULL DEFAULT 'upi',
  status public.payment_status NOT NULL DEFAULT 'created',
  protected BOOLEAN NOT NULL DEFAULT false,
  razorpay_order_id TEXT,
  razorpay_payment_id TEXT,
  signature_verified BOOLEAN NOT NULL DEFAULT false,
  receipt_no TEXT UNIQUE NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 8. Table: payouts
CREATE TABLE public.payouts (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  amount_paise BIGINT NOT NULL CHECK (amount_paise > 0),
  status public.payout_status NOT NULL DEFAULT 'requested',
  method TEXT NOT NULL DEFAULT 'upi',
  payout_ref TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- TRUST, VERIFICATION & SAFETY TABLES
-- ============================================================================

-- 9. Table: kyc_records
CREATE TABLE public.kyc_records (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  doc_type public.doc_type NOT NULL,
  provider TEXT NOT NULL DEFAULT 'digilocker',
  provider_ref TEXT,
  status public.verification_status NOT NULL DEFAULT 'pending',
  masked_id TEXT,
  name_masked TEXT,
  verified_at TIMESTAMPTZ,
  expiry_date DATE,
  rejection_reason TEXT,
  doc_path TEXT,
  reviewer_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 10. Table: face_profiles
CREATE TABLE public.face_profiles (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  user_id UUID UNIQUE NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  reference_path TEXT NOT NULL,
  matcher_ref TEXT,
  liveness_passed_at TIMESTAMPTZ,
  consent_log_id UUID,
  status public.verification_status NOT NULL DEFAULT 'verified',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 11. Table: verification_attempts
CREATE TABLE public.verification_attempts (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  context public.verification_context NOT NULL,
  assignment_id UUID REFERENCES public.job_assignments(id) ON DELETE SET NULL,
  liveness_ok BOOLEAN NOT NULL,
  match_score NUMERIC(5,2) CHECK (match_score >= 0.00 AND match_score <= 100.00),
  gps_ok BOOLEAN NOT NULL,
  distance_m NUMERIC(10,2) CHECK (distance_m >= 0),
  result public.verification_attempt_result NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 12. Table: consent_logs
CREATE TABLE public.consent_logs (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  purpose public.consent_purpose NOT NULL,
  granted BOOLEAN NOT NULL,
  version TEXT NOT NULL DEFAULT '1.0',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 13. Table: fraud_flags
CREATE TABLE public.fraud_flags (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  rule_key TEXT NOT NULL,
  severity public.fraud_severity NOT NULL DEFAULT 'medium',
  ref_type TEXT,
  ref_id UUID,
  evidence JSONB,
  status public.fraud_flag_status NOT NULL DEFAULT 'open',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 14. Table: ratings_reviews
CREATE TABLE public.ratings_reviews (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  ref_type TEXT NOT NULL,
  ref_id UUID NOT NULL,
  rater_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  target_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  stars INT NOT NULL CHECK (stars >= 1 AND stars <= 5),
  tags TEXT[],
  comment TEXT,
  hidden BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_ratings_rater_ref UNIQUE (rater_id, ref_type, ref_id)
);

-- 15. Table: favourites
CREATE TABLE public.favourites (
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  target_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, target_id)
);

-- 16. Table: disputes
CREATE TABLE public.disputes (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  ref_type TEXT NOT NULL,
  ref_id UUID NOT NULL,
  raised_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  against UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  issue_type public.dispute_issue_type NOT NULL,
  details TEXT NOT NULL,
  status public.dispute_status NOT NULL DEFAULT 'open',
  resolution TEXT,
  refund_paise BIGINT CHECK (refund_paise >= 0),
  resolved_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 17. Table: dispute_evidence
CREATE TABLE public.dispute_evidence (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  dispute_id UUID NOT NULL REFERENCES public.disputes(id) ON DELETE CASCADE,
  uploader UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  path TEXT NOT NULL,
  note TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 18. Table: emergency_contacts
CREATE TABLE public.emergency_contacts (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  phone TEXT NOT NULL,
  relation TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 19. Table: sos_incidents
CREATE TABLE public.sos_incidents (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  assignment_id UUID REFERENCES public.job_assignments(id) ON DELETE SET NULL,
  location extensions.geography(Point, 4326),
  status public.sos_status NOT NULL DEFAULT 'active',
  notified JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 20. Table: protection_claims
CREATE TABLE public.protection_claims (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  assignment_id UUID NOT NULL REFERENCES public.job_assignments(id) ON DELETE CASCADE,
  claimant_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  claim_type TEXT NOT NULL,
  amount_paise BIGINT NOT NULL CHECK (amount_paise >= 0),
  details TEXT NOT NULL,
  status public.protection_claim_status NOT NULL DEFAULT 'submitted',
  is_simulated BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- ENABLE RLS ON ALL TABLES (No policies yet - P1.5)
-- ============================================================================

ALTER TABLE public.wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ledger_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kyc_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.face_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verification_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.consent_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fraud_flags ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ratings_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.favourites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.disputes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dispute_evidence ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.emergency_contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sos_incidents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.protection_claims ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- INDEXES
-- ============================================================================

CREATE INDEX idx_wallets_user ON public.wallets (user_id);
CREATE INDEX idx_ledger_wallet_bucket ON public.ledger_entries (wallet_id, bucket);
CREATE INDEX idx_ledger_idempotency ON public.ledger_entries (idempotency_key);
CREATE INDEX idx_payments_payer ON public.payments (payer_id);
CREATE INDEX idx_payments_payee ON public.payments (payee_id);
CREATE INDEX idx_payments_status ON public.payments (status);
CREATE INDEX idx_payments_receipt ON public.payments (receipt_no);
CREATE INDEX idx_payouts_user_status ON public.payouts (user_id, status);
CREATE INDEX idx_kyc_user_status ON public.kyc_records (user_id, status);
CREATE INDEX idx_verif_attempts_user ON public.verification_attempts (user_id, context);
CREATE INDEX idx_consent_user_purpose ON public.consent_logs (user_id, purpose);
CREATE INDEX idx_fraud_user_status ON public.fraud_flags (user_id, status);
CREATE INDEX idx_ratings_target ON public.ratings_reviews (target_id);
CREATE INDEX idx_ratings_rater_ref ON public.ratings_reviews (rater_id, ref_type, ref_id);
CREATE INDEX idx_disputes_raised ON public.disputes (raised_by);
CREATE INDEX idx_disputes_against ON public.disputes (against);
CREATE INDEX idx_disputes_status ON public.disputes (status);
CREATE INDEX idx_emergency_contacts_user ON public.emergency_contacts (user_id);
CREATE INDEX idx_sos_location ON public.sos_incidents USING GIST (location);

-- ============================================================================
-- TRIGGERS FOR updated_at
-- ============================================================================

CREATE TRIGGER trg_kyc_records_updated_at BEFORE UPDATE ON public.kyc_records FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER trg_face_profiles_updated_at BEFORE UPDATE ON public.face_profiles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER trg_disputes_updated_at BEFORE UPDATE ON public.disputes FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================================
-- TABLE COMMENTS
-- ============================================================================

COMMENT ON TABLE public.wallets IS 'User in-app digital wallet.';
COMMENT ON TABLE public.ledger_entries IS 'APPEND-ONLY immutable double-entry style financial transaction ledger.';
COMMENT ON VIEW public.wallet_balances IS 'Calculated live wallet balances per bucket (available, pending, escrow, reward).';
COMMENT ON TABLE public.payments IS 'Razorpay and in-app payment transactions with protection status.';
COMMENT ON TABLE public.payouts IS 'Worker and farmer withdrawal payouts.';
COMMENT ON TABLE public.kyc_records IS 'Identity document KYC records with masked IDs and verification status.';
COMMENT ON TABLE public.face_profiles IS 'Facial enrollment profile reference and liveness timestamp.';
COMMENT ON TABLE public.verification_attempts IS 'On-device face and GPS liveness/distance verification attempt logs.';
COMMENT ON TABLE public.consent_logs IS 'Granular user privacy and data processing consent audit log.';
COMMENT ON TABLE public.fraud_flags IS 'Automated trust and safety fraud anomaly flags.';
COMMENT ON TABLE public.ratings_reviews IS 'Peer ratings and reviews with 1-5 star scale and tags.';
COMMENT ON TABLE public.favourites IS 'User favourite workers, farmers, or employers.';
COMMENT ON TABLE public.disputes IS 'Job and produce order disputes with resolution status.';
COMMENT ON TABLE public.dispute_evidence IS 'Supporting evidence files for active disputes.';
COMMENT ON TABLE public.emergency_contacts IS 'User emergency contact list for SOS notifications.';
COMMENT ON TABLE public.sos_incidents IS 'Real-time Emergency SOS incident alerts.';
COMMENT ON TABLE public.protection_claims IS 'Job protection insurance claims (labelled is_simulated for demo mode).';
