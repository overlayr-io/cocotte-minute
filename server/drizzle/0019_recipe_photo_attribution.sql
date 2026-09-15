CREATE TABLE "ingredient_photos" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"ingredient_id" uuid NOT NULL,
	"image_url" text NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "recipe_favorites" (
	"user_id" uuid NOT NULL,
	"recipe_id" uuid NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "recipe_favorites_user_id_recipe_id_pk" PRIMARY KEY("user_id","recipe_id")
);
--> statement-breakpoint
ALTER TABLE "recipes" ADD COLUMN "photo_author_name" text;--> statement-breakpoint
ALTER TABLE "recipes" ADD COLUMN "photo_author_url" text;--> statement-breakpoint
ALTER TABLE "recipes" ADD COLUMN "calories_per_serving" numeric(8, 2);--> statement-breakpoint
ALTER TABLE "recipes" ADD COLUMN "proteins_per_serving" numeric(8, 2);--> statement-breakpoint
ALTER TABLE "recipes" ADD COLUMN "carbs_per_serving" numeric(8, 2);--> statement-breakpoint
ALTER TABLE "recipes" ADD COLUMN "fats_per_serving" numeric(8, 2);--> statement-breakpoint
ALTER TABLE "ingredient_photos" ADD CONSTRAINT "ingredient_photos_ingredient_id_ingredients_id_fk" FOREIGN KEY ("ingredient_id") REFERENCES "public"."ingredients"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "recipe_favorites" ADD CONSTRAINT "recipe_favorites_recipe_id_recipes_id_fk" FOREIGN KEY ("recipe_id") REFERENCES "public"."recipes"("id") ON DELETE cascade ON UPDATE no action;