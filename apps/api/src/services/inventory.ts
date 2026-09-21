import { Prisma, prisma } from "@leetlogic/database";
import { AppError } from "../lib/errors.js";

export async function reserveInventory(listingId: string, checkoutReferenceId: string, quantity: Prisma.Decimal, expiresAt: Date) {
  if (quantity.lte(0)) throw new AppError(422, "QUANTITY_INVALID", "Quantity must be greater than zero");
  return prisma.$transaction(async tx => {
    const changed = await tx.$executeRaw`
      UPDATE "listings"
      SET "reserved_quantity" = "reserved_quantity" + ${quantity}, "updated_at" = NOW()
      WHERE "id" = ${listingId}::uuid
        AND "deleted_at" IS NULL
        AND "status" = 'ACTIVE'
        AND "available_quantity" - "reserved_quantity" >= ${quantity}`;
    if (changed !== 1) throw new AppError(409, "INSUFFICIENT_INVENTORY", "Requested inventory is unavailable");
    const reservation = await tx.inventoryReservation.create({ data: { listingId, checkoutReferenceId, quantity, expiresAt } });
    await tx.inventoryMovement.create({ data: { listingId, type: "RESERVE", quantity, referenceType: "inventory_reservation", referenceId: reservation.id } });
    return reservation;
  }, { isolationLevel: Prisma.TransactionIsolationLevel.Serializable });
}

export async function assertFarmerCanPublish(userId: string) {
  const farmer = await prisma.farmerProfile.findUnique({ where: { userId }, select: { verificationStatus: true } });
  if (farmer?.verificationStatus !== "APPROVED") throw new AppError(403, "SELLER_NOT_VERIFIED", "Seller verification is required before publishing listings");
}
