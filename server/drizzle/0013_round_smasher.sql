CREATE TYPE "public"."premium_type" AS ENUM('none', 'subscription', 'lifetime');--> statement-breakpoint
ALTER TABLE "accounts" ADD COLUMN "premium_type" "premium_type" DEFAULT 'none' NOT NULL;--> statement-breakpoint
ALTER TABLE "accounts" ADD COLUMN "premium_until" timestamp with time zone;--> statement-breakpoint
ALTER TABLE "accounts" ADD COLUMN "premium_updated_at" timestamp with time zone;