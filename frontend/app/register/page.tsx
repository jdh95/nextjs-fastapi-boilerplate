"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

export default function RegisterPage() {
  const router = useRouter();
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);

    const res = await fetch("/api/auth/register", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      credentials: "include",
      body: JSON.stringify({ name, email, password }),
    });

    if (!res.ok) {
      const msg = await res.text();
      setError(msg || "Registrierung fehlgeschlagen");
      return;
    }

    // Optional: direkt zu /app oder erst zu /login
    router.push("/app");
  }

  return (
    <div style={{ maxWidth: 420, margin: "40px auto" }}>
      <h1>Registrieren</h1>
      <form onSubmit={onSubmit}>
        <label>Name</label>
        <input value={name} onChange={(e) => setName(e.target.value)} style={{ width: "100%" }} />
        <label>E-Mail</label>
        <input value={email} onChange={(e) => setEmail(e.target.value)} style={{ width: "100%" }} />
        <label>Passwort</label>
        <input type="password" value={password} onChange={(e) => setPassword(e.target.value)} style={{ width: "100%" }} />
        <button style={{ marginTop: 12 }}>Account erstellen</button>
        {error && <p style={{ marginTop: 12 }}>{error}</p>}
      </form>
    </div>
  );
}
