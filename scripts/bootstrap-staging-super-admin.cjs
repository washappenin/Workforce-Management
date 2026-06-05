const bcrypt = require("bcryptjs");
const { PrismaClient } = require("@prisma/client");

const confirmationPhrase = "CREATE_STAGING_SUPER_ADMIN";
const minimumPasswordLength = 16;

const fail = (message) => {
  console.error(`[FAIL] ${message}`);
  process.exit(1);
};

if (process.env.NODE_ENV !== "staging") {
  fail("This command only runs when NODE_ENV=staging.");
}

if (process.env.CONFIRM_BOOTSTRAP_SUPER_ADMIN !== confirmationPhrase) {
  fail(`Set CONFIRM_BOOTSTRAP_SUPER_ADMIN=${confirmationPhrase} to confirm this controlled operation.`);
}

if (!process.env.DATABASE_URL) {
  fail("DATABASE_URL is required.");
}

const email = process.env.BOOTSTRAP_SUPER_ADMIN_EMAIL?.trim().toLowerCase();
const password = process.env.BOOTSTRAP_SUPER_ADMIN_PASSWORD;

if (!email || !email.includes("@")) {
  fail("BOOTSTRAP_SUPER_ADMIN_EMAIL must be a valid email address.");
}

if (!password || password.length < minimumPasswordLength) {
  fail(`BOOTSTRAP_SUPER_ADMIN_PASSWORD must contain at least ${minimumPasswordLength} characters.`);
}

const prisma = new PrismaClient();

const main = async () => {
  const matchingUsers = await prisma.user.findMany({
    where: { email },
    select: {
      id: true,
      companyId: true
    }
  });

  if (matchingUsers.length > 1) {
    throw new Error("Multiple users already use this email. Resolve the duplicate accounts before bootstrapping.");
  }

  const existingUser = matchingUsers[0];

  if (existingUser?.companyId) {
    throw new Error("The matching user is company-scoped and cannot be promoted by this command.");
  }

  const passwordHash = await bcrypt.hash(password, 12);
  const result = await prisma.$transaction(async (transaction) => {
    const role = await transaction.role.upsert({
      where: { name: "SUPER_ADMIN" },
      update: {},
      create: { name: "SUPER_ADMIN" }
    });

    const user = existingUser
      ? await transaction.user.update({
          where: { id: existingUser.id },
          data: {
            email,
            passwordHash,
            status: "ACTIVE",
            companyId: null
          }
        })
      : await transaction.user.create({
          data: {
            email,
            passwordHash,
            status: "ACTIVE",
            companyId: null
          }
        });

    const existingRole = await transaction.userRole.findFirst({
      where: {
        userId: user.id,
        roleId: role.id,
        companyId: null
      }
    });

    if (!existingRole) {
      await transaction.userRole.create({
        data: {
          userId: user.id,
          roleId: role.id,
          companyId: null
        }
      });
    }

    if (existingUser) {
      await transaction.deviceSession.updateMany({
        where: {
          userId: user.id,
          status: "ACTIVE"
        },
        data: {
          status: "REVOKED"
        }
      });
    }

    await transaction.auditLog.create({
      data: {
        actorUserId: user.id,
        category: "SECURITY",
        action: existingUser ? "STAGING_SUPER_ADMIN_CREDENTIALS_ROTATED" : "STAGING_SUPER_ADMIN_BOOTSTRAPPED",
        targetType: "User",
        targetId: user.id,
        metadata: {
          source: "controlled-staging-bootstrap",
          created: !existingUser
        }
      }
    });

    return {
      userId: user.id,
      created: !existingUser
    };
  });

  console.log(`[PASS] Staging super-admin ${result.created ? "created" : "updated"} successfully.`);
  console.log(`[INFO] User ID: ${result.userId}`);
  console.log("[INFO] Remove BOOTSTRAP_SUPER_ADMIN_PASSWORD and confirmation variables from Railway now.");
};

main()
  .catch((error) => {
    console.error("[FAIL] Staging super-admin bootstrap failed.");
    console.error(error instanceof Error ? error.message : error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
