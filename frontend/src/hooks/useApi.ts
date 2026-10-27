import { useCallback, useEffect, useState } from 'react';

export interface ApiState<T> {
  data?: T;
  error?: Error;
  loading: boolean;
  reload: () => void;
}

/**
 * 呼叫 API 並管理 loading / error / data。
 *   const courses = useApi((signal) => memberApi.courses(signal), []);
 * deps 改變時會重新呼叫，舊的請求會被取消。
 */
export function useApi<T>(fetcher: (signal: AbortSignal) => Promise<T>, deps: unknown[]): ApiState<T> {
  const [state, setState] = useState<Omit<ApiState<T>, 'reload'>>({ loading: true });
  const [version, setVersion] = useState(0);

  useEffect(() => {
    const controller = new AbortController();
    setState((prev) => ({ ...prev, loading: true, error: undefined }));
    fetcher(controller.signal)
      .then((data) => {
        if (!controller.signal.aborted) setState({ data, loading: false });
      })
      .catch((error: Error) => {
        if (!controller.signal.aborted && error.name !== 'AbortError') setState({ error, loading: false });
      });
    return () => controller.abort();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [...deps, version]);

  const reload = useCallback(() => setVersion((v) => v + 1), []);
  return { ...state, reload };
}

/** 每隔一段時間更新一次「現在時間」，用來刷新倒數與進行中狀態 */
export function useNow(intervalMs = 60_000): Date {
  const [now, setNow] = useState(() => new Date());
  useEffect(() => {
    const id = window.setInterval(() => setNow(new Date()), intervalMs);
    return () => window.clearInterval(id);
  }, [intervalMs]);
  return now;
}
