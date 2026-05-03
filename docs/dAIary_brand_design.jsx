import { useState } from "react";

const LogoDesignShowcase = () => {
  const [activeTab, setActiveTab] = useState("logo");
  const [darkMode, setDarkMode] = useState(false);
  const [activeVariant, setActiveVariant] = useState(0);

  const bg = darkMode ? "#0f0f14" : "#faf9f7";
  const textColor = darkMode ? "#e8e6e1" : "#1a1a1a";
  const subtleText = darkMode ? "#8a8880" : "#9a9590";
  const cardBg = darkMode ? "#1a1a20" : "#ffffff";
  const borderColor = darkMode ? "#2a2a32" : "#e8e5e0";

  // Primary brand colors
  const brandGold = "#c4956a";
  const brandDeep = "#2d2420";
  const brandCream = "#f5efe8";
  const brandAccent = "#e8a87c";

  const Logo = ({ size = 1, showTagline = true, variant = 0 }) => {
    const scale = size;
    return (
      <div style={{ textAlign: "center" }}>
        <div
          style={{
            fontFamily: "'Playfair Display', Georgia, serif",
            fontSize: `${2.8 * scale}rem`,
            fontWeight: 700,
            letterSpacing: `${0.02 * scale}rem`,
            color: variant === 2 ? "#ffffff" : textColor,
            lineHeight: 1.1,
            userSelect: "none",
          }}
        >
          <span style={{ fontWeight: 400 }}>d</span>
          <span
            style={{
              color: brandGold,
              fontWeight: 700,
              fontStyle: "italic",
              position: "relative",
            }}
          >
            AI
          </span>
          <span style={{ fontWeight: 400 }}>ary</span>
        </div>
        {showTagline && (
          <div
            style={{
              fontFamily: "'Noto Sans JP', sans-serif",
              fontSize: `${0.65 * scale}rem`,
              color: variant === 2 ? "rgba(255,255,255,0.6)" : subtleText,
              letterSpacing: `${0.25 * scale}rem`,
              marginTop: `${0.3 * scale}rem`,
              fontWeight: 300,
            }}
          >
            写真に、言葉を添えて。
          </div>
        )}
      </div>
    );
  };

  const AppIcon = ({ size = 120, variant = 0 }) => {
    const radius = size * 0.22;

    if (variant === 0) {
      return (
        <div
          style={{
            width: size,
            height: size,
            borderRadius: radius,
            background: `linear-gradient(145deg, ${brandCream} 0%, #ebe3d8 100%)`,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            flexDirection: "column",
            boxShadow: "0 8px 32px rgba(0,0,0,0.12), 0 2px 8px rgba(0,0,0,0.06)",
            position: "relative",
            overflow: "hidden",
          }}
        >
          <div
            style={{
              position: "absolute",
              top: -size * 0.15,
              right: -size * 0.15,
              width: size * 0.6,
              height: size * 0.6,
              borderRadius: "50%",
              background: `radial-gradient(circle, ${brandAccent}22 0%, transparent 70%)`,
            }}
          />
          <div
            style={{
              fontFamily: "'Playfair Display', Georgia, serif",
              fontSize: size * 0.28,
              fontWeight: 700,
              color: brandDeep,
              lineHeight: 1,
              zIndex: 1,
            }}
          >
            <span style={{ fontWeight: 400 }}>d</span>
            <span style={{ color: brandGold, fontStyle: "italic", fontWeight: 700 }}>
              AI
            </span>
          </div>
          <div
            style={{
              width: size * 0.35,
              height: 1.5,
              background: `linear-gradient(90deg, transparent, ${brandGold}, transparent)`,
              marginTop: size * 0.02,
              zIndex: 1,
            }}
          />
          <div
            style={{
              fontFamily: "'Noto Sans JP', sans-serif",
              fontSize: size * 0.08,
              color: brandGold,
              letterSpacing: size * 0.015,
              marginTop: size * 0.02,
              fontWeight: 400,
              zIndex: 1,
            }}
          >
            ary
          </div>
        </div>
      );
    }

    if (variant === 1) {
      return (
        <div
          style={{
            width: size,
            height: size,
            borderRadius: radius,
            background: brandDeep,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            flexDirection: "column",
            boxShadow: "0 8px 32px rgba(0,0,0,0.2)",
            position: "relative",
            overflow: "hidden",
          }}
        >
          <div
            style={{
              position: "absolute",
              bottom: -size * 0.1,
              left: -size * 0.1,
              width: size * 0.5,
              height: size * 0.5,
              borderRadius: "50%",
              background: `radial-gradient(circle, ${brandGold}15 0%, transparent 70%)`,
            }}
          />
          <div
            style={{
              fontFamily: "'Playfair Display', Georgia, serif",
              fontSize: size * 0.3,
              fontWeight: 700,
              color: brandCream,
              lineHeight: 1,
              zIndex: 1,
            }}
          >
            <span style={{ fontWeight: 400 }}>d</span>
            <span style={{ color: brandGold, fontStyle: "italic", fontWeight: 700 }}>
              AI
            </span>
          </div>
          <div
            style={{
              width: size * 0.35,
              height: 1,
              background: `linear-gradient(90deg, transparent, ${brandGold}88, transparent)`,
              marginTop: size * 0.025,
              zIndex: 1,
            }}
          />
          <div
            style={{
              fontFamily: "'Noto Sans JP', sans-serif",
              fontSize: size * 0.08,
              color: `${brandGold}aa`,
              letterSpacing: size * 0.015,
              marginTop: size * 0.02,
              fontWeight: 300,
              zIndex: 1,
            }}
          >
            ary
          </div>
        </div>
      );
    }

    if (variant === 2) {
      return (
        <div
          style={{
            width: size,
            height: size,
            borderRadius: radius,
            background: `linear-gradient(145deg, ${brandGold} 0%, ${brandAccent} 50%, #d4a574 100%)`,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            flexDirection: "column",
            boxShadow: "0 8px 32px rgba(196,149,106,0.3)",
            position: "relative",
            overflow: "hidden",
          }}
        >
          <div
            style={{
              position: "absolute",
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              background: "radial-gradient(circle at 30% 30%, rgba(255,255,255,0.15) 0%, transparent 60%)",
            }}
          />
          <div
            style={{
              fontFamily: "'Playfair Display', Georgia, serif",
              fontSize: size * 0.3,
              fontWeight: 700,
              color: "#ffffff",
              lineHeight: 1,
              zIndex: 1,
              textShadow: "0 2px 4px rgba(0,0,0,0.15)",
            }}
          >
            <span style={{ fontWeight: 400 }}>d</span>
            <span style={{ fontWeight: 700, fontStyle: "italic" }}>AI</span>
          </div>
          <div
            style={{
              width: size * 0.35,
              height: 1.5,
              background: "linear-gradient(90deg, transparent, rgba(255,255,255,0.6), transparent)",
              marginTop: size * 0.025,
              zIndex: 1,
            }}
          />
          <div
            style={{
              fontSize: size * 0.08,
              color: "rgba(255,255,255,0.85)",
              letterSpacing: size * 0.015,
              marginTop: size * 0.02,
              fontWeight: 300,
              zIndex: 1,
            }}
          >
            ary
          </div>
        </div>
      );
    }
    return null;
  };

  const variants = [
    { name: "Light", desc: "クリーム × ゴールド — 温かみと上品さ" },
    { name: "Dark", desc: "ダークブラウン × ゴールド — 高級感・落ち着き" },
    { name: "Gold", desc: "ゴールドグラデーション — 華やか・キャッチー" },
  ];

  return (
    <div
      style={{
        minHeight: "100vh",
        background: bg,
        color: textColor,
        fontFamily: "'Noto Sans JP', 'Helvetica Neue', sans-serif",
        transition: "all 0.3s ease",
      }}
    >
      <link
        href="https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,400;0,700;1,400;1,700&family=Noto+Sans+JP:wght@300;400;500;700&display=swap"
        rel="stylesheet"
      />

      {/* Header */}
      <div
        style={{
          padding: "24px 32px",
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          borderBottom: `1px solid ${borderColor}`,
        }}
      >
        <div style={{ fontSize: "0.85rem", fontWeight: 500, letterSpacing: "0.1rem" }}>
          dAIary — Brand Design
        </div>
        <button
          onClick={() => setDarkMode(!darkMode)}
          style={{
            background: "none",
            border: `1px solid ${borderColor}`,
            color: textColor,
            padding: "6px 16px",
            borderRadius: 20,
            cursor: "pointer",
            fontSize: "0.75rem",
            letterSpacing: "0.05rem",
          }}
        >
          {darkMode ? "☀ Light" : "● Dark"}
        </button>
      </div>

      {/* Tabs */}
      <div
        style={{
          display: "flex",
          gap: 0,
          padding: "0 32px",
          borderBottom: `1px solid ${borderColor}`,
        }}
      >
        {["logo", "icon", "usage"].map((tab) => (
          <button
            key={tab}
            onClick={() => setActiveTab(tab)}
            style={{
              background: "none",
              border: "none",
              color: activeTab === tab ? brandGold : subtleText,
              padding: "16px 24px",
              cursor: "pointer",
              fontSize: "0.8rem",
              fontWeight: activeTab === tab ? 600 : 400,
              letterSpacing: "0.08rem",
              borderBottom: activeTab === tab ? `2px solid ${brandGold}` : "2px solid transparent",
              transition: "all 0.2s ease",
              textTransform: "uppercase",
            }}
          >
            {tab === "logo" ? "ロゴタイプ" : tab === "icon" ? "アプリアイコン" : "使用例"}
          </button>
        ))}
      </div>

      <div style={{ padding: "40px 32px", maxWidth: 900, margin: "0 auto" }}>
        {/* Logo Tab */}
        {activeTab === "logo" && (
          <div>
            {/* Main Logo Display */}
            <div
              style={{
                background: cardBg,
                borderRadius: 16,
                padding: "64px 40px",
                border: `1px solid ${borderColor}`,
                marginBottom: 32,
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
              }}
            >
              <Logo size={1.6} />
            </div>

            {/* Design Concept */}
            <div
              style={{
                background: cardBg,
                borderRadius: 16,
                padding: "32px 40px",
                border: `1px solid ${borderColor}`,
                marginBottom: 32,
              }}
            >
              <div
                style={{
                  fontSize: "0.7rem",
                  color: brandGold,
                  letterSpacing: "0.15rem",
                  marginBottom: 16,
                  textTransform: "uppercase",
                  fontWeight: 600,
                }}
              >
                Design Concept
              </div>
              <div style={{ fontSize: "0.9rem", lineHeight: 2, color: subtleText }}>
                <p style={{ margin: "0 0 12px" }}>
                  ロゴタイプは <strong style={{ color: textColor }}>Playfair Display</strong> を使用。
                  セリフ体の持つクラシカルな品格が「ダイアリー（日記）」の世界観を表現します。
                </p>
                <p style={{ margin: "0 0 12px" }}>
                  <strong style={{ color: textColor }}>「AI」</strong>部分はイタリック × ゴールドで強調。
                  通常のウェイトで組まれた「d」「ary」の中で自然にアクセントとなり、
                  テクノロジーとクリエイティビティの融合を視覚的に伝えます。
                </p>
                <p style={{ margin: 0 }}>
                  タグライン「写真に、言葉を添えて。」は
                  <strong style={{ color: textColor }}> Noto Sans JP Light</strong> で
                  控えめに配置し、メインロゴの存在感を損なわないバランスに。
                </p>
              </div>
            </div>

            {/* Color Palette */}
            <div
              style={{
                background: cardBg,
                borderRadius: 16,
                padding: "32px 40px",
                border: `1px solid ${borderColor}`,
                marginBottom: 32,
              }}
            >
              <div
                style={{
                  fontSize: "0.7rem",
                  color: brandGold,
                  letterSpacing: "0.15rem",
                  marginBottom: 20,
                  textTransform: "uppercase",
                  fontWeight: 600,
                }}
              >
                Color Palette
              </div>
              <div style={{ display: "flex", gap: 16, flexWrap: "wrap" }}>
                {[
                  { color: brandGold, name: "Brand Gold", hex: "#C4956A", role: "AI強調・アクセント" },
                  { color: brandDeep, name: "Deep Brown", hex: "#2D2420", role: "テキスト・ダークBG" },
                  { color: brandCream, name: "Cream", hex: "#F5EFE8", role: "ライトBG・カード" },
                  { color: brandAccent, name: "Warm Accent", hex: "#E8A87C", role: "グラデーション・ホバー" },
                ].map((c, i) => (
                  <div key={i} style={{ flex: "1 1 180px" }}>
                    <div
                      style={{
                        width: "100%",
                        height: 64,
                        borderRadius: 10,
                        background: c.color,
                        marginBottom: 8,
                        boxShadow: "0 2px 8px rgba(0,0,0,0.08)",
                      }}
                    />
                    <div style={{ fontSize: "0.78rem", fontWeight: 600, marginBottom: 2 }}>
                      {c.name}
                    </div>
                    <div style={{ fontSize: "0.7rem", color: subtleText }}>
                      {c.hex} — {c.role}
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Typography */}
            <div
              style={{
                background: cardBg,
                borderRadius: 16,
                padding: "32px 40px",
                border: `1px solid ${borderColor}`,
              }}
            >
              <div
                style={{
                  fontSize: "0.7rem",
                  color: brandGold,
                  letterSpacing: "0.15rem",
                  marginBottom: 20,
                  textTransform: "uppercase",
                  fontWeight: 600,
                }}
              >
                Typography
              </div>
              <div style={{ display: "flex", gap: 32, flexWrap: "wrap" }}>
                <div style={{ flex: 1, minWidth: 200 }}>
                  <div
                    style={{
                      fontFamily: "'Playfair Display', serif",
                      fontSize: "1.8rem",
                      marginBottom: 8,
                    }}
                  >
                    Playfair Display
                  </div>
                  <div style={{ fontSize: "0.75rem", color: subtleText }}>
                    ロゴ・見出し — クラシカルで気品のあるセリフ体
                  </div>
                </div>
                <div style={{ flex: 1, minWidth: 200 }}>
                  <div
                    style={{
                      fontFamily: "'Noto Sans JP', sans-serif",
                      fontSize: "1.4rem",
                      fontWeight: 300,
                      marginBottom: 8,
                    }}
                  >
                    Noto Sans JP
                  </div>
                  <div style={{ fontSize: "0.75rem", color: subtleText }}>
                    本文・UI — 読みやすく現代的なサンセリフ体
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Icon Tab */}
        {activeTab === "icon" && (
          <div>
            {/* Variant Selector */}
            <div style={{ display: "flex", gap: 8, marginBottom: 32 }}>
              {variants.map((v, i) => (
                <button
                  key={i}
                  onClick={() => setActiveVariant(i)}
                  style={{
                    background: activeVariant === i ? brandGold : "transparent",
                    color: activeVariant === i ? "#fff" : subtleText,
                    border: `1px solid ${activeVariant === i ? brandGold : borderColor}`,
                    padding: "8px 20px",
                    borderRadius: 20,
                    cursor: "pointer",
                    fontSize: "0.78rem",
                    fontWeight: 500,
                    transition: "all 0.2s ease",
                  }}
                >
                  {v.name}
                </button>
              ))}
            </div>

            {/* Main Icon Display */}
            <div
              style={{
                background: cardBg,
                borderRadius: 16,
                padding: "48px",
                border: `1px solid ${borderColor}`,
                marginBottom: 32,
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                flexDirection: "column",
                gap: 24,
              }}
            >
              <AppIcon size={160} variant={activeVariant} />
              <div style={{ textAlign: "center" }}>
                <div style={{ fontSize: "0.85rem", fontWeight: 600, marginBottom: 4 }}>
                  {variants[activeVariant].name}
                </div>
                <div style={{ fontSize: "0.75rem", color: subtleText }}>
                  {variants[activeVariant].desc}
                </div>
              </div>
            </div>

            {/* Size Variations */}
            <div
              style={{
                background: cardBg,
                borderRadius: 16,
                padding: "32px 40px",
                border: `1px solid ${borderColor}`,
                marginBottom: 32,
              }}
            >
              <div
                style={{
                  fontSize: "0.7rem",
                  color: brandGold,
                  letterSpacing: "0.15rem",
                  marginBottom: 24,
                  textTransform: "uppercase",
                  fontWeight: 600,
                }}
              >
                Size Variations
              </div>
              <div
                style={{
                  display: "flex",
                  alignItems: "flex-end",
                  justifyContent: "center",
                  gap: 32,
                  flexWrap: "wrap",
                }}
              >
                {[
                  { size: 120, label: "App Store (1024px)" },
                  { size: 80, label: "Home Screen (180px)" },
                  { size: 48, label: "Spotlight (120px)" },
                  { size: 32, label: "Settings (58px)" },
                ].map((s, i) => (
                  <div key={i} style={{ textAlign: "center" }}>
                    <AppIcon size={s.size} variant={activeVariant} />
                    <div
                      style={{
                        fontSize: "0.65rem",
                        color: subtleText,
                        marginTop: 8,
                        whiteSpace: "nowrap",
                      }}
                    >
                      {s.label}
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* All Variants Comparison */}
            <div
              style={{
                background: cardBg,
                borderRadius: 16,
                padding: "32px 40px",
                border: `1px solid ${borderColor}`,
              }}
            >
              <div
                style={{
                  fontSize: "0.7rem",
                  color: brandGold,
                  letterSpacing: "0.15rem",
                  marginBottom: 24,
                  textTransform: "uppercase",
                  fontWeight: 600,
                }}
              >
                All Variants
              </div>
              <div
                style={{
                  display: "flex",
                  justifyContent: "center",
                  gap: 32,
                  flexWrap: "wrap",
                }}
              >
                {variants.map((v, i) => (
                  <div key={i} style={{ textAlign: "center" }}>
                    <AppIcon size={100} variant={i} />
                    <div
                      style={{
                        fontSize: "0.75rem",
                        fontWeight: 500,
                        marginTop: 12,
                      }}
                    >
                      {v.name}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}

        {/* Usage Tab */}
        {activeTab === "usage" && (
          <div>
            {/* Splash Screen Mockup */}
            <div
              style={{
                background: cardBg,
                borderRadius: 16,
                padding: "32px 40px",
                border: `1px solid ${borderColor}`,
                marginBottom: 32,
              }}
            >
              <div
                style={{
                  fontSize: "0.7rem",
                  color: brandGold,
                  letterSpacing: "0.15rem",
                  marginBottom: 24,
                  textTransform: "uppercase",
                  fontWeight: 600,
                }}
              >
                Splash Screen
              </div>
              <div style={{ display: "flex", justifyContent: "center", gap: 24, flexWrap: "wrap" }}>
                {/* Light splash */}
                <div
                  style={{
                    width: 220,
                    height: 420,
                    borderRadius: 28,
                    background: `linear-gradient(180deg, ${brandCream} 0%, #ebe3d8 100%)`,
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    flexDirection: "column",
                    boxShadow: "0 8px 32px rgba(0,0,0,0.1)",
                    position: "relative",
                    overflow: "hidden",
                  }}
                >
                  <div
                    style={{
                      position: "absolute",
                      top: -40,
                      right: -40,
                      width: 160,
                      height: 160,
                      borderRadius: "50%",
                      background: `radial-gradient(circle, ${brandAccent}18 0%, transparent 70%)`,
                    }}
                  />
                  <Logo size={0.9} />
                </div>

                {/* Dark splash */}
                <div
                  style={{
                    width: 220,
                    height: 420,
                    borderRadius: 28,
                    background: `linear-gradient(180deg, #1a1714 0%, ${brandDeep} 100%)`,
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    flexDirection: "column",
                    boxShadow: "0 8px 32px rgba(0,0,0,0.2)",
                    position: "relative",
                    overflow: "hidden",
                  }}
                >
                  <div
                    style={{
                      position: "absolute",
                      bottom: -40,
                      left: -40,
                      width: 160,
                      height: 160,
                      borderRadius: "50%",
                      background: `radial-gradient(circle, ${brandGold}10 0%, transparent 70%)`,
                    }}
                  />
                  <div style={{ textAlign: "center" }}>
                    <div
                      style={{
                        fontFamily: "'Playfair Display', Georgia, serif",
                        fontSize: "2.5rem",
                        fontWeight: 700,
                        color: brandCream,
                        lineHeight: 1.1,
                      }}
                    >
                      <span style={{ fontWeight: 400 }}>d</span>
                      <span style={{ color: brandGold, fontWeight: 700, fontStyle: "italic" }}>AI</span>
                      <span style={{ fontWeight: 400 }}>ary</span>
                    </div>
                    <div
                      style={{
                        fontSize: "0.58rem",
                        color: `${brandGold}99`,
                        letterSpacing: "0.22rem",
                        marginTop: "0.3rem",
                        fontWeight: 300,
                      }}
                    >
                      写真に、言葉を添えて。
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* Store Listing Preview */}
            <div
              style={{
                background: cardBg,
                borderRadius: 16,
                padding: "32px 40px",
                border: `1px solid ${borderColor}`,
                marginBottom: 32,
              }}
            >
              <div
                style={{
                  fontSize: "0.7rem",
                  color: brandGold,
                  letterSpacing: "0.15rem",
                  marginBottom: 24,
                  textTransform: "uppercase",
                  fontWeight: 600,
                }}
              >
                App Store Listing Preview
              </div>
              <div
                style={{
                  display: "flex",
                  gap: 16,
                  alignItems: "center",
                  padding: 16,
                  borderRadius: 12,
                  background: darkMode ? "#12121a" : "#f8f6f3",
                }}
              >
                <AppIcon size={64} variant={0} />
                <div>
                  <div
                    style={{
                      fontSize: "1rem",
                      fontWeight: 600,
                      marginBottom: 2,
                    }}
                  >
                    dAIary — フォトダイアリー
                  </div>
                  <div
                    style={{
                      fontSize: "0.75rem",
                      color: subtleText,
                      marginBottom: 4,
                    }}
                  >
                    写真に、言葉を添えて。AIがおしゃれな投稿文を生成
                  </div>
                  <div style={{ display: "flex", gap: 4, alignItems: "center" }}>
                    {[1, 2, 3, 4].map((i) => (
                      <span key={i} style={{ color: brandGold, fontSize: "0.7rem" }}>
                        ★
                      </span>
                    ))}
                    <span style={{ color: subtleText, fontSize: "0.7rem" }}>★</span>
                    <span
                      style={{
                        fontSize: "0.65rem",
                        color: subtleText,
                        marginLeft: 4,
                      }}
                    >
                      4.2 (128)
                    </span>
                  </div>
                </div>
              </div>
            </div>

            {/* Logo Variations */}
            <div
              style={{
                background: cardBg,
                borderRadius: 16,
                padding: "32px 40px",
                border: `1px solid ${borderColor}`,
              }}
            >
              <div
                style={{
                  fontSize: "0.7rem",
                  color: brandGold,
                  letterSpacing: "0.15rem",
                  marginBottom: 24,
                  textTransform: "uppercase",
                  fontWeight: 600,
                }}
              >
                Logo on Different Backgrounds
              </div>
              <div style={{ display: "flex", gap: 16, flexWrap: "wrap", justifyContent: "center" }}>
                {[
                  { bg: brandCream, label: "Cream BG" },
                  { bg: brandDeep, label: "Dark BG" },
                  { bg: "#ffffff", label: "White BG" },
                ].map((item, i) => (
                  <div
                    key={i}
                    style={{
                      flex: "1 1 240px",
                      height: 160,
                      background: item.bg,
                      borderRadius: 12,
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                      border: `1px solid ${borderColor}`,
                    }}
                  >
                    <div style={{ textAlign: "center" }}>
                      <div
                        style={{
                          fontFamily: "'Playfair Display', Georgia, serif",
                          fontSize: "2rem",
                          fontWeight: 700,
                          color: item.bg === brandDeep ? brandCream : brandDeep,
                          lineHeight: 1.1,
                        }}
                      >
                        <span style={{ fontWeight: 400 }}>d</span>
                        <span style={{ color: brandGold, fontWeight: 700, fontStyle: "italic" }}>
                          AI
                        </span>
                        <span style={{ fontWeight: 400 }}>ary</span>
                      </div>
                      <div
                        style={{
                          fontSize: "0.55rem",
                          color: item.bg === brandDeep ? `${brandGold}88` : subtleText,
                          letterSpacing: "0.18rem",
                          marginTop: 4,
                        }}
                      >
                        写真に、言葉を添えて。
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default LogoDesignShowcase;
