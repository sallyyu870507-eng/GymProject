/**
 * 型別宣告：讓 TypeScript 可以使用組員的 Sidebar.jsx（feature/frontend-fangyu）。
 * Sidebar.jsx 與 Sidebar.css 直接沿用組員的檔案，不要修改。
 */
import type { JSX } from 'react';

export interface SidebarProps {
  /** 'member' | 'coach' | 'admin'；登入後 Sidebar 會用 /api/user 的 role 覆蓋 */
  role?: 'member' | 'coach' | 'admin';
  /** 目前頁面的選單 key，例如 'home' */
  activeItem?: string;
  /** 點選單時呼叫，參數是選單 key */
  onNavigate?: (key: string) => void;
}

declare function Sidebar(props: SidebarProps): JSX.Element;
export default Sidebar;
