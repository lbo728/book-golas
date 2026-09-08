"use client";

import { useEffect } from "react";

export function BlabThemeSync() {
  useEffect(() => {
    const media = window.matchMedia("(prefers-color-scheme: light)");
    const applyTheme = () => {
      document.documentElement.dataset.blabTheme = media.matches ? "light" : "dark";
    };

    applyTheme();
    media.addEventListener("change", applyTheme);
    return () => media.removeEventListener("change", applyTheme);
  }, []);

  return null;
}
