import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Games24 Control Center | Super Admin & Live Oversight",
  description: "Executive operations portal for Games24 venue approvals, real-time match tracking, and financial reconciliation.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="en"
      className="dark h-full bg-[#080B11] antialiased"
    >
      <body className="min-h-full flex flex-col bg-[#080B11] text-slate-100 font-sans selection:bg-[#CCFF00]/20 selection:text-[#CCFF00]">
        {children}
      </body>
    </html>
  );
}
