export type User = {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
  avatar?: string;
  role: string;
  createdAt: string;
  isActive: boolean;
};

export type Group = {
  id: string;
  name: string;
  description: string;
  members: string[];
  isArchived: boolean;
  createdAt: string;
  updatedAt: string;
};

export type AuditLog = {
  id: string;
  action: string;
  resourceType: string;
  resourceId: string;
  userId: string;
  metadata: Record<string, any>;
  timestamp: string;
};
