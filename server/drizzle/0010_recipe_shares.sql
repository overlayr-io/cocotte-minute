CREATE TABLE "recipe_shares" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"recipe_id" uuid NOT NULL,
	"author_id" uuid NOT NULL,
	"token" varchar(32) NOT NULL,
	"revoked_at" timestamp with time zone,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "recipe_shares_token_unique" UNIQUE("token")
);
--> statement-breakpoint
ALTER TABLE "recipe_shares" ADD CONSTRAINT "recipe_shares_recipe_id_recipes_id_fk" FOREIGN KEY ("recipe_id") REFERENCES "public"."recipes"("id") ON DELETE cascade ON UPDATE no action;