import { NextRequest } from "next/server";

const BACKEND_URL = process.env.BACKEND_URL ?? "http://localhost:8000";

type Params = { path: string[] };
type RouteContext = { params: Promise<Params> };

function buildForwardHeaders(req: NextRequest): Headers {
  const h = new Headers();
  const cookie = req.headers.get("cookie");
  if (cookie) h.set("cookie", cookie);

  const contentType = req.headers.get("content-type");
  if (contentType) h.set("content-type", contentType);

  const accept = req.headers.get("accept");
  if (accept) h.set("accept", accept);

  return h;
}

async function proxy(req: NextRequest, ctx: RouteContext) {
  const { path } = await ctx.params; // ✅ Next 16: params ist Promise
  const joined = path.join("/");
  const url = `${BACKEND_URL}/api/${joined}${req.nextUrl.search}`;

  const method = req.method.toUpperCase();
  const hasBody = !["GET", "HEAD"].includes(method);
  const body = hasBody ? new Uint8Array(await req.arrayBuffer()) : undefined;

  const backendRes = await fetch(url, {
    method,
    headers: buildForwardHeaders(req),
    body,
    redirect: "manual",
  });

  const resHeaders = new Headers();
  const setCookie = backendRes.headers.get("set-cookie");
  if (setCookie) resHeaders.set("set-cookie", setCookie);

  const ct = backendRes.headers.get("content-type");
  if (ct) resHeaders.set("content-type", ct);

  return new Response(backendRes.body, {
    status: backendRes.status,
    headers: resHeaders,
  });
}

export const dynamic = "force-dynamic";

export async function GET(req: NextRequest, ctx: RouteContext) {
  return proxy(req, ctx);
}
export async function POST(req: NextRequest, ctx: RouteContext) {
  return proxy(req, ctx);
}
export async function PUT(req: NextRequest, ctx: RouteContext) {
  return proxy(req, ctx);
}
export async function PATCH(req: NextRequest, ctx: RouteContext) {
  return proxy(req, ctx);
}
export async function DELETE(req: NextRequest, ctx: RouteContext) {
  return proxy(req, ctx);
}
