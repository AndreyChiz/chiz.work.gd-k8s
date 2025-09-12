# Идентифифкация авторизации пользователя.

### Цель

Сделать так чтобы приложение понимало авторизирован ли текущий пользователь на сервере.

### Задача

- создать запрос GET /api/me который возвращает либо json с данными пользователя, либо 401 Unauthorized
- создать состояние приложения Auth
- создать механизм для обновления состояния по требованию

### Требования

- axios
- redux

Tags: Auth redux axios


### Решение GPT-5

Отлично 💪 Тогда перепишем на Redux Toolkit, чтобы хранить данные авторизации централизованно.
Это чуть более «enterprise-way», чем Context, и сразу готово для масштабирования.

1. Установка Redux Toolkit и React Redux

```sh 
yarn add @reduxjs/toolkit react-redux
```

2. Создаём authSlice

src/store/authSlice.ts
```ts
import { createSlice, createAsyncThunk } from "@reduxjs/toolkit";
import api from "../api";

interface User {
  id: number;
  username: string;
  email: string;
}

interface AuthState {
  user: User | null;
  loading: boolean;
  error: string | null;
}

const initialState: AuthState = {
  user: null,
  loading: false,
  error: null,
};

// Асинхронный экшен: получить текущего пользователя
export const fetchMe = createAsyncThunk("auth/fetchMe", async (_, thunkAPI) => {
  try {
    const res = await api.get<User>("/api/me");
    return res.data;
  } catch (err: any) {
    return thunkAPI.rejectWithValue(err.response?.data?.detail || "Unauthorized");
  }
});

const authSlice = createSlice({
  name: "auth",
  initialState,
  reducers: {
    logout(state) {
      state.user = null;
      state.error = null;
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetchMe.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(fetchMe.fulfilled, (state, action) => {
        state.user = action.payload;
        state.loading = false;
      })
      .addCase(fetchMe.rejected, (state, action) => {
        state.user = null;
        state.loading = false;
        state.error = action.payload as string;
      });
  },
});

export const { logout } = authSlice.actions;
export default authSlice.reducer;
```
3. Настройка Redux Store

src/store/index.ts  
```ts
import { configureStore } from "@reduxjs/toolkit";
import authReducer from "./authSlice";

export const store = configureStore({
  reducer: {
    auth: authReducer,
  },
});

export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;

```

4. Оборачиваем приложение в Provider

src/main.tsx
```sh
import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App";
import { Provider } from "react-redux";
import { store } from "./store";

ReactDOM.createRoot(document.getElementById("root")!).render(
  <Provider store={store}>
    <App />
  </Provider>
);

```


5. Использование авторизации в компоненте

src/App.tsx

```sh

import { useEffect } from "react";
import { useSelector, useDispatch } from "react-redux";
import { fetchMe, logout } from "./store/authSlice";
import type { RootState, AppDispatch } from "./store";

export default function App() {
  const dispatch = useDispatch<AppDispatch>();
  const { user, loading, error } = useSelector((state: RootState) => state.auth);

  useEffect(() => {
    dispatch(fetchMe());
  }, [dispatch]);

  if (loading) return <p>Загрузка...</p>;
  if (error) return <p className="text-red-500">Ошибка: {error}</p>;

  return (
    <div className="p-4">
      {user ? (
        <>
          <h1>Добро пожаловать, {user.username}!</h1>
          <button
            className="mt-2 px-4 py-2 bg-gray-200 rounded"
            onClick={() => dispatch(logout())}
          >
            Выйти
          </button>
        </>
      ) : (
        <h1>Вы не авторизованы</h1>
      )}
    </div>
  );
}

```

6. Плюс: Автоматическая обработка 401 через axios interceptor

src/api.ts

```sh
    import axios from "axios";
import { store } from "./store";
import { logout } from "./store/authSlice";

const api = axios.create({
  baseURL: "http://localhost:8000",
  headers: { "Content-Type": "application/json" },
  withCredentials: true, // нужно для передачи cookie
});

api.interceptors.response.use(
  (res) => res,
  (err) => {
    if (err.response?.status === 401) {
      store.dispatch(logout());
    }
    return Promise.reject(err);
  }
);

export default api;

```

Теперь логика простая:

При загрузке приложения → fetchMe() вызывает GET /api/me.

Если сервер вернул 200 → сохраняем user в Redux.

Если сервер вернул 401 → user = null, фронт считает, что не авторизован.

Если где-то в запросах поймали 401, axios interceptor автоматически диспатчит logout().