import { axios } from "./axios";
import { AuditLog } from "../types";

interface AuditLogResponse {
  success: boolean;
  page: number;
  limit: number;
  total: number;
  logs: AuditLog[];
}

export const fetchAuditLogs = async (
  page = 1,
  limit = 20
): Promise<AuditLogResponse> => {
  const response = await axios.get<AuditLogResponse>("/auditLog", {
    params: { page, limit },
  });
  return response.data;
};
