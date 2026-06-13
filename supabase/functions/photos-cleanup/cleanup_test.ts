import { assertEquals } from "std/assert/mod.ts";
import { collectStoragePaths, expirationCutoff } from "./cleanup.ts";

Deno.test("expirationCutoff: 30 日前の ISO 文字列を返す", () => {
  const now = new Date("2026-06-13T00:00:00.000Z");
  assertEquals(expirationCutoff(now, 30), "2026-05-14T00:00:00.000Z");
});

Deno.test("expirationCutoff: 保持日数を変えられる", () => {
  const now = new Date("2026-06-13T12:30:00.000Z");
  assertEquals(expirationCutoff(now, 1), "2026-06-12T12:30:00.000Z");
});

Deno.test("collectStoragePaths: 原寸 + サムネを返す", () => {
  assertEquals(
    collectStoragePaths({ storage_path: "u/a.jpg", thumbnail_path: "u/thumb_a.jpg" }),
    ["u/a.jpg", "u/thumb_a.jpg"],
  );
});

Deno.test("collectStoragePaths: null / 空文字は除外する", () => {
  assertEquals(collectStoragePaths({ storage_path: "u/a.jpg", thumbnail_path: null }), ["u/a.jpg"]);
  assertEquals(collectStoragePaths({ storage_path: "", thumbnail_path: null }), []);
});
