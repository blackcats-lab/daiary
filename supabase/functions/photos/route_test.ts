import { assertEquals } from "std/assert/mod.ts";
import { resolvePhotosRoute } from "./validation.ts";

Deno.test("resolvePhotosRoute: 本番パスの一覧", () => {
  assertEquals(resolvePhotosRoute("/functions/v1/photos"), { kind: "collection" });
});

Deno.test("resolvePhotosRoute: ローカル serve パスの一覧", () => {
  assertEquals(resolvePhotosRoute("/photos"), { kind: "collection" });
});

Deno.test("resolvePhotosRoute: 末尾スラッシュを許容", () => {
  assertEquals(resolvePhotosRoute("/functions/v1/photos/"), { kind: "collection" });
});

Deno.test("resolvePhotosRoute: タグ集約", () => {
  assertEquals(resolvePhotosRoute("/functions/v1/photos/tags"), { kind: "tags" });
});

Deno.test("resolvePhotosRoute: ID 指定", () => {
  assertEquals(
    resolvePhotosRoute("/functions/v1/photos/123e4567-e89b-12d3-a456-426614174000"),
    { kind: "photo", id: "123e4567-e89b-12d3-a456-426614174000" },
  );
});

Deno.test("resolvePhotosRoute: 復元", () => {
  assertEquals(
    resolvePhotosRoute("/functions/v1/photos/123e4567-e89b-12d3-a456-426614174000/restore"),
    { kind: "restore", id: "123e4567-e89b-12d3-a456-426614174000" },
  );
});

Deno.test("resolvePhotosRoute: 不明なサブパスは unknown", () => {
  assertEquals(
    resolvePhotosRoute("/functions/v1/photos/123e4567-e89b-12d3-a456-426614174000/unknown"),
    { kind: "unknown" },
  );
});

Deno.test("resolvePhotosRoute: 深すぎるパスは unknown", () => {
  assertEquals(
    resolvePhotosRoute("/functions/v1/photos/a/b/c"),
    { kind: "unknown" },
  );
});

Deno.test("resolvePhotosRoute: photos セグメントが無ければ unknown", () => {
  assertEquals(resolvePhotosRoute("/functions/v1/albums"), { kind: "unknown" });
});
