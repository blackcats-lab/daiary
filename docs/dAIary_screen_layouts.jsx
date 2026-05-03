import { useState } from "react";
import { Camera, Image, Sparkles, FolderOpen, Settings, Heart, Search, Copy, Share2, ChevronLeft, ChevronRight, Plus, Grid3X3, RotateCcw, Sun, Sliders, Clock, Star, Trash2, X, Check, User, CreditCard, Bell, Moon, LogOut, Mail, Lock, Eye, EyeOff } from "lucide-react";

const brandGold = "#c4956a";
const brandDeep = "#2d2420";
const brandCream = "#f5efe8";
const brandAccent = "#e8a87c";

const MiniLogo = ({ size = 18, color = brandDeep }) => (
  <span style={{ fontFamily: "'Playfair Display', Georgia, serif", fontSize: size, fontWeight: 700, color, lineHeight: 1 }}>
    <span style={{ fontWeight: 400 }}>d</span>
    <span style={{ color: brandGold, fontWeight: 700, fontStyle: "italic" }}>AI</span>
    <span style={{ fontWeight: 400 }}>ary</span>
  </span>
);

const PhoneFrame = ({ children, title }) => (
  <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 12 }}>
    <div style={{
      width: 300, height: 600, borderRadius: 32, background: "#fff",
      boxShadow: "0 12px 48px rgba(0,0,0,0.12), 0 2px 12px rgba(0,0,0,0.06), inset 0 0 0 1px rgba(0,0,0,0.06)",
      overflow: "hidden", position: "relative", display: "flex", flexDirection: "column"
    }}>
      <div style={{ height: 28, background: "#fff", display: "flex", alignItems: "center", justifyContent: "center", position: "relative" }}>
        <div style={{ width: 80, height: 5, borderRadius: 3, background: "#1a1a1a", position: "absolute", top: 8 }} />
      </div>
      <div style={{ flex: 1, overflow: "hidden", display: "flex", flexDirection: "column" }}>
        {children}
      </div>
      <div style={{ height: 4, background: "#fff", display: "flex", alignItems: "center", justifyContent: "center", paddingBottom: 2 }}>
        <div style={{ width: 100, height: 4, borderRadius: 2, background: "#1a1a1a" }} />
      </div>
    </div>
    <div style={{ fontSize: "0.78rem", fontWeight: 600, color: "#1a1a1a", letterSpacing: "0.03rem" }}>{title}</div>
  </div>
);

const BottomNav = ({ active = "home" }) => {
  const items = [
    { key: "home", icon: Image, label: "ホーム" },
    { key: "camera", icon: Camera, label: "撮影" },
    { key: "ai", icon: Sparkles, label: "AI生成" },
    { key: "album", icon: FolderOpen, label: "アルバム" },
    { key: "settings", icon: Settings, label: "設定" },
  ];
  return (
    <div style={{
      display: "flex", justifyContent: "space-around", alignItems: "center",
      height: 56, borderTop: "1px solid #ebe8e3", background: "#fff", flexShrink: 0
    }}>
      {items.map(({ key, icon: Icon, label }) => (
        <div key={key} style={{
          display: "flex", flexDirection: "column", alignItems: "center", gap: 2, cursor: "pointer",
          opacity: active === key ? 1 : 0.4
        }}>
          <Icon size={18} color={active === key ? brandGold : brandDeep} strokeWidth={active === key ? 2.2 : 1.5} />
          <span style={{ fontSize: 9, color: active === key ? brandGold : brandDeep, fontWeight: active === key ? 600 : 400 }}>{label}</span>
        </div>
      ))}
    </div>
  );
};

// ── Screens ──

const HomeScreen = () => {
  const photos = [
    { color: "#d4a88c", date: "5/3" }, { color: "#8fb5a3", date: "5/2" },
    { color: "#a89cc4", date: "5/2" }, { color: "#c49696", date: "5/1" },
    { color: "#96b8c4", date: "4/30" }, { color: "#c4b896", date: "4/29" },
    { color: "#b89696", date: "4/29" }, { color: "#96c4a8", date: "4/28" },
    { color: "#c4a096", date: "4/27" },
  ];
  return (
    <div style={{ flex: 1, display: "flex", flexDirection: "column", background: brandCream }}>
      <div style={{ padding: "12px 20px 8px", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
        <MiniLogo size={20} />
        <div style={{ display: "flex", gap: 12 }}>
          <Search size={18} color={brandDeep} strokeWidth={1.5} />
          <Bell size={18} color={brandDeep} strokeWidth={1.5} />
        </div>
      </div>
      <div style={{ padding: "4px 20px 10px" }}>
        <div style={{ display: "flex", gap: 8 }}>
          {["すべて", "お気に入り", "最近"].map((t, i) => (
            <div key={t} style={{
              padding: "5px 14px", borderRadius: 16, fontSize: 11, fontWeight: 500,
              background: i === 0 ? brandGold : "transparent",
              color: i === 0 ? "#fff" : "#9a9590",
              border: i === 0 ? "none" : "1px solid #e0dbd5"
            }}>{t}</div>
          ))}
        </div>
      </div>
      <div style={{
        flex: 1, overflow: "auto", padding: "0 12px 8px",
        display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 3
      }}>
        {photos.map((p, i) => (
          <div key={i} style={{
            aspectRatio: "1", borderRadius: i === 0 ? "8px 2px 2px 2px" : 2,
            background: `linear-gradient(135deg, ${p.color}, ${p.color}88)`,
            position: "relative", overflow: "hidden"
          }}>
            {i === 0 && <Heart size={12} color="#fff" fill="#fff" style={{ position: "absolute", top: 6, right: 6, opacity: 0.9 }} />}
            {i === 2 && <Heart size={12} color="#fff" fill="#fff" style={{ position: "absolute", top: 6, right: 6, opacity: 0.9 }} />}
            <div style={{ position: "absolute", bottom: 4, left: 6, fontSize: 8, color: "rgba(255,255,255,0.8)", fontWeight: 500 }}>{p.date}</div>
          </div>
        ))}
      </div>
      <BottomNav active="home" />
    </div>
  );
};

const AIGenerateScreen = () => {
  const [selectedStyle, setSelectedStyle] = useState(0);
  const styles = ["ポエム風", "ビジネス風", "カジュアル", "ユーモア", "カスタム"];
  return (
    <div style={{ flex: 1, display: "flex", flexDirection: "column", background: brandCream }}>
      <div style={{ padding: "12px 20px 8px", display: "flex", alignItems: "center", gap: 12 }}>
        <ChevronLeft size={20} color={brandDeep} strokeWidth={1.5} />
        <span style={{ fontSize: 14, fontWeight: 600, color: brandDeep }}>AI テキスト生成</span>
      </div>
      <div style={{ flex: 1, overflow: "auto", padding: "0 16px 12px" }}>
        <div style={{
          width: "100%", height: 140, borderRadius: 12, marginBottom: 12,
          background: "linear-gradient(135deg, #d4a88c, #c49696)",
          display: "flex", alignItems: "center", justifyContent: "center"
        }}>
          <span style={{ fontSize: 10, color: "rgba(255,255,255,0.7)", fontWeight: 500 }}>選択された写真</span>
        </div>
        <div style={{ marginBottom: 12 }}>
          <div style={{ fontSize: 11, fontWeight: 600, color: brandDeep, marginBottom: 6 }}>スタイル</div>
          <div style={{ display: "flex", gap: 6, flexWrap: "wrap" }}>
            {styles.map((s, i) => (
              <div key={s} onClick={() => setSelectedStyle(i)} style={{
                padding: "5px 12px", borderRadius: 14, fontSize: 10, fontWeight: 500, cursor: "pointer",
                background: selectedStyle === i ? brandGold : "#fff",
                color: selectedStyle === i ? "#fff" : "#9a9590",
                border: `1px solid ${selectedStyle === i ? brandGold : "#e0dbd5"}`,
                transition: "all 0.2s"
              }}>{s}</div>
            ))}
          </div>
        </div>
        <div style={{ marginBottom: 12 }}>
          <div style={{ fontSize: 11, fontWeight: 600, color: brandDeep, marginBottom: 6 }}>文章の長さ</div>
          <div style={{ display: "flex", gap: 6 }}>
            {["短文", "中文", "長文"].map((l, i) => (
              <div key={l} style={{
                flex: 1, textAlign: "center", padding: "6px 0", borderRadius: 8, fontSize: 10, fontWeight: 500,
                background: i === 1 ? brandGold : "#fff",
                color: i === 1 ? "#fff" : "#9a9590",
                border: `1px solid ${i === 1 ? brandGold : "#e0dbd5"}`
              }}>{l}</div>
            ))}
          </div>
        </div>
        <div style={{
          background: "#fff", borderRadius: 12, padding: 14, marginBottom: 12,
          border: "1px solid #e8e5e0"
        }}>
          <div style={{ fontSize: 10, fontWeight: 600, color: brandGold, marginBottom: 6, display: "flex", alignItems: "center", gap: 4 }}>
            <Sparkles size={12} /> 生成された投稿文
          </div>
          <div style={{ fontSize: 11, color: brandDeep, lineHeight: 1.8, marginBottom: 10 }}>
            午後の光が窓辺に踊る。<br />何気ない日常の中に、<br />小さな幸せの欠片が<br />散りばめられている。
          </div>
          <div style={{ display: "flex", gap: 8, justifyContent: "flex-end" }}>
            <div style={{ display: "flex", alignItems: "center", gap: 3, fontSize: 9, color: "#9a9590", cursor: "pointer" }}>
              <RotateCcw size={11} /> 再生成
            </div>
            <div style={{ display: "flex", alignItems: "center", gap: 3, fontSize: 9, color: brandGold, cursor: "pointer" }}>
              <Copy size={11} /> コピー
            </div>
          </div>
        </div>
        <div style={{
          background: "#fff", borderRadius: 12, padding: 14,
          border: "1px solid #e8e5e0"
        }}>
          <div style={{ fontSize: 10, fontWeight: 600, color: brandGold, marginBottom: 8 }}># ハッシュタグ</div>
          <div style={{ display: "flex", flexWrap: "wrap", gap: 4 }}>
            {["#午後のひととき", "#日常", "#写真日記", "#光と影", "#暮らし", "#photography", "#dailylife"].map(tag => (
              <span key={tag} style={{
                fontSize: 9, color: brandGold, background: `${brandGold}12`,
                padding: "3px 8px", borderRadius: 10
              }}>{tag}</span>
            ))}
          </div>
          <div style={{ display: "flex", gap: 8, justifyContent: "flex-end", marginTop: 10 }}>
            <div style={{ display: "flex", alignItems: "center", gap: 3, fontSize: 9, color: brandGold, cursor: "pointer" }}>
              <Copy size={11} /> コピー
            </div>
          </div>
        </div>
      </div>
      <div style={{ padding: "8px 16px 8px", flexShrink: 0 }}>
        <div style={{
          display: "flex", gap: 10
        }}>
          <div style={{
            flex: 1, padding: "10px 0", borderRadius: 12, textAlign: "center",
            background: brandGold, color: "#fff", fontSize: 12, fontWeight: 600,
            display: "flex", alignItems: "center", justifyContent: "center", gap: 6
          }}>
            <Share2 size={14} /> まとめて共有
          </div>
        </div>
      </div>
      <BottomNav active="ai" />
    </div>
  );
};

const AlbumScreen = () => {
  const albums = [
    { name: "東京散歩", count: 24, colors: ["#d4a88c", "#c49696"] },
    { name: "カフェ巡り", count: 18, colors: ["#8fb5a3", "#96c4a8"] },
    { name: "仕事", count: 12, colors: ["#a89cc4", "#96b8c4"] },
    { name: "旅行 2026", count: 45, colors: ["#c4b896", "#d4a88c"] },
  ];
  return (
    <div style={{ flex: 1, display: "flex", flexDirection: "column", background: brandCream }}>
      <div style={{ padding: "12px 20px 8px", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
        <span style={{ fontSize: 16, fontWeight: 700, color: brandDeep }}>アルバム</span>
        <Plus size={20} color={brandGold} strokeWidth={2} />
      </div>
      <div style={{ padding: "0 16px 6px" }}>
        <div style={{
          display: "flex", alignItems: "center", gap: 8, background: "#fff",
          borderRadius: 10, padding: "8px 12px", border: "1px solid #e8e5e0"
        }}>
          <Search size={14} color="#9a9590" />
          <span style={{ fontSize: 11, color: "#c0bbb5" }}>アルバムを検索...</span>
        </div>
      </div>
      <div style={{ flex: 1, overflow: "auto", padding: "4px 16px" }}>
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}>
          {albums.map((a, i) => (
            <div key={i} style={{ cursor: "pointer" }}>
              <div style={{
                aspectRatio: "1.2", borderRadius: 12, overflow: "hidden", marginBottom: 6,
                background: `linear-gradient(135deg, ${a.colors[0]}, ${a.colors[1]})`,
                position: "relative"
              }}>
                <div style={{
                  position: "absolute", bottom: 0, left: 0, right: 0,
                  padding: "16px 10px 8px",
                  background: "linear-gradient(transparent, rgba(0,0,0,0.35))"
                }}>
                  <div style={{ fontSize: 9, color: "rgba(255,255,255,0.8)" }}>{a.count} 枚</div>
                </div>
              </div>
              <div style={{ fontSize: 12, fontWeight: 600, color: brandDeep, paddingLeft: 2 }}>{a.name}</div>
            </div>
          ))}
        </div>
      </div>
      <BottomNav active="album" />
    </div>
  );
};

const PhotoDetailScreen = () => (
  <div style={{ flex: 1, display: "flex", flexDirection: "column", background: "#0a0a0a" }}>
    <div style={{ padding: "10px 16px", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
      <ChevronLeft size={22} color="#fff" strokeWidth={1.5} />
      <span style={{ fontSize: 12, color: "rgba(255,255,255,0.6)" }}>2026/05/03 14:32</span>
      <Trash2 size={18} color="rgba(255,255,255,0.5)" strokeWidth={1.5} />
    </div>
    <div style={{
      flex: 1, display: "flex", alignItems: "center", justifyContent: "center",
      padding: "0 12px"
    }}>
      <div style={{
        width: "100%", aspectRatio: "3/4", borderRadius: 4,
        background: "linear-gradient(135deg, #d4a88c, #c49696, #a89cc4)"
      }} />
    </div>
    <div style={{ padding: "12px 20px 4px" }}>
      <div style={{ display: "flex", justifyContent: "center", gap: 32, marginBottom: 8 }}>
        <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 3, cursor: "pointer" }}>
          <Heart size={20} color="#fff" strokeWidth={1.5} />
          <span style={{ fontSize: 8, color: "rgba(255,255,255,0.5)" }}>お気に入り</span>
        </div>
        <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 3, cursor: "pointer" }}>
          <Sparkles size={20} color={brandGold} strokeWidth={1.5} />
          <span style={{ fontSize: 8, color: brandGold }}>AI生成</span>
        </div>
        <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 3, cursor: "pointer" }}>
          <Sliders size={20} color="#fff" strokeWidth={1.5} />
          <span style={{ fontSize: 8, color: "rgba(255,255,255,0.5)" }}>編集</span>
        </div>
        <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 3, cursor: "pointer" }}>
          <Share2 size={20} color="#fff" strokeWidth={1.5} />
          <span style={{ fontSize: 8, color: "rgba(255,255,255,0.5)" }}>共有</span>
        </div>
      </div>
    </div>
    <div style={{
      background: "#151515", borderRadius: "16px 16px 0 0", padding: "14px 20px 10px"
    }}>
      <div style={{ fontSize: 10, fontWeight: 600, color: "rgba(255,255,255,0.4)", marginBottom: 8, letterSpacing: "0.05rem" }}>EXIF 情報</div>
      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 6 }}>
        {[
          ["カメラ", "iPhone 16 Pro"],
          ["焦点距離", "24mm"],
          ["ISO", "100"],
          ["シャッター", "1/250s"],
          ["絞り", "f/1.8"],
          ["サイズ", "4032×3024"],
        ].map(([k, v]) => (
          <div key={k} style={{ display: "flex", justifyContent: "space-between" }}>
            <span style={{ fontSize: 9, color: "rgba(255,255,255,0.35)" }}>{k}</span>
            <span style={{ fontSize: 9, color: "rgba(255,255,255,0.7)" }}>{v}</span>
          </div>
        ))}
      </div>
    </div>
  </div>
);

const CameraScreen = () => (
  <div style={{ flex: 1, display: "flex", flexDirection: "column", background: "#000" }}>
    <div style={{ padding: "8px 16px", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
      <X size={22} color="#fff" strokeWidth={1.5} />
      <div style={{ display: "flex", gap: 16 }}>
        <Sun size={18} color="#fff" strokeWidth={1.5} />
        <Grid3X3 size={18} color={brandGold} strokeWidth={1.5} />
      </div>
    </div>
    <div style={{
      flex: 1, display: "flex", alignItems: "center", justifyContent: "center",
      position: "relative"
    }}>
      <div style={{
        width: "100%", height: "100%",
        background: "linear-gradient(180deg, #2a3530 0%, #1a2520 50%, #151a18 100%)",
        position: "relative"
      }}>
        {[1, 2].map(i => (
          <div key={`v${i}`} style={{
            position: "absolute", top: 0, bottom: 0,
            left: `${i * 33.33}%`, width: 1,
            background: "rgba(255,255,255,0.15)"
          }} />
        ))}
        {[1, 2].map(i => (
          <div key={`h${i}`} style={{
            position: "absolute", left: 0, right: 0,
            top: `${i * 33.33}%`, height: 1,
            background: "rgba(255,255,255,0.15)"
          }} />
        ))}
        <div style={{
          position: "absolute", top: "50%", left: "50%",
          transform: "translate(-50%, -50%)",
          width: 28, height: 28, borderRadius: "50%",
          border: "1.5px solid rgba(255,255,255,0.4)"
        }} />
      </div>
    </div>
    <div style={{ padding: "16px 20px 12px", display: "flex", alignItems: "center", justifyContent: "space-around" }}>
      <div style={{
        width: 38, height: 38, borderRadius: 8, overflow: "hidden",
        background: "linear-gradient(135deg, #d4a88c, #c49696)",
        border: "2px solid rgba(255,255,255,0.3)"
      }} />
      <div style={{
        width: 60, height: 60, borderRadius: "50%",
        border: "3px solid #fff", display: "flex", alignItems: "center", justifyContent: "center",
        cursor: "pointer"
      }}>
        <div style={{ width: 48, height: 48, borderRadius: "50%", background: "#fff" }} />
      </div>
      <div style={{
        width: 38, height: 38, borderRadius: "50%",
        border: "1.5px solid rgba(255,255,255,0.3)",
        display: "flex", alignItems: "center", justifyContent: "center"
      }}>
        <RotateCcw size={16} color="#fff" strokeWidth={1.5} />
      </div>
    </div>
  </div>
);

const SettingsScreen = () => (
  <div style={{ flex: 1, display: "flex", flexDirection: "column", background: brandCream }}>
    <div style={{ padding: "12px 20px 12px" }}>
      <span style={{ fontSize: 16, fontWeight: 700, color: brandDeep }}>設定</span>
    </div>
    <div style={{ flex: 1, overflow: "auto", padding: "0 16px" }}>
      <div style={{
        background: "#fff", borderRadius: 14, padding: "14px 16px", marginBottom: 12,
        border: "1px solid #e8e5e0", display: "flex", alignItems: "center", gap: 12
      }}>
        <div style={{
          width: 44, height: 44, borderRadius: "50%",
          background: `linear-gradient(135deg, ${brandGold}, ${brandAccent})`,
          display: "flex", alignItems: "center", justifyContent: "center"
        }}>
          <User size={20} color="#fff" />
        </div>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 13, fontWeight: 600, color: brandDeep }}>田中 太郎</div>
          <div style={{ fontSize: 10, color: "#9a9590" }}>tanaka@example.com</div>
        </div>
        <ChevronRight size={16} color="#c0bbb5" />
      </div>
      <div style={{
        background: "#fff", borderRadius: 14, padding: "4px 0", marginBottom: 12,
        border: "1px solid #e8e5e0"
      }}>
        <div style={{
          display: "flex", alignItems: "center", gap: 10, padding: "10px 16px",
          borderBottom: "1px solid #f0ede8"
        }}>
          <div style={{ width: 28, height: 28, borderRadius: 8, background: `${brandGold}15`, display: "flex", alignItems: "center", justifyContent: "center" }}>
            <CreditCard size={14} color={brandGold} />
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 12, color: brandDeep }}>プラン</div>
            <div style={{ fontSize: 9, color: brandGold, fontWeight: 600 }}>Free — アップグレード</div>
          </div>
          <ChevronRight size={14} color="#c0bbb5" />
        </div>
        <div style={{
          display: "flex", alignItems: "center", gap: 10, padding: "10px 16px",
          borderBottom: "1px solid #f0ede8"
        }}>
          <div style={{ width: 28, height: 28, borderRadius: 8, background: "#f0ede8", display: "flex", alignItems: "center", justifyContent: "center" }}>
            <Sparkles size={14} color={brandDeep} />
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 12, color: brandDeep }}>デフォルトスタイル</div>
            <div style={{ fontSize: 9, color: "#9a9590" }}>カジュアル</div>
          </div>
          <ChevronRight size={14} color="#c0bbb5" />
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: 10, padding: "10px 16px" }}>
          <div style={{ width: 28, height: 28, borderRadius: 8, background: "#f0ede8", display: "flex", alignItems: "center", justifyContent: "center" }}>
            <Moon size={14} color={brandDeep} />
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 12, color: brandDeep }}>テーマ</div>
            <div style={{ fontSize: 9, color: "#9a9590" }}>システム連動</div>
          </div>
          <ChevronRight size={14} color="#c0bbb5" />
        </div>
      </div>
      <div style={{
        background: "#fff", borderRadius: 14, padding: "4px 0", marginBottom: 12,
        border: "1px solid #e8e5e0"
      }}>
        <div style={{
          display: "flex", alignItems: "center", gap: 10, padding: "10px 16px",
          borderBottom: "1px solid #f0ede8"
        }}>
          <div style={{ width: 28, height: 28, borderRadius: 8, background: "#f0ede8", display: "flex", alignItems: "center", justifyContent: "center" }}>
            <Bell size={14} color={brandDeep} />
          </div>
          <span style={{ fontSize: 12, color: brandDeep, flex: 1 }}>通知</span>
          <div style={{ width: 36, height: 20, borderRadius: 10, background: brandGold, position: "relative", cursor: "pointer" }}>
            <div style={{ width: 16, height: 16, borderRadius: "50%", background: "#fff", position: "absolute", right: 2, top: 2, boxShadow: "0 1px 3px rgba(0,0,0,0.15)" }} />
          </div>
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: 10, padding: "10px 16px" }}>
          <div style={{ width: 28, height: 28, borderRadius: 8, background: "#f0ede8", display: "flex", alignItems: "center", justifyContent: "center" }}>
            <FolderOpen size={14} color={brandDeep} />
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 12, color: brandDeep }}>ストレージ</div>
            <div style={{ fontSize: 9, color: "#9a9590" }}>0.3 GB / 1.0 GB</div>
          </div>
          <ChevronRight size={14} color="#c0bbb5" />
        </div>
      </div>
      <div style={{
        display: "flex", alignItems: "center", justifyContent: "center", gap: 6,
        padding: "10px 0", cursor: "pointer"
      }}>
        <LogOut size={14} color="#c49696" />
        <span style={{ fontSize: 12, color: "#c49696" }}>ログアウト</span>
      </div>
    </div>
    <BottomNav active="settings" />
  </div>
);

const LoginScreen = () => {
  const [showPass, setShowPass] = useState(false);
  return (
    <div style={{
      flex: 1, display: "flex", flexDirection: "column",
      background: `linear-gradient(180deg, ${brandCream} 0%, #ebe3d8 100%)`,
      padding: "0 24px", justifyContent: "center"
    }}>
      <div style={{ textAlign: "center", marginBottom: 32 }}>
        <div style={{
          fontFamily: "'Playfair Display', Georgia, serif", fontSize: "2.4rem",
          fontWeight: 700, color: brandDeep, lineHeight: 1.1
        }}>
          <span style={{ fontWeight: 400 }}>d</span>
          <span style={{ color: brandGold, fontWeight: 700, fontStyle: "italic" }}>AI</span>
          <span style={{ fontWeight: 400 }}>ary</span>
        </div>
        <div style={{ fontSize: 10, color: "#9a9590", letterSpacing: "0.2rem", marginTop: 4, fontWeight: 300 }}>写真に、言葉を添えて。</div>
      </div>
      <div style={{ marginBottom: 12 }}>
        <div style={{
          display: "flex", alignItems: "center", gap: 10, background: "#fff",
          borderRadius: 12, padding: "10px 14px", border: "1px solid #e8e5e0"
        }}>
          <Mail size={16} color="#c0bbb5" />
          <span style={{ fontSize: 12, color: "#c0bbb5" }}>メールアドレス</span>
        </div>
      </div>
      <div style={{ marginBottom: 16 }}>
        <div style={{
          display: "flex", alignItems: "center", gap: 10, background: "#fff",
          borderRadius: 12, padding: "10px 14px", border: "1px solid #e8e5e0"
        }}>
          <Lock size={16} color="#c0bbb5" />
          <span style={{ fontSize: 12, color: "#c0bbb5", flex: 1 }}>パスワード</span>
          <div onClick={() => setShowPass(!showPass)} style={{ cursor: "pointer" }}>
            {showPass ? <Eye size={16} color="#c0bbb5" /> : <EyeOff size={16} color="#c0bbb5" />}
          </div>
        </div>
      </div>
      <div style={{
        padding: "12px 0", borderRadius: 12, textAlign: "center",
        background: brandGold, color: "#fff", fontSize: 13, fontWeight: 600,
        marginBottom: 12, cursor: "pointer"
      }}>ログイン</div>
      <div style={{ display: "flex", alignItems: "center", gap: 12, margin: "4px 0 12px" }}>
        <div style={{ flex: 1, height: 1, background: "#ddd8d2" }} />
        <span style={{ fontSize: 9, color: "#b0aaa4" }}>または</span>
        <div style={{ flex: 1, height: 1, background: "#ddd8d2" }} />
      </div>
      <div style={{
        display: "flex", gap: 10
      }}>
        <div style={{
          flex: 1, padding: "10px 0", borderRadius: 12, textAlign: "center",
          background: "#fff", border: "1px solid #e8e5e0", fontSize: 11,
          color: brandDeep, fontWeight: 500, cursor: "pointer"
        }}>Google</div>
        <div style={{
          flex: 1, padding: "10px 0", borderRadius: 12, textAlign: "center",
          background: "#1a1a1a", fontSize: 11, color: "#fff", fontWeight: 500,
          cursor: "pointer"
        }}> Apple</div>
      </div>
      <div style={{ textAlign: "center", marginTop: 16 }}>
        <span style={{ fontSize: 10, color: "#9a9590" }}>アカウントをお持ちでない方は </span>
        <span style={{ fontSize: 10, color: brandGold, fontWeight: 600, cursor: "pointer" }}>新規登録</span>
      </div>
    </div>
  );
};

// ── Main App ──
const DAIaryScreens = () => {
  const [activeScreen, setActiveScreen] = useState(0);

  const screens = [
    { component: <LoginScreen />, title: "ログイン", key: "login" },
    { component: <HomeScreen />, title: "ホーム（写真一覧）", key: "home" },
    { component: <CameraScreen />, title: "カメラ撮影", key: "camera" },
    { component: <PhotoDetailScreen />, title: "写真詳細", key: "detail" },
    { component: <AIGenerateScreen />, title: "AI テキスト生成", key: "ai" },
    { component: <AlbumScreen />, title: "アルバム一覧", key: "album" },
    { component: <SettingsScreen />, title: "設定", key: "settings" },
  ];

  return (
    <div style={{
      minHeight: "100vh", background: "#f5f3f0",
      fontFamily: "'Noto Sans JP', 'Helvetica Neue', sans-serif"
    }}>
      <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,400;0,700;1,400;1,700&family=Noto+Sans+JP:wght@300;400;500;700&display=swap" rel="stylesheet" />

      {/* Header */}
      <div style={{
        padding: "20px 32px 16px",
        background: "#fff",
        borderBottom: "1px solid #e8e5e0"
      }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 16 }}>
          <div>
            <MiniLogo size={22} />
            <span style={{ fontSize: 13, fontWeight: 400, color: "#9a9590", marginLeft: 10, letterSpacing: "0.05rem" }}>Screen Layouts</span>
          </div>
          <div style={{ fontSize: 11, color: "#9a9590" }}>v1.0 / 2026</div>
        </div>

        {/* Screen Selector */}
        <div style={{ display: "flex", gap: 6, flexWrap: "wrap" }}>
          {screens.map((s, i) => (
            <button
              key={s.key}
              onClick={() => setActiveScreen(i)}
              style={{
                padding: "6px 14px", borderRadius: 16, fontSize: 11, fontWeight: 500,
                background: activeScreen === i ? brandGold : "transparent",
                color: activeScreen === i ? "#fff" : "#9a9590",
                border: `1px solid ${activeScreen === i ? brandGold : "#e0dbd5"}`,
                cursor: "pointer", transition: "all 0.2s"
              }}
            >{s.title}</button>
          ))}
        </div>
      </div>

      {/* Phone Display */}
      <div style={{
        display: "flex", justifyContent: "center", alignItems: "flex-start",
        padding: "40px 24px 24px", gap: 40
      }}>
        <PhoneFrame title={screens[activeScreen].title}>
          {screens[activeScreen].component}
        </PhoneFrame>

        {/* Annotations */}
        <div style={{ maxWidth: 320, paddingTop: 8 }}>
          <div style={{
            fontSize: 11, color: brandGold, letterSpacing: "0.12rem",
            textTransform: "uppercase", fontWeight: 600, marginBottom: 12
          }}>Design Notes</div>
          <div style={{
            background: "#fff", borderRadius: 14, padding: "20px 24px",
            border: "1px solid #e8e5e0"
          }}>
            {activeScreen === 0 && (
              <div style={{ fontSize: 12, color: "#6a6560", lineHeight: 1.9 }}>
                <p style={{ marginBottom: 8 }}><strong style={{ color: brandDeep }}>ログイン画面</strong>はブランドの第一印象。クリーム系グラデーション背景にロゴを大きく配置。</p>
                <p style={{ marginBottom: 8 }}>入力フィールドはミニマルなアウトライン。ソーシャルログインは<strong style={{ color: brandDeep }}>Google / Apple</strong>の2択でシンプルに。</p>
                <p>新規登録への導線はゴールドで強調。</p>
              </div>
            )}
            {activeScreen === 1 && (
              <div style={{ fontSize: 12, color: "#6a6560", lineHeight: 1.9 }}>
                <p style={{ marginBottom: 8 }}><strong style={{ color: brandDeep }}>ホーム画面</strong>は3カラムのグリッドで写真を一覧表示。フォトダイアリーの「日々の記録」感を演出。</p>
                <p style={{ marginBottom: 8 }}>上部にフィルタータブ（すべて / お気に入り / 最近）を配置し、素早い絞り込みが可能。</p>
                <p>各写真には日付とお気に入りアイコンをオーバーレイ表示。</p>
              </div>
            )}
            {activeScreen === 2 && (
              <div style={{ fontSize: 12, color: "#6a6560", lineHeight: 1.9 }}>
                <p style={{ marginBottom: 8 }}><strong style={{ color: brandDeep }}>カメラ画面</strong>はフルスクリーンの黒背景。三分割グリッドラインをゴールドでアクティブ表示。</p>
                <p style={{ marginBottom: 8 }}>シャッターボタンは中央に大きく配置。左に直近の写真サムネイル、右にカメラ切替。</p>
                <p>上部にフラッシュ・グリッド切替アイコン。</p>
              </div>
            )}
            {activeScreen === 3 && (
              <div style={{ fontSize: 12, color: "#6a6560", lineHeight: 1.9 }}>
                <p style={{ marginBottom: 8 }}><strong style={{ color: brandDeep }}>写真詳細画面</strong>はダークUI。写真を最大限に引き立てる黒背景。</p>
                <p style={{ marginBottom: 8 }}>アクションバーに<strong style={{ color: brandGold }}>AI生成ボタン</strong>をゴールドで際立たせ、コア機能への導線を強調。</p>
                <p>下部にスライドアップでEXIF情報を表示。</p>
              </div>
            )}
            {activeScreen === 4 && (
              <div style={{ fontSize: 12, color: "#6a6560", lineHeight: 1.9 }}>
                <p style={{ marginBottom: 8 }}><strong style={{ color: brandDeep }}>AI生成画面</strong>はアプリのコア体験。スタイル選択はチップUIで一覧性を確保。</p>
                <p style={{ marginBottom: 8 }}>生成結果はカード内に表示し、<strong style={{ color: brandGold }}>再生成・コピー</strong>のアクションを右下に配置。</p>
                <p>ハッシュタグはゴールド背景のタグチップで表示。下部に「まとめて共有」ボタン。</p>
              </div>
            )}
            {activeScreen === 5 && (
              <div style={{ fontSize: 12, color: "#6a6560", lineHeight: 1.9 }}>
                <p style={{ marginBottom: 8 }}><strong style={{ color: brandDeep }}>アルバム画面</strong>は2カラムグリッド。カバー写真にグラデーションオーバーレイで枚数を表示。</p>
                <p style={{ marginBottom: 8 }}>検索バーを上部に配置し、アルバム名での絞り込みに対応。</p>
                <p>右上の「+」からアルバム新規作成が可能。</p>
              </div>
            )}
            {activeScreen === 6 && (
              <div style={{ fontSize: 12, color: "#6a6560", lineHeight: 1.9 }}>
                <p style={{ marginBottom: 8 }}><strong style={{ color: brandDeep }}>設定画面</strong>はiOSライクなグループ化リスト。プロフィールカードを最上部に配置。</p>
                <p style={{ marginBottom: 8 }}>プラン表示に<strong style={{ color: brandGold }}>アップグレード</strong>への導線をゴールドで強調。</p>
                <p>トグルスイッチやストレージ使用量など、状態が一目で分かるUI。</p>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default DAIaryScreens;
