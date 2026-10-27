import { useEffect, useState } from 'react';

/** 輸入停下來 delay 毫秒後才更新，搜尋框打字時不會每個字都打一次 API */
export function useDebounced<T>(value: T, delay = 350): T {
  const [debounced, setDebounced] = useState(value);
  useEffect(() => {
    const id = window.setTimeout(() => setDebounced(value), delay);
    return () => window.clearTimeout(id);
  }, [value, delay]);
  return debounced;
}
