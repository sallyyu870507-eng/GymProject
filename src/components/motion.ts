import { useEffect, useState } from 'react';

/** 使用者是否在系統設定開了「減少動態效果」 */
export function prefersReducedMotion(): boolean {
  return typeof window !== 'undefined' && window.matchMedia?.('(prefers-reduced-motion: reduce)').matches;
}

/**
 * 數字從 0 跳到目標值（只在畫面第一次出現或數值改變時跑一次）。
 * decimals：小數位數，例如體重 60.3 → 1。
 */
export function useCountUp(target: number | null | undefined, { duration = 900, delay = 0, decimals = 0 } = {}) {
  const [value, setValue] = useState<number | null>(target ?? null);

  useEffect(() => {
    if (target == null) {
      setValue(null);
      return;
    }
    if (prefersReducedMotion()) {
      setValue(target);
      return;
    }
    let raf = 0;
    let start = 0;
    const tick = (t: number) => {
      if (!start) start = t + delay;
      const p = Math.min(1, Math.max(0, (t - start) / duration));
      const eased = 1 - Math.pow(1 - p, 3);
      setValue(target * eased);
      if (p < 1) raf = requestAnimationFrame(tick);
    };
    setValue(0);
    raf = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf);
  }, [target, duration, delay]);

  if (value == null) return '—';
  return value.toFixed(decimals);
}
