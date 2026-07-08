CREATE TYPE "public"."account_status" AS ENUM('active', 'pending_deletion', 'deleted');--> statement-breakpoint
CREATE TABLE "accounts" (
	"user_id" uuid PRIMARY KEY NOT NULL,
	"account_status" "account_status" DEFAULT 'active' NOT NULL,
	"deletion_requested_at" timestamp with time zone,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
