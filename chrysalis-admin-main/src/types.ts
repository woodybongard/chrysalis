import { BaseRecord } from "@refinedev/core";

export interface Group extends BaseRecord {
  id: string;
  name: string;
  description?: string;
  members: number;
  isArchived: boolean;
  createdAt: string;
  profileImg?: string;
}

export interface User extends BaseRecord {
  id: string;
  email: string;
  username: string;
  role: string;
  firstName: string;
  lastName: string;
  avatar: string | null;
  isActive: boolean;
  isVerified: boolean;
  isfirstLoggedIn: boolean;
  lastLogin: string;
  createdAt: string;
  updatedAt: string;
}

export interface AuditLog extends BaseRecord {
  id: string;
  actorUserId: string;
  recipientUserId: string | null;
  eventType: string;
  messageId: string;
  conversationId: string | null;
  groupId: string;
  metadata: {
    type: string;
    hasFile: boolean;
  };
  createdAt: string;
  actor: User;
  recipient: User | null;
  group: Group | null;
}
