import { Space, Typography } from "antd";

const { Title: AntTitle } = Typography;

export const AppTitle: React.FC = () => {
  return (
    <Space align="center">
      {/* Replace with your logo image */}
      <img
        src="/logo.png"
        alt="Chrysalis"
        style={{ width: 32, height: 32, borderRadius: "50%" }}
      />
      <AntTitle level={5} style={{ margin: 0 }}>
        Chrysalis
      </AntTitle>
    </Space>
  );
};
