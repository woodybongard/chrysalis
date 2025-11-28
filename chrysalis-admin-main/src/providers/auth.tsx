import type { AuthProvider } from "@refinedev/core";
import axios from "axios";

type LoginVariables = {
  email: string;
  password: string;
};

type Tokens = {
  accessToken: string;
  refreshToken: string;
  expiresAt: string;
};

type User = {
  id: string;
  email: string;
  role?: string;
  [key: string]: any; // in case backend sends more fields
};

type LoginResponse = {
  data: {
    tokens: Tokens;
    user: User;
  };
};

export const createAuthProvider = (apiUrl: string): AuthProvider => {
  return {
    login: async ({ email, password }: LoginVariables) => {
      try {
        const { data } = await axios.post<LoginResponse>(
          `${apiUrl}/auth/login`,
          {
            login: email,
            password,
          }
        );

        const { accessToken, refreshToken, expiresAt } = data?.data?.tokens;
        const user = data?.data?.user;
        if (user.role !== "ADMIN" && user.role !== "SUPERADMIN") {
          return {
            success: false,
            error: new Error("Unauthorized role"),
          };
        }
        localStorage.setItem("accessToken", accessToken);
        localStorage.setItem("refreshToken", refreshToken);
        localStorage.setItem("expiresAt", expiresAt);

        // store user info (optional, for role/permissions later)
        localStorage.setItem("user", JSON.stringify(data.data.user));

        // Set default auth header
        axios.defaults.headers.common = {
          Authorization: `Bearer ${accessToken}`,
        };

        return {
          success: true,
          redirectTo: "/users",
        };
      } catch (error) {
        return {
          success: false,
          error: new Error("Invalid credentials"),
        };
      }
    },
    check: async () => {
      const token = localStorage.getItem("accessToken");

      if (!token) {
        return {
          authenticated: false,
          error: new Error("Not authenticated"),
          logout: true,
          redirectTo: "/login",
        };
      }

      return {
        authenticated: true,
      };
    },
    logout: async () => {
      localStorage.removeItem("accessToken");
      localStorage.removeItem("refreshToken");

      return {
        success: true,
        redirectTo: "/login",
      };
    },
    onError: async (error) => {
      if (error.status === 401 || error.status === 403) {
        return {
          logout: true,
          redirectTo: "/login",
          error: new Error("Unauthorized"),
        };
      }

      return {};
    },
    getPermissions: async () => {
      const token = localStorage.getItem("token");
      if (!token) return null;
      return null;
    },
  };
};
