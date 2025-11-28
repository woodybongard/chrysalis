// src/providers/dataProvider.ts
import { DataProvider } from "@refinedev/core";
import axios, { AxiosError } from "axios";

export const createDataProvider = (apiUrl: string): DataProvider => {
  const axiosInstance = axios.create({
    baseURL: apiUrl,
  });

  axiosInstance.interceptors.request.use((config) => {
    const token = localStorage.getItem("accessToken");
    if (token) {
      config.headers["Authorization"] = `Bearer ${token}`;
    }
    return config;
  });

  return {
    getApiUrl: () => apiUrl,

    getList: async ({ resource, pagination }) => {
      const { currentPage = 1, pageSize = 10 } = pagination ?? {};

      const response = await axiosInstance.get(`${resource}`, {
        params: { page: currentPage, limit: pageSize },
      });

      // 🔑 handle both users & groups
      let data = response.data.data || response.data.groups || [];
      let total = response.data.pagination?.total || response.data.total || 0;

      // 🔄 normalize groups
      if (resource === "groups") {
        data = data.map((g: any) => ({
          ...g,
          members: g._count?.members ?? 0, // refine expects "members" directly
          isArchived: g.archived, // rename for frontend
        }));
      }

      console.log("DataProvider getList:", { resource, data, total });

      return { data, total };
    },

    getOne: async ({ resource, id }) => {
      if (resource === "users") {
        // ✅ your custom user-details endpoint
        const response = await axiosInstance.get(
          `${resource}/user-details/${id}`
        );
        return { data: response.data.data };
      }

      if (resource === "groups") {
        // ✅ your existing group-specific logic
        const response = await axiosInstance.get(`${resource}/${id}`);
        return {
          data: {
            ...response.data.group,
            isArchived: response.data.group.archived,
          },
        };
      }

      // ✅ default for all other resources
      const response = await axiosInstance.get(`${resource}/${id}`);
      return { data: response.data.data };
    },

    create: async ({ resource, variables }) => {
      try {
        const response = await axiosInstance.post(`${resource}`, variables);
        return { data: response.data.data };
      } catch (error) {
        const axiosError = error as AxiosError;
        // Throw error with response data attached
        const customError = new Error(
          axiosError.response?.statusText || "Request failed"
        ) as any;
        customError.response = axiosError.response;
        throw customError;
      }
    },

    update: async ({ resource, id, variables }) => {
      const response = await axiosInstance.patch(
        `${resource}/${id}`,
        variables
      );
      return { data: response.data.data };
    },

    deleteOne: async ({ resource, id }) => {
      const response = await axiosInstance.delete(`${resource}/${id}`);
      return { data: response.data.data };
    },

    custom: async ({ url, method, headers, payload, query, meta }) => {
      try {
        const params = query || meta?.query;
        console.log("Custom request params:", { url, method, payload, query, meta, params });

        const response = await axiosInstance.request({
          url,
          method,
          headers,
          data: payload,
          params,
        });

        console.log("Custom request response:", response.data);

        return { data: response.data };
      } catch (error) {
        const axiosError = error as AxiosError;
        console.error("Custom request error:", axiosError.response?.data);
        // Throw error with response data attached for proper error handling
        const customError = new Error(
          axiosError.response?.statusText || "Request failed"
        ) as any;
        customError.response = axiosError.response;
        throw customError;
      }
    },
  };
};
