const fs = require("node:fs");

const [command, ...args] = process.argv.slice(2);

const readJson = (file) => JSON.parse(fs.readFileSync(file, "utf8"));

const getPath = (value, path) => {
  const parts = [];
  const pattern = /([^.[\]]+)|\[(\d+)\]/g;
  let match;

  while ((match = pattern.exec(path)) !== null) {
    parts.push(match[1] ?? Number(match[2]));
  }

  return parts.reduce((current, part) => current?.[part], value);
};

const writeValue = (value) => {
  if (typeof value === "string") {
    process.stdout.write(value);
    return;
  }

  process.stdout.write(JSON.stringify(value));
};

const parseTypedValue = (type, value) => {
  if (type === "string") {
    return value;
  }

  if (type === "number") {
    const parsed = Number(value);

    if (!Number.isFinite(parsed)) {
      throw new Error(`Invalid number: ${value}`);
    }

    return parsed;
  }

  if (type === "boolean") {
    if (value !== "true" && value !== "false") {
      throw new Error(`Invalid boolean: ${value}`);
    }

    return value === "true";
  }

  if (type === "null") {
    return null;
  }

  throw new Error(`Unsupported value type: ${type}`);
};

const removeKeys = (value, keys) => {
  if (Array.isArray(value)) {
    return value.map((item) => removeKeys(item, keys));
  }

  if (value && typeof value === "object") {
    return Object.fromEntries(
      Object.entries(value)
        .filter(([key]) => !keys.has(key))
        .map(([key, item]) => [key, removeKeys(item, keys)])
    );
  }

  return value;
};

try {
  if (command === "object") {
    if (args.length % 3 !== 0) {
      throw new Error("Object arguments must be key/type/value triples");
    }

    const result = {};

    for (let index = 0; index < args.length; index += 3) {
      result[args[index]] = parseTypedValue(args[index + 1], args[index + 2]);
    }

    writeValue(result);
  } else if (command === "get") {
    const value = getPath(readJson(args[0]), args[1]);

    if (value === undefined || value === null) {
      process.exit(1);
    }

    writeValue(value);
  } else if (command === "test") {
    const data = readJson(args[0]);
    const test = new Function("data", `"use strict"; return Boolean(${args[1]});`);
    process.exit(test(data) ? 0 : 1);
  } else if (command === "test-arg") {
    const data = readJson(args[0]);
    const test = new Function("data", "arg", `"use strict"; return Boolean(${args[1]});`);
    process.exit(test(data, args[2]) ? 0 : 1);
  } else if (command === "sanitize") {
    const data = removeKeys(readJson(args[0]), new Set(["accessToken", "refreshToken"]));
    process.stdout.write(`${JSON.stringify(data, null, 2)}\n`);
  } else {
    throw new Error(`Unsupported command: ${command ?? "<empty>"}`);
  }
} catch (error) {
  console.error(error instanceof Error ? error.message : error);
  process.exit(1);
}
