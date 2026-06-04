const { spawnSync } = require("node:child_process");
const fs = require("node:fs");
const path = require("node:path");

const command = process.argv[2];
const commandArgs = process.argv.slice(3);

if (!["generate", "validate", "migrate"].includes(command)) {
  console.error("Usage: node scripts/prisma.cjs <generate|validate|migrate deploy>");
  process.exit(1);
}

if (command === "migrate" && commandArgs.join(" ") !== "deploy") {
  console.error("Usage: node scripts/prisma.cjs migrate deploy");
  process.exit(1);
}

const prismaBin = path.join(__dirname, "..", "node_modules", ".bin", process.platform === "win32" ? "prisma.cmd" : "prisma");
const schemaPath = path.join(__dirname, "..", "prisma", "schema.prisma");

if (command === "generate") {
  const schema = fs.readFileSync(schemaPath, "utf8");

  if (!/^\s*model\s+\w+/m.test(schema)) {
    console.log("No Prisma models defined yet; skipping client generation until Checkpoint 2.");
    process.exit(0);
  }
}

const isDeployedEnvironment = process.env.NODE_ENV === "staging" || process.env.NODE_ENV === "production";

if (command === "migrate" && isDeployedEnvironment && !process.env.DATABASE_URL) {
  console.error("DATABASE_URL is required for prisma migrate deploy in staging/production.");
  process.exit(1);
}

const env = {
  ...process.env,
  DATABASE_URL:
    process.env.DATABASE_URL ??
    "postgresql://postgres:postgres@localhost:5432/workforce_management?schema=public"
};

const executable = process.platform === "win32" ? "cmd.exe" : prismaBin;
const prismaArgs = [command, ...commandArgs];
const args = process.platform === "win32" ? ["/c", prismaBin, ...prismaArgs] : prismaArgs;

const result = spawnSync(executable, args, {
  env,
  stdio: "inherit"
});

if (result.error) {
  console.error(result.error);
}

process.exit(result.status ?? 1);
