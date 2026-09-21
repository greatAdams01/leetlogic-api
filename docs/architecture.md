# Phase One Architecture

The API is a modular monolith. PostgreSQL is the system of record, Redis stores short-lived OTP
challenges and rate limits, and external providers sit behind interfaces. Customer identities use
phone OTP. Administrator identities are invitation-only and use phone OTP plus TOTP.

Money is represented in minor units with an ISO currency code. Phase One permits NGN only.
Addresses are restricted to Nigeria at the API boundary while retaining a country code for future
expansion. Orders, payments and shipments are intentionally deferred, but the catalogue uses stable
UUIDs and inventory reservation identifiers to avoid later relationship changes.

Audit records and inventory movements are append-only. Identity evidence is private, referenced by
object keys, and can only be exposed through expiring signed URLs by an authorized administrator.

