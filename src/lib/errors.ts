export interface AppErrorOptions {
  code: string;
  message: string;
  statusCode: number;
  details?: unknown;
  expose?: boolean;
}

export class AppError extends Error {
  public readonly code: string;
  public readonly statusCode: number;
  public readonly details?: unknown;
  public readonly expose: boolean;

  constructor(options: AppErrorOptions) {
    super(options.message);
    this.name = "AppError";
    this.code = options.code;
    this.statusCode = options.statusCode;
    this.details = options.details;
    this.expose = options.expose ?? options.statusCode < 500;
  }
}

export class NotFoundError extends AppError {
  constructor(message = "Resource not found") {
    super({ code: "NOT_FOUND", message, statusCode: 404 });
  }
}

export class ValidationError extends AppError {
  constructor(message = "Validation failed", details?: unknown, statusCode: 400 | 422 = 422) {
    super({ code: "VALIDATION_ERROR", message, statusCode, details });
  }
}

export class ConflictError extends AppError {
  constructor(message = "Resource already exists") {
    super({ code: "CONFLICT", message, statusCode: 409 });
  }
}

export class AuthenticationError extends AppError {
  constructor(message = "Authentication required") {
    super({ code: "UNAUTHENTICATED", message, statusCode: 401 });
  }
}

export class AuthorizationError extends AppError {
  constructor(message = "You do not have permission to perform this action") {
    super({ code: "FORBIDDEN", message, statusCode: 403 });
  }
}

export const isAppError = (error: unknown): error is AppError => error instanceof AppError;
