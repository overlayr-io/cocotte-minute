CREATE TYPE "public"."meal_entry_type" AS ENUM('recipe', 'eating_out', 'note');--> statement-breakpoint
CREATE TYPE "public"."meal_slot" AS ENUM('matin', 'midi', 'soir');--> statement-breakpoint
CREATE TABLE "meal_plan_entries" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"owner_id" uuid NOT NULL,
	"day" date NOT NULL,
	"slot" "meal_slot" NOT NULL,
	"entry_type" "meal_entry_type" NOT NULL,
	"recipe_id" uuid,
	"note_text" varchar(160),
	"position" integer DEFAULT 0 NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "meal_plan_entries" ADD CONSTRAINT "meal_plan_entries_recipe_id_recipes_id_fk" FOREIGN KEY ("recipe_id") REFERENCES "public"."recipes"("id") ON DELETE cascade ON UPDATE no action;