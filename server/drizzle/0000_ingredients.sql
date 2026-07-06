CREATE TYPE "public"."ingredient_unit" AS ENUM('gramme', 'milligramme', 'piece', 'cuillere_cafe', 'cuillere_soupe');--> statement-breakpoint
CREATE TABLE "ingredients" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"owner_id" uuid,
	"name" varchar(120) NOT NULL,
	"image_url" text,
	"unit" "ingredient_unit" NOT NULL,
	"imported_from_id" uuid,
	"deleted_at" timestamp with time zone,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "ingredient_alternatives" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"low_id" uuid NOT NULL,
	"high_id" uuid NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "ingredients" ADD CONSTRAINT "ingredients_imported_from_id_ingredients_id_fk" FOREIGN KEY ("imported_from_id") REFERENCES "public"."ingredients"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "ingredient_alternatives" ADD CONSTRAINT "ingredient_alternatives_low_id_ingredients_id_fk" FOREIGN KEY ("low_id") REFERENCES "public"."ingredients"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "ingredient_alternatives" ADD CONSTRAINT "ingredient_alternatives_high_id_ingredients_id_fk" FOREIGN KEY ("high_id") REFERENCES "public"."ingredients"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
CREATE UNIQUE INDEX "ingredient_alternatives_pair_uq" ON "ingredient_alternatives" USING btree ("low_id","high_id");