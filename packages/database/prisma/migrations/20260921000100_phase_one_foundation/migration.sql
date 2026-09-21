-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "public";

-- CreateEnum
CREATE TYPE "UserStatus" AS ENUM ('ACTIVE', 'SUSPENDED', 'CLOSED');

-- CreateEnum
CREATE TYPE "Capability" AS ENUM ('BUYER', 'SELLER');

-- CreateEnum
CREATE TYPE "VerificationStatus" AS ENUM ('NOT_STARTED', 'DRAFT', 'SUBMITTED', 'UNDER_REVIEW', 'APPROVED', 'REJECTED', 'RESUBMISSION_REQUIRED');

-- CreateEnum
CREATE TYPE "DocumentType" AS ENUM ('NIN_SLIP', 'VOTER_CARD', 'DRIVERS_LICENSE', 'PASSPORT');

-- CreateEnum
CREATE TYPE "ReviewDecision" AS ENUM ('APPROVED', 'REJECTED', 'RESUBMISSION_REQUIRED');

-- CreateEnum
CREATE TYPE "AdminStatus" AS ENUM ('INVITED', 'ACTIVE', 'SUSPENDED', 'CLOSED');

-- CreateEnum
CREATE TYPE "SessionSubject" AS ENUM ('CUSTOMER', 'ADMIN');

-- CreateEnum
CREATE TYPE "OtpPurpose" AS ENUM ('CUSTOMER_LOGIN', 'ADMIN_LOGIN');

-- CreateEnum
CREATE TYPE "OtpProvider" AS ENUM ('CONSOLE', 'TERMII', 'AFRICAS_TALKING');

-- CreateEnum
CREATE TYPE "OtpOutcome" AS ENUM ('REQUESTED', 'SENT', 'SEND_FAILED', 'VERIFIED', 'INVALID', 'EXPIRED', 'RATE_LIMITED');

-- CreateEnum
CREATE TYPE "ListingStatus" AS ENUM ('DRAFT', 'PENDING_REVIEW', 'ACTIVE', 'PAUSED', 'SOLD_OUT', 'REJECTED', 'ARCHIVED');

-- CreateEnum
CREATE TYPE "ShippingScope" AS ENUM ('LOCAL', 'NATIONWIDE');

-- CreateEnum
CREATE TYPE "MediaType" AS ENUM ('IMAGE', 'VOICE_NOTE');

-- CreateEnum
CREATE TYPE "MediaStatus" AS ENUM ('PENDING', 'READY', 'FAILED');

-- CreateEnum
CREATE TYPE "InventoryMovementType" AS ENUM ('INCREASE', 'DECREASE', 'RESERVE', 'RELEASE', 'SALE', 'ADJUSTMENT');

-- CreateEnum
CREATE TYPE "ReservationStatus" AS ENUM ('ACTIVE', 'RELEASED', 'CONSUMED', 'EXPIRED');

-- CreateTable
CREATE TABLE "users" (
    "id" UUID NOT NULL,
    "phone_e164" TEXT NOT NULL,
    "phone_verified_at" TIMESTAMPTZ(6),
    "status" "UserStatus" NOT NULL DEFAULT 'ACTIVE',
    "preferred_locale" VARCHAR(10) NOT NULL DEFAULT 'en',
    "last_login_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,
    "deleted_at" TIMESTAMPTZ(6),

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "user_capabilities" (
    "user_id" UUID NOT NULL,
    "capability" "Capability" NOT NULL,
    "granted_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "user_capabilities_pkey" PRIMARY KEY ("user_id","capability")
);

-- CreateTable
CREATE TABLE "user_profiles" (
    "user_id" UUID NOT NULL,
    "full_name" VARCHAR(120),
    "display_name" VARCHAR(80),
    "avatar_object_key" VARCHAR(500),
    "email" VARCHAR(254),

    CONSTRAINT "user_profiles_pkey" PRIMARY KEY ("user_id")
);

-- CreateTable
CREATE TABLE "addresses" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "label" VARCHAR(60),
    "country_code" CHAR(2) NOT NULL DEFAULT 'NG',
    "state" VARCHAR(80) NOT NULL,
    "lga" VARCHAR(80) NOT NULL,
    "ward" VARCHAR(100),
    "city" VARCHAR(100) NOT NULL,
    "line1" VARCHAR(180) NOT NULL,
    "line2" VARCHAR(180),
    "landmark" VARCHAR(180),
    "postal_code" VARCHAR(20),
    "latitude" DECIMAL(9,6),
    "longitude" DECIMAL(9,6),
    "is_default_delivery" BOOLEAN NOT NULL DEFAULT false,
    "is_default_farm" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,
    "deleted_at" TIMESTAMPTZ(6),

    CONSTRAINT "addresses_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "sessions" (
    "id" UUID NOT NULL,
    "subject" "SessionSubject" NOT NULL,
    "user_id" UUID,
    "admin_id" UUID,
    "token_family_id" UUID NOT NULL,
    "refresh_token_hash" CHAR(64) NOT NULL,
    "device_id" VARCHAR(128) NOT NULL,
    "expires_at" TIMESTAMPTZ(6) NOT NULL,
    "revoked_at" TIMESTAMPTZ(6),
    "replaced_by_id" UUID,
    "reuse_detected_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "last_used_at" TIMESTAMPTZ(6),

    CONSTRAINT "sessions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "otp_events" (
    "id" UUID NOT NULL,
    "provider" "OtpProvider" NOT NULL,
    "purpose" "OtpPurpose" NOT NULL,
    "masked_destination" VARCHAR(32) NOT NULL,
    "outcome" "OtpOutcome" NOT NULL,
    "attempts" INTEGER NOT NULL DEFAULT 0,
    "ip_address" INET,
    "request_id" UUID NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "otp_events_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "farmer_profiles" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "farm_name" VARCHAR(160) NOT NULL,
    "farm_type" VARCHAR(80) NOT NULL,
    "description" TEXT,
    "primary_address_id" UUID,
    "verification_status" "VerificationStatus" NOT NULL DEFAULT 'DRAFT',
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "farmer_profiles_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "verification_cases" (
    "id" UUID NOT NULL,
    "farmer_profile_id" UUID NOT NULL,
    "status" "VerificationStatus" NOT NULL DEFAULT 'DRAFT',
    "submitted_at" TIMESTAMPTZ(6),
    "decided_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "verification_cases_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "verification_documents" (
    "id" UUID NOT NULL,
    "verification_case_id" UUID NOT NULL,
    "document_type" "DocumentType" NOT NULL,
    "encrypted_object_key" VARCHAR(1000) NOT NULL,
    "mime_type" VARCHAR(100) NOT NULL,
    "checksum_sha256" CHAR(64) NOT NULL,
    "reference_last_four" VARCHAR(4),
    "review_status" "VerificationStatus" NOT NULL DEFAULT 'DRAFT',
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "verification_documents_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "farm_evidence" (
    "id" UUID NOT NULL,
    "verification_case_id" UUID NOT NULL,
    "encrypted_object_key" VARCHAR(1000),
    "note" TEXT,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "farm_evidence_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "verification_reviews" (
    "id" UUID NOT NULL,
    "verification_case_id" UUID NOT NULL,
    "reviewer_admin_id" UUID NOT NULL,
    "decision" "ReviewDecision" NOT NULL,
    "reason" VARCHAR(500) NOT NULL,
    "internal_notes" TEXT,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "verification_reviews_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "admin_accounts" (
    "id" UUID NOT NULL,
    "phone_e164" TEXT NOT NULL,
    "full_name" VARCHAR(120) NOT NULL,
    "status" "AdminStatus" NOT NULL DEFAULT 'INVITED',
    "totp_secret_encrypted" TEXT,
    "totp_enrolled_at" TIMESTAMPTZ(6),
    "invited_by_id" UUID,
    "invited_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "last_login_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "admin_accounts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "admin_roles" (
    "id" UUID NOT NULL,
    "code" VARCHAR(80) NOT NULL,
    "name" VARCHAR(120) NOT NULL,

    CONSTRAINT "admin_roles_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "permissions" (
    "id" UUID NOT NULL,
    "code" VARCHAR(120) NOT NULL,
    "description" VARCHAR(240) NOT NULL,

    CONSTRAINT "permissions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "role_permissions" (
    "role_id" UUID NOT NULL,
    "permission_id" UUID NOT NULL,

    CONSTRAINT "role_permissions_pkey" PRIMARY KEY ("role_id","permission_id")
);

-- CreateTable
CREATE TABLE "admin_role_assignments" (
    "admin_id" UUID NOT NULL,
    "role_id" UUID NOT NULL,
    "assigned_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "admin_role_assignments_pkey" PRIMARY KEY ("admin_id","role_id")
);

-- CreateTable
CREATE TABLE "admin_recovery_codes" (
    "id" UUID NOT NULL,
    "admin_id" UUID NOT NULL,
    "code_hash" CHAR(64) NOT NULL,
    "used_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "admin_recovery_codes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "audit_logs" (
    "id" BIGSERIAL NOT NULL,
    "actor_type" VARCHAR(30) NOT NULL,
    "actor_id" UUID,
    "action" VARCHAR(120) NOT NULL,
    "entity_type" VARCHAR(120) NOT NULL,
    "entity_id" UUID,
    "before_redacted" JSONB,
    "after_redacted" JSONB,
    "ip_address" INET,
    "user_agent" VARCHAR(500),
    "request_id" UUID NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "audit_logs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "languages" (
    "code" VARCHAR(10) NOT NULL,
    "name" VARCHAR(80) NOT NULL,
    "native_name" VARCHAR(80) NOT NULL,
    "is_enabled" BOOLEAN NOT NULL DEFAULT true,
    "sort_order" INTEGER NOT NULL,

    CONSTRAINT "languages_pkey" PRIMARY KEY ("code")
);

-- CreateTable
CREATE TABLE "categories" (
    "id" UUID NOT NULL,
    "slug" VARCHAR(100) NOT NULL,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "sort_order" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "categories_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "category_translations" (
    "category_id" UUID NOT NULL,
    "locale" VARCHAR(10) NOT NULL,
    "name" VARCHAR(120) NOT NULL,

    CONSTRAINT "category_translations_pkey" PRIMARY KEY ("category_id","locale")
);

-- CreateTable
CREATE TABLE "units" (
    "code" VARCHAR(30) NOT NULL,
    "name" VARCHAR(80) NOT NULL,
    "allows_decimal" BOOLEAN NOT NULL DEFAULT true,
    "is_active" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "units_pkey" PRIMARY KEY ("code")
);

-- CreateTable
CREATE TABLE "listings" (
    "id" UUID NOT NULL,
    "farmer_profile_id" UUID NOT NULL,
    "category_id" UUID NOT NULL,
    "unit_code" VARCHAR(30) NOT NULL,
    "location_address_id" UUID NOT NULL,
    "title" VARCHAR(160) NOT NULL,
    "description" TEXT,
    "currency_code" CHAR(3) NOT NULL DEFAULT 'NGN',
    "unit_price_minor" BIGINT NOT NULL,
    "available_quantity" DECIMAL(18,3) NOT NULL,
    "reserved_quantity" DECIMAL(18,3) NOT NULL DEFAULT 0,
    "shipping_scope" "ShippingScope" NOT NULL,
    "status" "ListingStatus" NOT NULL DEFAULT 'DRAFT',
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,
    "deleted_at" TIMESTAMPTZ(6),

    CONSTRAINT "listings_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "listing_media" (
    "id" UUID NOT NULL,
    "listing_id" UUID NOT NULL,
    "type" "MediaType" NOT NULL,
    "object_key" VARCHAR(500) NOT NULL,
    "mime_type" VARCHAR(100) NOT NULL,
    "display_order" INTEGER NOT NULL DEFAULT 0,
    "status" "MediaStatus" NOT NULL DEFAULT 'PENDING',
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "listing_media_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "inventory_movements" (
    "id" UUID NOT NULL,
    "listing_id" UUID NOT NULL,
    "type" "InventoryMovementType" NOT NULL,
    "quantity" DECIMAL(18,3) NOT NULL,
    "reference_type" VARCHAR(40),
    "reference_id" UUID,
    "note" VARCHAR(500),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "inventory_movements_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "inventory_reservations" (
    "id" UUID NOT NULL,
    "listing_id" UUID NOT NULL,
    "checkout_reference_id" UUID NOT NULL,
    "quantity" DECIMAL(18,3) NOT NULL,
    "status" "ReservationStatus" NOT NULL DEFAULT 'ACTIVE',
    "expires_at" TIMESTAMPTZ(6) NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "inventory_reservations_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "idempotency_records" (
    "id" UUID NOT NULL,
    "scope" VARCHAR(80) NOT NULL,
    "idempotency_key" VARCHAR(128) NOT NULL,
    "request_hash" CHAR(64) NOT NULL,
    "response_status" INTEGER,
    "response_body" JSONB,
    "resource_id" UUID,
    "expires_at" TIMESTAMPTZ(6) NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "completed_at" TIMESTAMPTZ(6),

    CONSTRAINT "idempotency_records_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_phone_e164_key" ON "users"("phone_e164");

-- CreateIndex
CREATE INDEX "addresses_user_id_idx" ON "addresses"("user_id");

-- CreateIndex
CREATE UNIQUE INDEX "sessions_refresh_token_hash_key" ON "sessions"("refresh_token_hash");

-- CreateIndex
CREATE INDEX "sessions_token_family_id_idx" ON "sessions"("token_family_id");

-- CreateIndex
CREATE INDEX "sessions_user_id_device_id_idx" ON "sessions"("user_id", "device_id");

-- CreateIndex
CREATE INDEX "sessions_admin_id_device_id_idx" ON "sessions"("admin_id", "device_id");

-- CreateIndex
CREATE INDEX "otp_events_request_id_idx" ON "otp_events"("request_id");

-- CreateIndex
CREATE UNIQUE INDEX "farmer_profiles_user_id_key" ON "farmer_profiles"("user_id");

-- CreateIndex
CREATE INDEX "verification_cases_status_submitted_at_idx" ON "verification_cases"("status", "submitted_at");

-- CreateIndex
CREATE UNIQUE INDEX "admin_accounts_phone_e164_key" ON "admin_accounts"("phone_e164");

-- CreateIndex
CREATE UNIQUE INDEX "admin_roles_code_key" ON "admin_roles"("code");

-- CreateIndex
CREATE UNIQUE INDEX "permissions_code_key" ON "permissions"("code");

-- CreateIndex
CREATE UNIQUE INDEX "admin_recovery_codes_admin_id_code_hash_key" ON "admin_recovery_codes"("admin_id", "code_hash");

-- CreateIndex
CREATE INDEX "audit_logs_entity_type_entity_id_idx" ON "audit_logs"("entity_type", "entity_id");

-- CreateIndex
CREATE INDEX "audit_logs_actor_id_created_at_idx" ON "audit_logs"("actor_id", "created_at");

-- CreateIndex
CREATE UNIQUE INDEX "categories_slug_key" ON "categories"("slug");

-- CreateIndex
CREATE INDEX "listings_status_category_id_idx" ON "listings"("status", "category_id");

-- CreateIndex
CREATE INDEX "listings_farmer_profile_id_status_idx" ON "listings"("farmer_profile_id", "status");

-- CreateIndex
CREATE INDEX "listing_media_listing_id_display_order_idx" ON "listing_media"("listing_id", "display_order");

-- CreateIndex
CREATE INDEX "inventory_movements_listing_id_created_at_idx" ON "inventory_movements"("listing_id", "created_at");

-- CreateIndex
CREATE INDEX "inventory_reservations_status_expires_at_idx" ON "inventory_reservations"("status", "expires_at");

-- CreateIndex
CREATE INDEX "idempotency_records_expires_at_idx" ON "idempotency_records"("expires_at");

-- CreateIndex
CREATE UNIQUE INDEX "idempotency_records_scope_idempotency_key_key" ON "idempotency_records"("scope", "idempotency_key");

-- AddForeignKey
ALTER TABLE "user_capabilities" ADD CONSTRAINT "user_capabilities_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_profiles" ADD CONSTRAINT "user_profiles_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "addresses" ADD CONSTRAINT "addresses_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sessions" ADD CONSTRAINT "sessions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sessions" ADD CONSTRAINT "sessions_admin_id_fkey" FOREIGN KEY ("admin_id") REFERENCES "admin_accounts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "farmer_profiles" ADD CONSTRAINT "farmer_profiles_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "farmer_profiles" ADD CONSTRAINT "farmer_profiles_primary_address_id_fkey" FOREIGN KEY ("primary_address_id") REFERENCES "addresses"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "verification_cases" ADD CONSTRAINT "verification_cases_farmer_profile_id_fkey" FOREIGN KEY ("farmer_profile_id") REFERENCES "farmer_profiles"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "verification_documents" ADD CONSTRAINT "verification_documents_verification_case_id_fkey" FOREIGN KEY ("verification_case_id") REFERENCES "verification_cases"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "farm_evidence" ADD CONSTRAINT "farm_evidence_verification_case_id_fkey" FOREIGN KEY ("verification_case_id") REFERENCES "verification_cases"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "verification_reviews" ADD CONSTRAINT "verification_reviews_verification_case_id_fkey" FOREIGN KEY ("verification_case_id") REFERENCES "verification_cases"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "verification_reviews" ADD CONSTRAINT "verification_reviews_reviewer_admin_id_fkey" FOREIGN KEY ("reviewer_admin_id") REFERENCES "admin_accounts"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "role_permissions" ADD CONSTRAINT "role_permissions_role_id_fkey" FOREIGN KEY ("role_id") REFERENCES "admin_roles"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "role_permissions" ADD CONSTRAINT "role_permissions_permission_id_fkey" FOREIGN KEY ("permission_id") REFERENCES "permissions"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "admin_role_assignments" ADD CONSTRAINT "admin_role_assignments_admin_id_fkey" FOREIGN KEY ("admin_id") REFERENCES "admin_accounts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "admin_role_assignments" ADD CONSTRAINT "admin_role_assignments_role_id_fkey" FOREIGN KEY ("role_id") REFERENCES "admin_roles"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "admin_recovery_codes" ADD CONSTRAINT "admin_recovery_codes_admin_id_fkey" FOREIGN KEY ("admin_id") REFERENCES "admin_accounts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "category_translations" ADD CONSTRAINT "category_translations_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "categories"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "listings" ADD CONSTRAINT "listings_farmer_profile_id_fkey" FOREIGN KEY ("farmer_profile_id") REFERENCES "farmer_profiles"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "listings" ADD CONSTRAINT "listings_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "categories"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "listings" ADD CONSTRAINT "listings_unit_code_fkey" FOREIGN KEY ("unit_code") REFERENCES "units"("code") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "listings" ADD CONSTRAINT "listings_location_address_id_fkey" FOREIGN KEY ("location_address_id") REFERENCES "addresses"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "listing_media" ADD CONSTRAINT "listing_media_listing_id_fkey" FOREIGN KEY ("listing_id") REFERENCES "listings"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "inventory_movements" ADD CONSTRAINT "inventory_movements_listing_id_fkey" FOREIGN KEY ("listing_id") REFERENCES "listings"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "inventory_reservations" ADD CONSTRAINT "inventory_reservations_listing_id_fkey" FOREIGN KEY ("listing_id") REFERENCES "listings"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- Each session belongs to exactly one principal of the declared type.
ALTER TABLE "sessions" ADD CONSTRAINT "sessions_subject_principal_check" CHECK (
  ("subject" = 'CUSTOMER' AND "user_id" IS NOT NULL AND "admin_id" IS NULL) OR
  ("subject" = 'ADMIN' AND "admin_id" IS NOT NULL AND "user_id" IS NULL)
);

-- Immutable ledger and audit rows are protected at the database boundary as well as in application code.
CREATE FUNCTION reject_immutable_change() RETURNS trigger AS $$
BEGIN
  RAISE EXCEPTION '% is append-only', TG_TABLE_NAME;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER audit_logs_append_only
BEFORE UPDATE OR DELETE ON "audit_logs"
FOR EACH ROW EXECUTE FUNCTION reject_immutable_change();

CREATE TRIGGER inventory_movements_append_only
BEFORE UPDATE OR DELETE ON "inventory_movements"
FOR EACH ROW EXECUTE FUNCTION reject_immutable_change();
