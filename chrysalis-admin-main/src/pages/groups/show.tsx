import React, { useState, useEffect } from "react";
import { useShow, useCustomMutation, useInvalidate } from "@refinedev/core";
import { Show, useModalForm } from "@refinedev/antd";
import {
  Typography,
  Table,
  Space,
  Button,
  Modal,
  Form,
  Select,
  Tag,
  notification,
  Avatar,
  App,
} from "antd";
import { UserAddOutlined, DeleteOutlined } from "@ant-design/icons";
import dayjs from "dayjs";

const { Title, Text } = Typography;

interface Member {
  id: string;
  userId: string;
  role: string;
  joinedAt: string;
  user: {
    id: string;
    firstName: string;
    lastName: string;
    email: string;
    avatar: string | null;
  };
}

interface Group {
  id: string;
  name: string;
  profileImg: string | null;
  archived: boolean;
  createdAt: string;
  updatedAt: string;
  members: Member[];
}

interface User {
  id: string;
  email: string;
  username: string;
  firstName: string | null;
  lastName: string | null;
  avatar: string | null;
}

interface FormValues {
  userIds: string[];
}

export const GroupShow: React.FC = () => {
  const BASE_URL = import.meta.env.VITE_API_URL;

  const { modal } = App.useApp();

  const {
    data: { data: initialGroup } = { data: undefined },
    isLoading: isGroupLoading,
  } = useShow<Group>({
    resource: "groups",
  }).query;

  const [group, setGroup] = useState<Group | undefined>(initialGroup);

  // Available users state (with pagination & search)
  const [availableUsers, setAvailableUsers] = useState<User[]>([]);
  const [isUsersLoading, setIsUsersLoading] = useState(false);
  const [usersPage, setUsersPage] = useState(1);
  const [usersTotalPages, setUsersTotalPages] = useState(1);
  const [usersSearch, setUsersSearch] = useState("");

  const invalidate = useInvalidate();
  const { mutate: addMemberMutate } = useCustomMutation();
  const [form] = Form.useForm<FormValues>();

  // Sync state with fetched group
  useEffect(() => {
    setGroup(initialGroup);
  }, [initialGroup]);

  // --- Fetch users not in group with pagination & search ---
  const fetchUsers = async (page = 1, search = "") => {
    if (!group?.id) return;

    setIsUsersLoading(true);
    try {
      const token = localStorage.getItem("accessToken");
      const response = await fetch(
        `${BASE_URL}/groups/userNotInGroup?groupId=${
          group.id
        }&page=${page}&limit=10&search=${encodeURIComponent(search)}`,
        {
          headers: {
            Authorization: `Bearer ${token}`,
          },
        }
      );
      const data = await response.json();

      if (page === 1) {
        setAvailableUsers(data.data);
      } else {
        setAvailableUsers((prev) => [...prev, ...data.data]);
      }

      setUsersPage(page);
      setUsersTotalPages(data.meta.totalPages);
    } catch (error) {
      console.error("Error fetching users:", error);
    } finally {
      setIsUsersLoading(false);
    }
  };

  // Handle search
  const handleSearch = (value: string) => {
    setUsersSearch(value);
    fetchUsers(1, value);
  };

  // Handle scroll to bottom (infinite load)
  const handlePopupScroll = (e: React.UIEvent<HTMLDivElement>) => {
    const target = e.target as HTMLDivElement;
    if (
      target.scrollTop + target.offsetHeight >= target.scrollHeight - 20 &&
      !isUsersLoading &&
      usersPage < usersTotalPages
    ) {
      fetchUsers(usersPage + 1, usersSearch);
    }
  };

  // Add members
  const handleAddMembers = async (values: FormValues) => {
    if (!group?.id) return;

    try {
      await addMemberMutate(
        {
          url: `/groups/${group.id}/members`,
          method: "post",
          values: {
            members: values.userIds,
          },
        },
        {
          onSuccess: () => {
            const addedUsers = availableUsers.filter((u) =>
              values.userIds.includes(u.id)
            );

            setGroup((prev) => {
              if (!prev) return prev;

              return {
                ...prev,
                members: [
                  ...prev.members,
                  ...addedUsers.map((u) => ({
                    id: u.id,
                    userId: u.id,
                    role: "MEMBER" as const,
                    joinedAt: new Date().toISOString(),
                    user: {
                      ...u,
                      firstName: u.firstName ?? "",
                      lastName: u.lastName ?? "",
                    },
                  })),
                ],
              };
            });

            closeAddMemberModal();
            form.resetFields();
            notification.success({
              message: "Success",
              description: "Members added successfully",
            });

            invalidate({
              resource: "groups",
              invalidates: ["list", "many", "detail"],
            });
          },
          onError: (error) => {
            console.error("Add members error:", error);
            notification.error({
              message: "Error",
              description: "Failed to add members",
            });
          },
        }
      );
    } catch (error) {
      console.error("Add members error:", error);
    }
  };

  // Remove member
  const handleRemoveMember = async (userId: string) => {
    if (!group?.id) return;

    try {
      const response = await fetch(
        `${BASE_URL}/groups/members/${group.id}/${userId}`,
        {
          method: "DELETE",
          headers: {
            Authorization: `Bearer ${localStorage.getItem("accessToken")}`,
          },
        }
      );

      if (!response.ok) throw new Error("Failed to remove member");

      notification.success({
        message: "Success",
        description: "Member removed successfully",
      });

      setGroup((prev) =>
        prev
          ? {
              ...prev,
              members: prev.members.filter((m) => m.userId !== userId),
            }
          : prev
      );

      invalidate({
        resource: "groups",
        invalidates: ["list", "many", "detail"],
      });
    } catch (error) {
      console.error("Error removing member:", error);
      notification.error({
        message: "Error",
        description: "Failed to remove member",
      });
      throw error;
    }
  };

  const showDeleteConfirm = (member: Member) => {
    modal.confirm({
      title: "Remove Member",
      content: `Are you sure you want to remove ${
        member.user.firstName && member.user.lastName
          ? `${member.user.firstName} ${member.user.lastName}`
          : member.user.email
      } from the group?`,
      okText: "Yes",
      okType: "danger",
      cancelText: "No",
      onOk() {
        return handleRemoveMember(member.userId);
      },
    });
  };

  const {
    modalProps,
    show: showAddMemberModal,
    close: closeAddMemberModal,
  } = useModalForm({
    action: "create",
    resource: "groups",
  });

  // Initial load
  useEffect(() => {
    if (modalProps.open && group?.id) {
      setAvailableUsers([]);
      setUsersPage(1);
      setUsersSearch("");
      fetchUsers(1, "");
    }
  }, [modalProps.open, group?.id]);

  const membersTableColumns = [
    {
      title: "Member",
      dataIndex: "user",
      render: (user: Member["user"]) => (
        <Space>
          <Avatar src={user.avatar}>
            {user.firstName?.[0]?.toUpperCase() || user.email[0].toUpperCase()}
          </Avatar>
          <Space direction="vertical" size={0}>
            <Text strong>
              {user.firstName && user.lastName
                ? `${user.firstName} ${user.lastName}`
                : user.email}
            </Text>
            <Text type="secondary">{user.email}</Text>
          </Space>
        </Space>
      ),
    },
    {
      title: "Role",
      dataIndex: "role",
      render: (role: string) => (
        <Tag color={role === "ADMIN" ? "blue" : "default"}>{role}</Tag>
      ),
    },
    {
      title: "Joined At",
      dataIndex: "joinedAt",
      render: (date: string) => dayjs(date).format("YYYY-MM-DD HH:mm"),
    },
    {
      title: "Actions",
      key: "actions",
      render: (_: any, record: Member) => (
        <Button
          type="link"
          danger
          icon={<DeleteOutlined />}
          onClick={() => showDeleteConfirm(record)}
        >
          Remove
        </Button>
      ),
    },
  ];

  return (
    <Show
      headerProps={{
        extra: (
          <Button
            type="primary"
            icon={<UserAddOutlined />}
            onClick={() => showAddMemberModal()}
          >
            Add Members
          </Button>
        ),
      }}
    >
      <Title level={5}>Group Information</Title>
      <Space direction="vertical" style={{ width: "100%", marginBottom: 24 }}>
        <Text>
          <Text strong>Name:</Text> {group?.name}
        </Text>
        <Text>
          <Text strong>Created At:</Text>{" "}
          {dayjs(group?.createdAt).format("YYYY-MM-DD HH:mm")}
        </Text>
        <Text>
          <Text strong>Status:</Text>{" "}
          <Tag color={group?.archived ? "red" : "green"}>
            {group?.archived ? "Archived" : "Active"}
          </Tag>
        </Text>
      </Space>

      <Title level={5}>Members</Title>
      <Table
        dataSource={group?.members}
        columns={membersTableColumns}
        size="small"
        rowKey="id"
      />

      <Modal {...modalProps} title="Add Members" onCancel={closeAddMemberModal}>
        <Form<FormValues> form={form} onFinish={handleAddMembers}>
          <Form.Item
            name="userIds"
            label="Select Users"
            rules={[{ required: true, message: "Please select users" }]}
          >
            <Select
              mode="multiple"
              placeholder={isUsersLoading ? "Loading users..." : "Select users"}
              loading={isUsersLoading && usersPage === 1} // show spinner only on first load
              optionFilterProp="children"
              showSearch
              onSearch={handleSearch}
              onPopupScroll={handlePopupScroll}
              filterOption={false} // disable client filtering, use API
              dropdownRender={(menu) => (
                <>
                  {menu}
                  {usersPage < usersTotalPages && (
                    <div style={{ textAlign: "center", padding: 8 }}>
                      {isUsersLoading ? (
                        <span style={{ fontSize: 12, color: "#999" }}>
                          Loading more...
                        </span>
                      ) : (
                        <span style={{ fontSize: 12, color: "#999" }}>
                          Scroll to load more
                        </span>
                      )}
                    </div>
                  )}
                </>
              )}
            >
              {availableUsers.map((user: User) => (
                <Select.Option key={user.id} value={user.id}>
                  {user.firstName && user.lastName
                    ? `${user.firstName} ${user.lastName} (${user.email})`
                    : user.email}
                </Select.Option>
              ))}
            </Select>
          </Form.Item>
          <Form.Item>
            <Button type="primary" htmlType="submit">
              Add Members
            </Button>
          </Form.Item>
        </Form>
      </Modal>
    </Show>
  );
};
