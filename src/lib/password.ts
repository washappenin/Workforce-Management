import bcrypt from "bcryptjs";

const passwordSaltRounds = 12;

export const hashPassword = async (password: string) => bcrypt.hash(password, passwordSaltRounds);

export const verifyPassword = async (password: string, passwordHash: string) => bcrypt.compare(password, passwordHash);
