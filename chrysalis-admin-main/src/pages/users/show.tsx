import { Show } from "@refinedev/antd";
import { useShow } from "@refinedev/core";
import { Typography, Descriptions, Avatar, Tag } from "antd";
import type { User } from "../../types";
import dayjs from "dayjs";

const { Title } = Typography;

export const UserShow = () => {
  const { query } = useShow<User>({
    resource: "users",
    meta: {
      // override URL to hit `/users/user-details/:id`
      url: (id: any) => `/users/user-details/${id}`,
    },
  });

  const { data, isLoading } = query;
  const record = data?.data;

  return (
    <Show isLoading={isLoading} canEdit={false}>
      {record && (
        <>
          <div
            style={{ display: "flex", alignItems: "center", marginBottom: 24 }}
          >
            <Avatar size={64} src={record.avatar} style={{ marginRight: 16 }}>
              {!record.avatar &&
                (record.firstName?.[0] || record.email?.[0] || "U")}
            </Avatar>
            <Title level={4}>
              {`${record.firstName || ""} ${record.lastName || ""}`.trim() ||
                record.username}
            </Title>
          </div>

          <Descriptions bordered column={1}>
            <Descriptions.Item label="Email">{record.email}</Descriptions.Item>
            <Descriptions.Item label="Username">
              {record.username}
            </Descriptions.Item>
            <Descriptions.Item label="Role">
              <Tag color="blue">{record.role}</Tag>
            </Descriptions.Item>
            <Descriptions.Item label="Status">
              {record.isActive ? (
                <Tag color="green">Active</Tag>
              ) : (
                <Tag color="red">Inactive</Tag>
              )}
            </Descriptions.Item>
            <Descriptions.Item label="Created At">
              {dayjs(record.createdAt).format("YYYY-MM-DD HH:mm")}
            </Descriptions.Item>
            <Descriptions.Item label="First Name">
              {record.firstName}
            </Descriptions.Item>
            <Descriptions.Item label="Last Name">
              {record.lastName}
            </Descriptions.Item>
          </Descriptions>
        </>
      )}
    </Show>
  );
};
