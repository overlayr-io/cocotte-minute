CREATE TYPE "public"."recipe_step_banner" AS ENUM('warning', 'info', 'danger', 'learn');--> statement-breakpoint
CREATE TABLE "recipe_steps" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"recipe_id" uuid NOT NULL,
	"position" integer NOT NULL,
	"description" text,
	"banner_type" "recipe_step_banner",
	"banner_text" text,
	"base_recipe_ref_id" uuid,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "step_ingredients" (
	"step_id" uuid NOT NULL,
	"ingredient_id" uuid NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "step_ingredients_step_id_ingredient_id_pk" PRIMARY KEY("step_id","ingredient_id")
);
--> statement-breakpoint
ALTER TABLE "recipe_steps" ADD CONSTRAINT "recipe_steps_recipe_id_recipes_id_fk" FOREIGN KEY ("recipe_id") REFERENCES "public"."recipes"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "recipe_steps" ADD CONSTRAINT "recipe_steps_base_recipe_ref_id_recipes_id_fk" FOREIGN KEY ("base_recipe_ref_id") REFERENCES "public"."recipes"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "step_ingredients" ADD CONSTRAINT "step_ingredients_step_id_recipe_steps_id_fk" FOREIGN KEY ("step_id") REFERENCES "public"."recipe_steps"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "step_ingredients" ADD CONSTRAINT "step_ingredients_ingredient_id_ingredients_id_fk" FOREIGN KEY ("ingredient_id") REFERENCES "public"."ingredients"("id") ON DELETE cascade ON UPDATE no action;