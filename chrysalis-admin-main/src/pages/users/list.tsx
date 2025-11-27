import { List, useTable, ShowButton, EditButton } from "@refinedev/antd";
import {
  Table,
  Space,
  Avatar,
  Tag,
  Button,
  Modal,
  Form,
  Input,
  Upload,
  App,
} from "antd";
import { UploadOutlined, LockOutlined } from "@ant-design/icons";
import type { User } from "../../types";
import dayjs from "dayjs";
import { useState } from "react";
import { useCreate, useInvalidate, useCustomMutation } from "@refinedev/core";
import type { UploadFile } from "antd/es/upload/interface";

export const UserList = () => {
  const { message, notification } = App.useApp();
  const [isCreateModalVisible, setIsCreateModalVisible] = useState(false);
  const [isEditModalVisible, setIsEditModalVisible] = useState(false);
  const [editingUser, setEditingUser] = useState<User | null>(null);
  const [editLoading, setEditLoading] = useState(false);
  const [editFileList, setEditFileList] = useState<UploadFile[]>([]);
  const [isPasswordModalVisible, setIsPasswordModalVisible] = useState(false);
  const [selectedUserId, setSelectedUserId] = useState<string | null>(null);
  const [passwordLoading, setPasswordLoading] = useState(false);

  const [createForm] = Form.useForm();
  const [editForm] = Form.useForm();
  const [passwordForm] = Form.useForm();

  const { mutate: createMutate } = useCreate();
  const { mutate: customMutate, isLoading: isUpdating } = useCustomMutation();
  const invalidate = useInvalidate();

  const { tableProps } = useTable<User>({
    resource: "users",
    pagination: { pageSize: 10 },
  });

  // ✅ CREATE USER
  const handleCreate = async (values: any) => {
    createMutate(
      {
        resource: "auth/register",
        values,
        errorNotification: false,
        successNotification: false,
      },
      {
        onSuccess: () => {
          setIsCreateModalVisible(false);
          createForm.resetFields();
          invalidate({ resource: "users", invalidates: ["list"] });
          message.success(`User ${values.username} created successfully!`);
        },
        onError: (error: any) => {
          // Handle both error formats: { error: { details, message } } and { message }
          const errorData = error?.response?.data?.error || error?.response?.data;
          const details = errorData?.details;

          if (details && Array.isArray(details) && details.length > 0) {
            const errorMsgs = details.map(
              (d: any) => `${d.path}: ${d.msg}`
            );
            notification.error({
              message: "Validation failed",
              description: errorMsgs.join(", "),
            });
          } else {
            const msg = errorData?.message || error?.response?.data?.message || error?.message || "Create failed";
            notification.error({ message: msg });
          }
        },
      }
    );
  };

  const { mutate: editMutate } = useCustomMutation();
  const { mutate: passwordMutate } = useCustomMutation();

  // ✅ UPDATE PASSWORD
  const handlePasswordUpdate = async (values: { currentPassword: string; password: string }) => {
    if (!selectedUserId) return;
    setPasswordLoading(true);

    try {
      await passwordMutate(
        {
          url: "/users/update-password",
          method: "put",
          values: {
            userId: selectedUserId,
            currentPassword: values.currentPassword,
            password: values.password,
          },
        },
        {
          onSuccess: () => {
            setIsPasswordModalVisible(false);
            passwordForm.resetFields();
            setSelectedUserId(null);
            notification.success({ message: "Password updated successfully" });
          },
          onError: (error: any) => {
            // Handle both error formats: { error: { details, message } } and { message }
            const errorData = error?.response?.data?.error || error?.response?.data;
            const details = errorData?.details;
            if (details && details.length > 0) {
              const errorMsgs = details.map((d: any) => `${d.path}: ${d.msg}`);
              notification.error({
                message: "Failed to update password",
                description: errorMsgs.join("\n"),
                style: { whiteSpace: "pre-line" },
              });
            } else {
              notification.error({
                message: "Failed to update password",
                description: errorData?.message || error?.response?.data?.message || "An error occurred",
              });
            }
          },
        }
      );
    } catch (error) {
      console.error(error);
    } finally {
      setPasswordLoading(false);
    }
  };

  // ✅ EDIT USER (multipart/form-data)
  const handleEdit = async (values: any) => {
    if (!editingUser) return;
    setEditLoading(true);

    const formData = new FormData();
    formData.append("firstName", values.firstName);
    formData.append("lastName", values.lastName);

    // Handle file upload
    if (editFileList.length > 0 && editFileList[0].originFileObj) {
      formData.append("file", editFileList[0].originFileObj);
    }

    // Handle avatar removal
    if (values.removeAvatar) {
      formData.append("removeAvatar", "true");
    }

    try {
      await new Promise<void>((resolve, reject) => {
        editMutate(
          {
            url: `/users/update-user-profile`,
            method: "patch",
            values: formData as any,
            meta: { query: { userId: editingUser.id } },
          },
          {
            onSuccess: () => {
              setIsEditModalVisible(false);
              setEditingUser(null);
              setEditFileList([]);
              editForm.resetFields();
              notification.success({ message: "Group updated successfully" });
              invalidate({ resource: "users", invalidates: ["list"] });
              resolve();
            },
            onError: (error: any) => {
              const errorData = error?.response?.data?.error;
              const details = errorData?.details;
              if (details && details.length > 0) {
                const errorMsgs = details.map((d: any) => `${d.path}: ${d.msg}`);
                notification.error({
                  message: "Failed to update user",
                  description: errorMsgs.join("\n"),
                  style: { whiteSpace: "pre-line" },
                });
              } else {
                notification.error({
                  message: errorData?.message || "Failed to update user",
                });
              }
              reject(error);
            },
          }
        );
      });
    } catch (error) {
      console.error(error);
    } finally {
      setEditLoading(false); // ensures loading stops even on error
    }

    // customMutate(
    //   {
    //     url: "/update-profile",
    //     method: "put",
    //     // headers: { "Content-Type": "multipart/form-data" },
    //     payload: formData,
    //   },
    //   {
    //     onSuccess: () => {
    //       setIsEditModalVisible(false);
    //       editForm.resetFields();
    //       setEditingUser(null);
    //       invalidate({ resource: "users", invalidates: ["list"] });
    //       message.success("Profile updated successfully!");
    //     },
    //     onError: (error: any) => {
    //       message.error(error?.response?.data?.message || "Update failed");
    //     },
    //   }
    // );
  };

  const openEditModal = (user: User) => {
    setEditingUser(user);
    setIsEditModalVisible(true);
    editForm.setFieldsValue({ firstName: user.firstName });
    editForm.setFieldsValue({ lastName: user.lastName });
    if (user.avatar) {
      setEditFileList([
        {
          uid: "-1",
          name: "avatar",
          status: "done",
          url: user.avatar,
        } as UploadFile,
      ]);
    } else {
      setEditFileList([]);
    }
  };

  return (
    <List
      headerButtons={[
        <Button type="primary" onClick={() => setIsCreateModalVisible(true)}>
          Create User
        </Button>,
      ]}
    >
      {/* CREATE MODAL */}
      <Modal
        title="Create User"
        open={isCreateModalVisible}
        onCancel={() => {
          setIsCreateModalVisible(false);
          createForm.resetFields();
        }}
        footer={null}
      >
        <Form form={createForm} onFinish={handleCreate} layout="vertical">
          <Form.Item
            name="email"
            label="Email"
            rules={[{ required: true, type: "email" }]}
          >
            <Input />
          </Form.Item>
          <Form.Item
            name="username"
            label="Username"
            rules={[{ required: true }]}
          >
            <Input />
          </Form.Item>
          <Form.Item
            name="password"
            label="Password"
            rules={[{ required: true, min: 8 }]}
          >
            <Input.Password />
          </Form.Item>
          <Form.Item
            name="firstName"
            label="First Name"
            rules={[{ required: true }]}
          >
            <Input />
          </Form.Item>
          <Form.Item
            name="lastName"
            label="Last Name"
            rules={[{ required: true }]}
          >
            <Input />
          </Form.Item>
          <Form.Item>
            <Space>
              <Button type="primary" htmlType="submit">
                Create
              </Button>
              <Button onClick={() => setIsCreateModalVisible(false)}>
                Cancel
              </Button>
            </Space>
          </Form.Item>
        </Form>
      </Modal>

      {/* EDIT MODAL */}
      <Modal
        title="Edit User"
        open={isEditModalVisible}
        onCancel={() => {
          setIsEditModalVisible(false);
          editForm.resetFields();
          setEditingUser(null);
        }}
        footer={null}
      >
        <Form form={editForm} onFinish={handleEdit} layout="vertical">
          <Form.Item
            name="firstName"
            label="First Name"
            rules={[{ required: true }]}
          >
            <Input />
          </Form.Item>
          <Form.Item
            name="lastName"
            label="Last Name"
            rules={[{ required: true }]}
          >
            <Input />
          </Form.Item>
          <Form.Item label="Avatar">
            <Upload
              listType="picture"
              maxCount={1}
              fileList={editFileList}
              onChange={({ fileList }) => setEditFileList(fileList)}
              beforeUpload={() => false} // prevent auto-upload
              onRemove={() => {
                editForm.setFieldsValue({ removeAvatar: true });
              }}
            >
              <Button icon={<UploadOutlined />}>Upload Avatar</Button>
            </Upload>
          </Form.Item>
          <Form.Item name="removeAvatar" hidden>
            <Input type="hidden" />
          </Form.Item>
          <Form.Item>
            <Space>
              <Button type="primary" htmlType="submit" loading={editLoading}>
                {editLoading ? "Updating..." : "Update"}
              </Button>
              <Button
                disabled={editLoading}
                onClick={() => setIsEditModalVisible(false)}
              >
                Cancel
              </Button>
            </Space>
          </Form.Item>
        </Form>
      </Modal>

      {/* PASSWORD MODAL */}
      <Modal
        title="Update Password"
        open={isPasswordModalVisible}
        onCancel={() => {
          setIsPasswordModalVisible(false);
          passwordForm.resetFields();
          setSelectedUserId(null);
        }}
        footer={null}
      >
        <Form
          form={passwordForm}
          onFinish={handlePasswordUpdate}
          layout="vertical"
        >
          <Form.Item
            name="currentPassword"
            label="Current Password"
            rules={[
              { required: true, message: "Please input current password!" },
            ]}
          >
            <Input.Password />
          </Form.Item>
          <Form.Item
            name="password"
            label="New Password"
            rules={[
              { required: true, message: "Please input new password!" },
              {
                pattern:
                  /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>]).{8,}$/,
                message:
                  "Password must be at least 8 characters long and include 1 uppercase, 1 lowercase, 1 number, and 1 special character",
              },
            ]}
          >
            <Input.Password />
          </Form.Item>
          <Form.Item
            name="confirmPassword"
            label="Confirm Password"
            dependencies={["password"]}
            rules={[
              { required: true, message: "Please confirm your password!" },
              ({ getFieldValue }) => ({
                validator(_, value) {
                  if (!value || getFieldValue("password") === value) {
                    return Promise.resolve();
                  }
                  return Promise.reject(new Error("Passwords do not match!"));
                },
              }),
            ]}
          >
            <Input.Password />
          </Form.Item>
          <Form.Item>
            <Space>
              <Button
                type="primary"
                htmlType="submit"
                loading={passwordLoading}
              >
                {passwordLoading ? "Updating..." : "Update Password"}
              </Button>
              <Button
                onClick={() => {
                  setIsPasswordModalVisible(false);
                  passwordForm.resetFields();
                  setSelectedUserId(null);
                }}
                disabled={passwordLoading}
              >
                Cancel
              </Button>
            </Space>
          </Form.Item>
        </Form>
      </Modal>

      {/* TABLE */}
      <Table {...tableProps} rowKey="id" size="small">
        <Table.Column<User>
          title="Name"
          render={(_, record) => (
            <Space>
              <Avatar src={record.avatar}>
                {record.avatar ? "" : record.firstName?.[0] || record.email[0]}
              </Avatar>
              <span>
                {`${record.firstName || ""} ${record.lastName || ""}`.trim() ||
                  "—"}
              </span>
            </Space>
          )}
        />
        <Table.Column<User> dataIndex="email" title="Email" />
        <Table.Column<User> dataIndex="username" title="UserName" />
        <Table.Column<User>
          dataIndex="isActive"
          title="Status"
          render={(value: boolean) =>
            value ? (
              <Tag color="green">Active</Tag>
            ) : (
              <Tag color="red">Inactive</Tag>
            )
          }
        />
        <Table.Column<User>
          dataIndex="createdAt"
          title="Created At"
          render={(value: string) => (
            <span>{dayjs(value).format("YYYY-MM-DD HH:mm")}</span>
          )}
        />
        <Table.Column<User>
          fixed="right"
          title="Actions"
          render={(_, record) => (
            <Space>
              <ShowButton size="small" recordItemId={record.id} hideText />
              <EditButton
                size="small"
                hideText
                onClick={() => openEditModal(record)}
              />
              <Button
                size="small"
                onClick={() => {
                  setSelectedUserId(record.id);
                  setIsPasswordModalVisible(true);
                }}
                icon={<LockOutlined />}
              />
            </Space>
          )}
        />
      </Table>
    </List>
  );
};
