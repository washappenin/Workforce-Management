import { PrismaClient, RoleName, SubscriptionPlanType } from "@prisma/client";
import { hashPassword } from "../src/lib/password";

const prisma = new PrismaClient();

const roleNames: RoleName[] = [
  "SUPER_ADMIN",
  "COMPANY_ADMIN",
  "HR_ADMIN",
  "MANAGER",
  "EMPLOYEE"
];

const plans = [
  {
    name: "Basic",
    type: "BASIC" as SubscriptionPlanType,
    pricePerEmployee: "120.00",
    currency: "ETB",
    isActive: true
  },
  {
    name: "Premium",
    type: "PREMIUM" as SubscriptionPlanType,
    pricePerEmployee: "250.00",
    currency: "ETB",
    isActive: true
  }
];

const developmentPassword = "Password123!";

const seedCompany = {
  name: "Demo Workforce Company",
  contactEmail: "admin@example.test",
  country: "US",
  timezone: "America/New_York"
};

const seedUsers = [
  {
    email: "superadmin@example.test",
    role: "SUPER_ADMIN" as RoleName,
    companyScoped: false
  },
  {
    email: "companyadmin@example.test",
    role: "COMPANY_ADMIN" as RoleName,
    companyScoped: true
  },
  {
    email: "hradmin@example.test",
    role: "HR_ADMIN" as RoleName,
    companyScoped: true
  },
  {
    email: "manager@example.test",
    role: "MANAGER" as RoleName,
    companyScoped: true
  },
  {
    email: "employee@example.test",
    role: "EMPLOYEE" as RoleName,
    companyScoped: true
  }
];

async function main() {
  for (const name of roleNames) {
    await prisma.role.upsert({
      where: { name },
      update: {},
      create: { name }
    });
  }

  for (const plan of plans) {
    await prisma.subscriptionPlan.upsert({
      where: { name: plan.name },
      update: plan,
      create: plan
    });
  }

  const passwordHash = await hashPassword(developmentPassword);
  const company = await prisma.company.upsert({
    where: { name: seedCompany.name },
    update: seedCompany,
    create: seedCompany
  });

  for (const seedUser of seedUsers) {
    const companyId = seedUser.companyScoped ? company.id : null;
    const existingUser = await prisma.user.findFirst({
      where: {
        email: seedUser.email,
        companyId
      }
    });

    const user = existingUser
      ? await prisma.user.update({
          where: { id: existingUser.id },
          data: {
            email: seedUser.email,
            passwordHash,
            status: "ACTIVE",
            companyId
          }
        })
      : await prisma.user.create({
          data: {
            email: seedUser.email,
            passwordHash,
            status: "ACTIVE",
            companyId
          }
        });

    const role = await prisma.role.findUniqueOrThrow({
      where: { name: seedUser.role }
    });

    const existingUserRole = await prisma.userRole.findFirst({
      where: {
        userId: user.id,
        roleId: role.id,
        companyId
      }
    });

    if (!existingUserRole) {
      await prisma.userRole.create({
        data: {
          userId: user.id,
          roleId: role.id,
          companyId
        }
      });
    }
  }
}

main()
  .then(async () => {
    await prisma.$disconnect();
  })
  .catch(async (error) => {
    console.error(error);
    await prisma.$disconnect();
    process.exit(1);
  });
