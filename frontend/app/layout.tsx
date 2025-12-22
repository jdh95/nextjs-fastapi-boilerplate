import type { Metadata } from "next";

const appName = process.env.NEXT_PUBLIC_APP_NAME ?? "App";

export const metadata: Metadata = {
  title: appName,
  description: `${appName} Webapp`,
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="de">
      <body>{children}</body>
    </html>
  );
}
