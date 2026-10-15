import { useEffect, useState } from "react";

// 載入資料：回傳 { data, loading, error, reload }；deps 變動（例如日期）時自動重抓
export function useAsync(fn, deps = []) {
  const [state, setState] = useState({ data: null, loading: true, error: null });
  const [n, setN] = useState(0);

  useEffect(() => {
    let alive = true;
    setState(s => ({ ...s, loading: true, error: null }));
    fn().then(
      data => alive && setState({ data, loading: false, error: null }),
      error => alive && setState({ data: null, loading: false, error })
    );
    return () => { alive = false; };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [...deps, n]);

  return { ...state, reload: () => setN(x => x + 1) };
}
