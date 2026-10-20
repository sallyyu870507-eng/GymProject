/** .env 的 VITE_USE_MOCK=true 時，所有 API 都回傳 src/mocks 的示範資料 */
export const USE_MOCK = import.meta.env.VITE_USE_MOCK === 'true';

export const sleep = (ms: number) => new Promise<void>((resolve) => setTimeout(resolve, ms));

/**
 * 每支 API 都用這個包起來。
 * @param real  真的呼叫後端
 * @param mock  示範資料
 * @param ready 後端已經有這支 API 嗎？false 時就算關掉示範模式也繼續用示範資料。
 *              後端做好之後改成 true（或直接刪掉這個參數）即可。
 */
export async function withMock<T>(real: () => Promise<T>, mock: () => T, ready = true): Promise<T> {
  if (!USE_MOCK && ready) return real();
  await sleep(200 + Math.random() * 300);
  return structuredClone(mock());
}
