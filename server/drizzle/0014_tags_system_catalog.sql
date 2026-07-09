ALTER TABLE "tags" ALTER COLUMN "owner_id" DROP NOT NULL;--> statement-breakpoint
ALTER TABLE "tags" ADD COLUMN "imported_from_id" uuid;--> statement-breakpoint
ALTER TABLE "tags" ADD CONSTRAINT "tags_imported_from_id_tags_id_fk" FOREIGN KEY ("imported_from_id") REFERENCES "public"."tags"("id") ON DELETE set null ON UPDATE no action;