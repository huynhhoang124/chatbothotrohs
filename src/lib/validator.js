import { z } from 'zod';

export const registerSchema = z.object({
  email: z.string().email({ message: 'Email không hợp lệ' }).max(255),
  password: z.string().min(6, { message: 'Mật khẩu tối thiểu 6 ký tự' }).max(100)
});

export const loginSchema = registerSchema;

export const studentSchema = z.object({
  fullName: z.string().min(2, { message: 'Họ tên quá ngắn' }),
  dob: z.string().min(4, { message: 'Ngày sinh không hợp lệ' }),
  major: z.string().min(2, { message: 'Chuyên ngành không hợp lệ' }),
  email: z.string().email({ message: 'Email sinh viên không hợp lệ' }),
  classes: z.array(z.string().min(1)).default([])
});

export const updateStudentSchema = studentSchema.partial();

export const courseSchema = z.object({
  title: z.string().min(2),
  credits: z.number().int().min(1).max(10),
  semester: z.string().min(1),
  teacher: z.string().min(2)
});

export const updateCourseSchema = courseSchema.partial();

export const enrollmentSchema = z.object({
  studentId: z.string().min(1),
  courseId: z.string().min(1)
});

export const enrollmentUpdateSchema = z.object({
  status: z.enum(['enrolled', 'completed', 'dropped'])
});

export const chatSchema = z.object({
  topic: z.enum(['faq', 'hocvu', 'dangky', 'email', 'khieunai', 'tonghop']),
  question: z.string().min(5),
  context: z.record(z.any()).optional()
});

export const queryKeywordSchema = z.object({
  keyword: z.string().optional()
});

export const querySemesterSchema = z.object({
  semester: z.string().optional()
});

export const queryEnrollmentSchema = z.object({
  studentId: z.string().optional()
});

export const validate = (schema, data) => {
  const result = schema.safeParse(data);
  if (!result.success) {
    const details = result.error.issues.map((issue) => ({
      path: issue.path.join('.'),
      message: issue.message
    }));
    return { ok: false, details };
  }
  return { ok: true, data: result.data };
};
