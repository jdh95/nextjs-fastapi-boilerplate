import { redirect } from "next/navigation";
import { headers } from "next/headers";
import LogoutButton from "../components/LogoutButton";

export default async function AppPage() {
  const cookie = (await headers()).get("cookie") ?? "";

  const res = await fetch("http://localhost:3000/api/me", {
    cache: "no-store",
    headers: { cookie },
  });

  if (res.status === 401) redirect("/login");

  const data = await res.json();

  return (
    <div style={{ maxWidth: 700, margin: "40px auto" }}>
      <h1>App</h1>
      <p>Eingeloggt. User-ID: {data.user_id}</p>
      <LogoutButton />
    </div>
  );
}
