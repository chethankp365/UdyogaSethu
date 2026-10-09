-- Migration: 0491_payments_updated_at.sql
-- Description: Add updated_at column to payments table for escrow release tracking.

ALTER TABLE public.payments ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
