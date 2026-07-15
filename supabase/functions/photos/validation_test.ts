import { assertEquals } from "std/assert/mod.ts";
import {
  aiTagsError,
  altTextError,
  captionError,
  clampLimit,
  DEFAULT_LIMIT,
  isUuid,
  MAX_LIMIT,
  normalizeTagQuery,
  positiveIntError,
  storagePathError,
} from "./validation.ts";

// --- normalizeTagQuery -------------------------------------------------------

Deno.test("normalizeTagQuery: trim して返す", () => {
  assertEquals(normalizeTagQuery("  #夕焼け  "), "#夕焼け");
});

Deno.test("normalizeTagQuery: # は strip しない（保存値そのまま完全一致のため）", () => {
  assertEquals(normalizeTagQuery("#海"), "#海");
  assertEquals(normalizeTagQuery("海"), "海");
});

Deno.test("normalizeTagQuery: null・空文字・空白のみは null", () => {
  assertEquals(normalizeTagQuery(null), null);
  assertEquals(normalizeTagQuery(""), null);
  assertEquals(normalizeTagQuery("   "), null);
});

// --- clampLimit ---------------------------------------------------------------

Deno.test("clampLimit: 通常値はそのまま", () => {
  assertEquals(clampLimit(30), 30);
});

Deno.test("clampLimit: 不正値はデフォルト", () => {
  assertEquals(clampLimit(NaN), DEFAULT_LIMIT);
  assertEquals(clampLimit(0), DEFAULT_LIMIT);
  assertEquals(clampLimit(-5), DEFAULT_LIMIT);
});

Deno.test("clampLimit: 上限でクランプ・小数は切り捨て", () => {
  assertEquals(clampLimit(9999), MAX_LIMIT);
  assertEquals(clampLimit(10.9), 10);
});

// --- isUuid -------------------------------------------------------------------

Deno.test("isUuid: 妥当な UUID を受理", () => {
  assertEquals(isUuid("123e4567-e89b-12d3-a456-426614174000"), true);
});

Deno.test("isUuid: 不正な文字列を拒否", () => {
  assertEquals(isUuid("tags"), false);
  assertEquals(isUuid("not-a-uuid"), false);
});

// --- captionError / altTextError ------------------------------------------------

Deno.test("captionError: 500 字以内は OK", () => {
  assertEquals(captionError("a".repeat(500)), null);
});

Deno.test("captionError: 501 字はエラー", () => {
  assertEquals(typeof captionError("a".repeat(501)), "string");
});

Deno.test("altTextError: 300 字以内は OK・301 字はエラー", () => {
  assertEquals(altTextError("a".repeat(300)), null);
  assertEquals(typeof altTextError("a".repeat(301)), "string");
});

// --- aiTagsError ----------------------------------------------------------------

Deno.test("aiTagsError: 妥当なタグ配列は OK", () => {
  assertEquals(aiTagsError(["#夕焼け", "#海"]), null);
  assertEquals(aiTagsError([]), null);
});

Deno.test("aiTagsError: 30 件ちょうどは OK・31 件はエラー", () => {
  const tags30 = Array.from({ length: 30 }, (_, i) => `#tag${i}`);
  assertEquals(aiTagsError(tags30), null);
  assertEquals(typeof aiTagsError([...tags30, "#tag30"]), "string");
});

Deno.test("aiTagsError: 文字列以外・空文字列はエラー", () => {
  assertEquals(typeof aiTagsError([123]), "string");
  assertEquals(typeof aiTagsError([""]), "string");
  assertEquals(typeof aiTagsError(["  "]), "string");
});

Deno.test("aiTagsError: 50 字ちょうどは OK・51 字はエラー", () => {
  assertEquals(aiTagsError(["a".repeat(50)]), null);
  assertEquals(typeof aiTagsError(["a".repeat(51)]), "string");
});

// --- positiveIntError -----------------------------------------------------------

Deno.test("positiveIntError: 正の整数は OK", () => {
  assertEquals(positiveIntError("width", 1024), null);
});

Deno.test("positiveIntError: 0・負数・小数・文字列はエラー", () => {
  assertEquals(typeof positiveIntError("width", 0), "string");
  assertEquals(typeof positiveIntError("width", -1), "string");
  assertEquals(typeof positiveIntError("width", 1.5), "string");
  assertEquals(typeof positiveIntError("width", "100"), "string");
});

// --- storagePathError -----------------------------------------------------------

const USER_ID = "123e4567-e89b-12d3-a456-426614174000";

Deno.test("storagePathError: 自分のフォルダ配下のパスは OK", () => {
  assertEquals(storagePathError("storage_path", `${USER_ID}/photo.jpg`, USER_ID), null);
  assertEquals(storagePathError("thumbnail_path", `${USER_ID}/thumb_photo.jpg`, USER_ID), null);
});

Deno.test("storagePathError: 他ユーザーのフォルダ配下は拒否", () => {
  const other = "999e4567-e89b-12d3-a456-426614174999";
  assertEquals(typeof storagePathError("storage_path", `${other}/photo.jpg`, USER_ID), "string");
});

Deno.test("storagePathError: プレフィックスだけ一致するフォルダ名は拒否", () => {
  // "{userId}abc/..." のような similar-prefix を "/" 区切りで弾けること
  assertEquals(
    typeof storagePathError("storage_path", `${USER_ID}abc/photo.jpg`, USER_ID),
    "string",
  );
});

Deno.test("storagePathError: パストラバーサル・不正区切りは拒否", () => {
  assertEquals(
    typeof storagePathError("storage_path", `${USER_ID}/../other/photo.jpg`, USER_ID),
    "string",
  );
  assertEquals(
    typeof storagePathError("storage_path", `${USER_ID}//photo.jpg`, USER_ID),
    "string",
  );
  assertEquals(
    typeof storagePathError("storage_path", `${USER_ID}\\photo.jpg`, USER_ID),
    "string",
  );
});

Deno.test("storagePathError: 空・非文字列・過長は拒否", () => {
  assertEquals(typeof storagePathError("storage_path", "", USER_ID), "string");
  assertEquals(typeof storagePathError("storage_path", 123, USER_ID), "string");
  assertEquals(
    typeof storagePathError("storage_path", `${USER_ID}/${"a".repeat(1024)}.jpg`, USER_ID),
    "string",
  );
});
