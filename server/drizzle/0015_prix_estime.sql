CREATE TYPE "public"."price_reference_unit" AS ENUM('kilogram', 'litre', 'piece');--> statement-breakpoint
CREATE TYPE "public"."recipe_price_bracket" AS ENUM('under_5', 'from_5_to_10', 'from_10_to_20', 'over_20');--> statement-breakpoint
CREATE TYPE "public"."recipe_price_mode" AS ENUM('calculated', 'fixed');--> statement-breakpoint
CREATE TABLE "ingredient_prices" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"ingredient_id" uuid NOT NULL,
	"price_reference_unit" "price_reference_unit" NOT NULL,
	"low_price" numeric(10, 3),
	"high_price" numeric(10, 3),
	"average_price" numeric(10, 3),
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "recipes" ADD COLUMN "price_mode" "recipe_price_mode" DEFAULT 'calculated' NOT NULL;--> statement-breakpoint
ALTER TABLE "recipes" ADD COLUMN "fixed_price" numeric(10, 2);--> statement-breakpoint
ALTER TABLE "recipes" ADD COLUMN "price_bracket" "recipe_price_bracket";--> statement-breakpoint
ALTER TABLE "ingredient_prices" ADD CONSTRAINT "ingredient_prices_ingredient_id_ingredients_id_fk" FOREIGN KEY ("ingredient_id") REFERENCES "public"."ingredients"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
CREATE UNIQUE INDEX "ingredient_prices_user_ingredient_uq" ON "ingredient_prices" USING btree ("user_id","ingredient_id");