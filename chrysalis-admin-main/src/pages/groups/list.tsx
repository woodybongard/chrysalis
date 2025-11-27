import React, { useState, useEffect } from "react";
import {
  useTable,
  List,
  EditButton,
  ShowButton,
  FilterDropdown,
} from "@refinedev/antd";
import { useCustomMutation, useInvalidate, useList } from "@refinedev/core";
import {
  Button,
  Table,
  Space,
  Input,
  DatePicker,
  Tooltip,
  Modal,
  notification,
  Tag,
  App,
  Form,
  Upload,
  Select,
  Avatar,
} from "antd";
import type { Group } from "../../types";
import type { BaseRecord } from "@refinedev/core";
import {
  SearchOutlined,
  InboxOutlined,
  UploadOutlined,
  PlusOutlined,
  EditOutlined,
} from "@ant-design/icons";
import type { UploadFile } from "antd/es/upload/interface";
import dayjs from "dayjs";

interface User extends BaseRecord {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
}

export const GroupList: React.FC = (): React.ReactNode => {
  const invalidate = useInvalidate();
  const { modal } = App.useApp();
  const [isCreateModalVisible, setIsCreateModalVisible] = useState(false);
  const [creating, setCreating] = useState(false);
  const [fileList, setFileList] = useState<UploadFile[]>([]);
  const [editModalVisible, setEditModalVisible] = useState(false);
  const [editLoading, setEditLoading] = useState(false);
  const [editingGroup, setEditingGroup] = useState<Group | null>(null);
  const [editFileList, setEditFileList] = useState<UploadFile[]>([]);

  const [createForm] = Form.useForm();
  const [editForm] = Form.useForm();

  const { tableProps } = useTable<Group>({
    syncWithLocation: true,
  });

  // Users for dropdown (if needed for create modal)
  const { result, isLoading: usersLoading } = useList<User>({
    resource: "users",
    queryOptions: { enabled: isCreateModalVisible },
  });
  const users = result?.data ?? [];

  // Create group
  const { mutate: createMutate } = useCustomMutation();
  const handleCreate = async (values: { name: string; members?: string[] }) => {
    setCreating(true);
    const formData = new FormData();
    formData.append("name", values.name);
    if (values.members) formData.append("members", values.members.join(","));
    if (fileList[0]?.originFileObj)
      formData.append("profileImg", fileList[0].originFileObj);

    await createMutate(
      { url: "/groups", method: "post", values: formData },
      {
        onSuccess: () => {
          setIsCreateModalVisible(false);
          createForm.resetFields();
          setFileList([]);
          notification.success({ message: "Group created successfully" });
          invalidate({ resource: "groups", invalidates: ["list"] });
        },
        onError: () =>
          notification.error({ message: "Failed to create group" }),
        onSettled: () => setCreating(false),
      }
    );
  };

  // Archive / unarchive group
  const { mutate: archiveMutate } = useCustomMutation();
  const handleArchive = (id: string, archive: boolean) => {
    modal.confirm({
      title: archive ? "Archive Group" : "Unarchive Group",
      content: `Are you sure you want to ${
        archive ? "archive" : "unarchive"
      } this group?`,
      onOk: async () => {
        await archiveMutate(
          {
            url: `/groups/${id}/${archive ? "archive" : "unarchive"}`,
            method: "patch",
            values: {},
          },
          {
            onSuccess: () => {
              invalidate({ resource: "groups", invalidates: ["list"] });
              notification.success({
                message: `Group ${
                  archive ? "archived" : "unarchived"
                } successfully`,
              });
            },
            onError: () =>
              notification.error({ message: "Failed to update group status" }),
          }
        );
      },
    });
  };

  // Edit group API
  const { mutate: editMutate } = useCustomMutation();
  const handleEdit = async (values: {
    name: string;
    removeProfileImg?: boolean;
  }) => {
    if (!editingGroup) return;
    setEditLoading(true);

    const formData = new FormData();
    formData.append("name", values.name);

    if (editFileList[0]?.originFileObj)
      formData.append("profileImg", editFileList[0].originFileObj);

    if (values.removeProfileImg) formData.append("removeProfileImg", "true");

    try {
      await new Promise<void>((resolve, reject) => {
        editMutate(
          {
            url: `/groups/${editingGroup.id}`,
            method: "patch",
            values: formData,
          },
          {
            onSuccess: () => {
              setEditModalVisible(false);
              setEditingGroup(null);
              setEditFileList([]);
              editForm.resetFields();
              notification.success({ message: "Group updated successfully" });
              invalidate({ resource: "groups", invalidates: ["list"] });
              resolve();
            },
            onError: (error) => {
              notification.error({ message: "Failed to update group" });
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
  };

  const openEditModal = (group: Group) => {
    setEditingGroup(group);
    setEditModalVisible(true);
    editForm.setFieldsValue({ name: group.name });
    if (group.profileImg) {
      setEditFileList([
        {
          uid: "-1",
          name: "profileImg",
          status: "done",
          url: group.profileImg,
        } as UploadFile,
      ]);
    } else {
      setEditFileList([]);
    }
  };

  return (
    <List
      headerButtons={[
        <Button
          key="create"
          type="primary"
          icon={<PlusOutlined />}
          onClick={() => setIsCreateModalVisible(true)}
        >
          Create Group
        </Button>,
      ]}
    >
      {/* Create Modal (simplified) */}
      <Modal
        title="Create Group"
        open={isCreateModalVisible}
        onCancel={() => {
          setIsCreateModalVisible(false);
          createForm.resetFields();
          setFileList([]);
        }}
        footer={null}
      >
        <Form form={createForm} onFinish={handleCreate} layout="vertical">
          <Form.Item
            name="name"
            label="Group Name"
            rules={[{ required: true }]}
          >
            <Input placeholder="Enter group name" />
          </Form.Item>
          <Form.Item
            name="members"
            label="Members"
            rules={[
              { required: true, message: "Please select at least one member" },
            ]}
          >
            <Select
              mode="multiple"
              placeholder={usersLoading ? "Loading users..." : "Select members"}
              loading={usersLoading}
              optionFilterProp="children"
            >
              {users.map((user: User) => (
                <Select.Option key={user.id} value={user.id}>
                  {`${user.firstName} ${user.lastName} (${user.email})`}
                </Select.Option>
              ))}
            </Select>
          </Form.Item>
          <Form.Item label="Profile Image">
            <Upload
              listType="picture"
              maxCount={1}
              fileList={fileList}
              onChange={({ fileList }) => setFileList(fileList)}
              beforeUpload={() => false}
            >
              <Button icon={<UploadOutlined />}>Click to Upload</Button>
            </Upload>
          </Form.Item>
          <Form.Item>
            <Space>
              <Button type="primary" htmlType="submit" loading={creating}>
                Create
              </Button>
              <Button
                disabled={creating}
                onClick={() => {
                  setIsCreateModalVisible(false);
                  createForm.resetFields();
                  setFileList([]);
                }}
              >
                Cancel
              </Button>
            </Space>
          </Form.Item>
        </Form>
      </Modal>

      {/* Edit Modal */}
      <Modal
        title="Edit Group"
        open={editModalVisible}
        onCancel={() => {
          setEditModalVisible(false);
          setEditingGroup(null);
          setEditFileList([]);
          editForm.resetFields();
        }}
        footer={null}
      >
        <Form form={editForm} onFinish={handleEdit} layout="vertical">
          <Form.Item
            name="name"
            label="Group Name"
            rules={[{ required: true }]}
          >
            <Input placeholder="Enter group name" />
          </Form.Item>

          <Form.Item label="Profile Image">
            <Upload
              listType="picture"
              maxCount={1}
              fileList={editFileList}
              onChange={({ fileList }) => setEditFileList(fileList)}
              beforeUpload={() => false}
              onRemove={() => {
                editForm.setFieldsValue({ removeProfileImg: true });
              }}
            >
              <Button icon={<UploadOutlined />}>Click to Upload</Button>
            </Upload>
          </Form.Item>

          <Form.Item name="removeProfileImg" valuePropName="checked" hidden>
            <Input type="hidden" />
          </Form.Item>

          <Form.Item>
            <Space>
              <Button type="primary" htmlType="submit" loading={editLoading}>
                Update
              </Button>
              <Button
                disabled={editLoading}
                onClick={() => {
                  setEditModalVisible(false);
                  setEditingGroup(null);
                  setEditFileList([]);
                  editForm.resetFields();
                }}
              >
                Cancel
              </Button>
            </Space>
          </Form.Item>
        </Form>
      </Modal>

      {/* Table */}
      <Table {...tableProps} rowKey="id" size="small">
        <Table.Column
          dataIndex="name"
          title="Name"
          render={(text: string, record: Group) => (
            <Space>
              <Avatar src={record.profileImg}>{record.name?.[0]}</Avatar>
              {text}
            </Space>
          )}
          filterDropdown={(props) => (
            <FilterDropdown {...props}>
              <Input prefix={<SearchOutlined />} placeholder="Search name" />
            </FilterDropdown>
          )}
        />
        <Table.Column dataIndex="members" title="Members" render={(m) => m} />
        <Table.Column
          dataIndex="isArchived"
          title="Status"
          render={(isArchived: boolean) => (
            <Tag color={isArchived ? "red" : "green"}>
              {isArchived ? "Archived" : "Active"}
            </Tag>
          )}
        />
        <Table.Column
          dataIndex="createdAt"
          title="Created At"
          render={(v: string) => dayjs(v).format("YYYY-MM-DD HH:mm")}
          filterDropdown={(props) => (
            <FilterDropdown {...props}>
              <DatePicker.RangePicker />
            </FilterDropdown>
          )}
          sorter
        />
        <Table.Column
          fixed="right"
          title="Actions"
          render={(_: any, record: Group) => (
            <Space>
              <ShowButton size="small" recordItemId={record.id} hideText />
              <Button
                size="small"
                icon={<EditOutlined />}
                onClick={() => openEditModal(record)}
              />
              <Tooltip title={record.isArchived ? "Unarchive" : "Archive"}>
                <Button
                  size="small"
                  type={record.isArchived ? "default" : "primary"}
                  icon={<InboxOutlined />}
                  onClick={() => handleArchive(record.id, !record.isArchived)}
                  danger={!record.isArchived}
                />
              </Tooltip>
            </Space>
          )}
        />
      </Table>
    </List>
  );
};
