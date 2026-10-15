import { Link } from "react-router-dom";
import { BRAND } from "../config.js";

export default function Brand() {
  return (
    <Link className="brand" to="/">
      <img src="/logo-mark.png" alt={BRAND.name} />
      <span><b>{BRAND.name}</b><small>{BRAND.nameZh}</small></span>
    </Link>
  );
}
