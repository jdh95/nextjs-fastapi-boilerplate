"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setLoading(true);

    const res = await fetch("/api/auth/login", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      // credentials ist hier optional, weil same-origin,
      // aber schadet nicht:
      credentials: "include",
      body: JSON.stringify({ email, password }),
    });

    setLoading(false);

    if (!res.ok) {
      const msg = await res.text();
      setError(msg || "Login fehlgeschlagen");
      return;
    }

    router.push("/app");
  }

  return (
    <div style={{ maxWidth: 420, margin: "40px auto" }}>
      <h1>Login</h1>
      <form onSubmit={onSubmit}>
        <label>E-Mail</label>
        <input value={email} onChange={(e) => setEmail(e.target.value)} style={{ width: "100%" }} />
        <label>Passwort</label>
        <input type="password" value={password} onChange={(e) => setPassword(e.target.value)} style={{ width: "100%" }} />
        <button disabled={loading} style={{ marginTop: 12 }}>
          {loading ? "..." : "Einloggen"}
        </button>
        {error && <p style={{ marginTop: 12 }}>{error}</p>}
      </form>
    </div>
  );
}
