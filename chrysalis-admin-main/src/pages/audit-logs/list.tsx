import { Table, Typography } from "antd";
import { useQuery } from "@tanstack/react-query";
import { FC } from "react";
import { fetchAuditLogs } from "../../providers/auditLogs";
import { AuditLog } from "../../types";
import { format } from "date-fns";

export const AuditLogList: FC = () => {
  const { data: auditLogs, isLoading } = useQuery({
    queryKey: ["audit-logs"],
    queryFn: () => fetchAuditLogs(),
  });

  const columns = [
    {
      title: "Event Type",
      dataIndex: "eventType",
      key: "eventType",
    },
    {
      title: "Actor",
      dataIndex: "actor",
      key: "actor",
      render: (actor: AuditLog["actor"]) =>
        `${actor.firstName} ${actor.lastName}`,
    },
    {
      title: "Group",
      dataIndex: "group",
      key: "group",
      render: (group: AuditLog["group"]) => group?.name || "-",
    },
    {
      title: "Message Type",
      dataIndex: "metadata",
      key: "messageType",
      render: (metadata: AuditLog["metadata"]) => metadata.type,
    },
    {
      title: "Created At",
      dataIndex: "createdAt",
      key: "createdAt",
      render: (date: string) => format(new Date(date), "PPp"),
    },
  ];

  return (
    <>
      <Typography.Title level={3}>Audit Logs</Typography.Title>
      <Table
        dataSource={auditLogs?.logs}
        columns={columns}
        size="small"
        rowKey="id"
        loading={isLoading}
        pagination={{
          total: auditLogs?.total,
          pageSize: auditLogs?.limit,
          current: auditLogs?.page,
        }}
      />
    </>
  );
};

export default AuditLogList;
