import { useLogin } from "@refinedev/core";
import {
  Row,
  Col,
  Layout,
  Card,
  Typography,
  Form,
  Input,
  Button,
  theme,
} from "antd";
import { useEffect, useState } from "react";

const { Text, Title } = Typography;
const { Content } = Layout;

export const LoginPage = () => {
  const [form] = Form.useForm();
  const { token } = theme.useToken();

  const { mutate: login } = useLogin();
  const [isLoading, setIsLoading] = useState(false);

  useEffect(() => {
    // If there's an error message from previous login attempt, clear it
    form.setFields([
      {
        name: "email",
        errors: [],
      },
      {
        name: "password",
        errors: [],
      },
    ]);
  }, [form]);

  const handleSubmit = async (values: { email: string; password: string }) => {
    setIsLoading(true);
    try {
      await login(values);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <Layout
      style={{ minHeight: "100vh", backgroundColor: token.colorBgContainer }}
    >
      <Content>
        <Row
          justify="center"
          align="middle"
          style={{
            height: "100vh",
          }}
        >
          <Col xs={22} sm={18} md={12} lg={8} xl={6}>
            <div style={{ textAlign: "center", marginBottom: "32px" }}>
              <img
                src="/logo.png" // Make sure to place your logo.png in the public folder
                alt="Chrysalis Logo"
                style={{ maxWidth: "150px", marginBottom: "24px" }}
              />
              <Title level={2}>Chrysalis</Title>
            </div>
            <Card
              style={{
                boxShadow: "0px 2px 8px rgba(0, 0, 0, 0.15)",
              }}
            >
              <Form<{ email: string; password: string }>
                layout="vertical"
                form={form}
                onFinish={handleSubmit}
                requiredMark={false}
                initialValues={{
                  remember: false,
                }}
              >
                <Form.Item
                  name="email"
                  label="Email"
                  rules={[
                    { required: true, message: "Email is required" },
                    { type: "email", message: "Invalid email address" },
                  ]}
                >
                  <Input size="large" placeholder="Enter your email" />
                </Form.Item>
                <Form.Item
                  name="password"
                  label="Password"
                  rules={[{ required: true, message: "Password is required" }]}
                >
                  <Input.Password size="large" placeholder="●●●●●●●●" />
                </Form.Item>
                <Button
                  type="primary"
                  size="large"
                  htmlType="submit"
                  loading={isLoading}
                  block
                  style={{ marginTop: "24px" }}
                >
                  Sign in
                </Button>
              </Form>
            </Card>
          </Col>
        </Row>
      </Content>
    </Layout>
  );
};
