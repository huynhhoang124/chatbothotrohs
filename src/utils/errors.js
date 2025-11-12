export class ApplicationError extends Error {
  constructor(message, statusCode = 500, code = 'APPLICATION_ERROR', details = []) {
    super(message);
    this.statusCode = statusCode;
    this.code = code;
    this.details = details;
  }
}

export class ValidationError extends ApplicationError {
  constructor(details) {
    super('Dữ liệu không hợp lệ', 400, 'VALIDATION_ERROR', details);
  }
}

export class UnauthorizedError extends ApplicationError {
  constructor(message = 'Yêu cầu đăng nhập.') {
    super(message, 401, 'UNAUTHORIZED');
  }
}

export class NotFoundError extends ApplicationError {
  constructor(message = 'Không tìm thấy dữ liệu') {
    super(message, 404, 'NOT_FOUND');
  }
}
