import { Refine, Authenticated } from "@refinedev/core";
import { ThemedLayout, useNotificationProvider } from "@refinedev/antd";
import routerBindings, {
  NavigateToResource,
  UnsavedChangesNotifier,
} from "@refinedev/react-router";
import { BrowserRouter, Routes, Route, Outlet } from "react-router";
import { App as AntdApp } from "antd";
import { createDataProvider } from "./providers/data";
import { createAuthProvider } from "./providers/auth";
import { UserList } from "./pages/users/list";
import { GroupList } from "./pages/groups/list";
import { GroupShow } from "./pages/groups/show";
import { AuditLogList } from "./pages/audit-logs/list";
import { LoginPage } from "./pages/auth/login";
import { RefineAiErrorComponent } from "./components/catch-all";
import { UserShow } from "./pages/users/show";
import { AppTitle } from "./components/Title";

const API_URL = import.meta.env.VITE_API_URL as string;

const App = () => {
  return (
    <BrowserRouter>
      <AntdApp>
      <Refine
        routerProvider={routerBindings}
        dataProvider={createDataProvider(API_URL)}
        authProvider={createAuthProvider(API_URL)}
        notificationProvider={useNotificationProvider}
        resources={[
          {
            name: "users",
            list: "/users",
            show: "/users/show/:id",
            edit: "/users/edit/:id",
            create: "/users/create",
          },
          {
            name: "groups",
            list: "/groups",
            show: "/groups/show/:id",
            edit: "/groups/edit/:id",
            create: "/groups/create",
          },
          {
            name: "audit-logs",
            list: "/audit-logs",
            show: "/audit-logs/show/:id",
          },
        ]}
      >
        <Routes>
          {/* Auth routes */}
          <Route
            element={
              <Authenticated key="auth-pages" fallback={<Outlet />}>
                <NavigateToResource resource="users" />
              </Authenticated>
            }
          >
            <Route path="/login" element={<LoginPage />} />
          </Route>

          {/* Protected routes */}
          <Route
            element={
              <Authenticated key="protected-routes">
                <ThemedLayout Title={AppTitle}>
                  <Outlet />
                </ThemedLayout>
              </Authenticated>
            }
          >
            <Route index element={<NavigateToResource resource="users" />} />
            <Route path="/users">
              <Route index element={<UserList />} />
              <Route path="show/:id" element={<UserShow />} />
            </Route>
            <Route path="/groups">
              <Route index element={<GroupList />} />
              <Route path="show/:id" element={<GroupShow />} />
            </Route>
            <Route path="/audit-logs">
              <Route index element={<AuditLogList />} />
            </Route>
            <Route path="*" element={<RefineAiErrorComponent />} />
          </Route>
        </Routes>
        <UnsavedChangesNotifier />
      </Refine>
      </AntdApp>
    </BrowserRouter>
  );
};

export default App;
