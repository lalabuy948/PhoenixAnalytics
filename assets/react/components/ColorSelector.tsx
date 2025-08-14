import * as React from "react";
import { Palette, Check } from "lucide-react";
import { useHotkeys } from "react-hotkeys-hook";

import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { cn } from "@/lib/utils";

interface ColorTheme {
  name: string;
  label: string;
  cssClass: string;
  colors: {
    primary: string;
    secondary: string;
    accent: string;
  };
}

const colorThemes: ColorTheme[] = [
  {
    name: "zinc",
    label: "Zinc",
    cssClass: "theme-zinc",
    colors: {
      primary: "hsl(240 6% 10%)",
      secondary: "hsl(240 5% 96%)",
      accent: "hsl(240 5% 96%)",
    }
  },
  {
    name: "slate",
    label: "Slate",
    cssClass: "theme-slate",
    colors: {
      primary: "hsl(215.4 16.3% 46.9%)",
      secondary: "hsl(210 40% 96%)",
      accent: "hsl(210 40% 96%)",
    }
  },
  {
    name: "stone",
    label: "Stone",
    cssClass: "theme-stone",
    colors: {
      primary: "hsl(24 10% 10%)",
      secondary: "hsl(60 9% 98%)",
      accent: "hsl(60 9% 98%)",
    }
  },
  {
    name: "gray",
    label: "Gray",
    cssClass: "theme-gray",
    colors: {
      primary: "hsl(220.9 39.3% 11%)",
      secondary: "hsl(220 14.3% 95.9%)",
      accent: "hsl(220 14.3% 95.9%)",
    }
  },
  {
    name: "neutral",
    label: "Neutral",
    cssClass: "theme-neutral",
    colors: {
      primary: "hsl(0 0% 9%)",
      secondary: "hsl(0 0% 96.1%)",
      accent: "hsl(0 0% 96.1%)",
    }
  },
  {
    name: "red",
    label: "Red",
    cssClass: "theme-red",
    colors: {
      primary: "hsl(0 72.2% 50.6%)",
      secondary: "hsl(0 0% 96.1%)",
      accent: "hsl(0 0% 96.1%)",
    }
  },
  {
    name: "rose",
    label: "Rose",
    cssClass: "theme-rose",
    colors: {
      primary: "hsl(346.8 77.2% 49.8%)",
      secondary: "hsl(0 0% 96.1%)",
      accent: "hsl(0 0% 96.1%)",
    }
  },
  {
    name: "orange",
    label: "Orange",
    cssClass: "theme-orange",
    colors: {
      primary: "hsl(24.6 95% 53.1%)",
      secondary: "hsl(0 0% 96.1%)",
      accent: "hsl(0 0% 96.1%)",
    }
  },
  {
    name: "green",
    label: "Green",
    cssClass: "theme-green",
    colors: {
      primary: "hsl(142.1 76.2% 36.3%)",
      secondary: "hsl(0 0% 96.1%)",
      accent: "hsl(0 0% 96.1%)",
    }
  },
  {
    name: "blue",
    label: "Blue",
    cssClass: "theme-blue",
    colors: {
      primary: "hsl(221.2 83.2% 53.3%)",
      secondary: "hsl(0 0% 96.1%)",
      accent: "hsl(0 0% 96.1%)",
    }
  },
  {
    name: "yellow",
    label: "Yellow",
    cssClass: "theme-yellow",
    colors: {
      primary: "hsl(47.9 95.8% 53.1%)",
      secondary: "hsl(0 0% 96.1%)",
      accent: "hsl(0 0% 96.1%)",
    }
  },
  {
    name: "violet",
    label: "Violet",
    cssClass: "theme-violet",
    colors: {
      primary: "hsl(262.1 83.3% 57.8%)",
      secondary: "hsl(0 0% 96.1%)",
      accent: "hsl(0 0% 96.1%)",
    }
  },
];

export function ColorSelector() {
  const [selectedTheme, setSelectedTheme] = React.useState<string>("blue");

  React.useEffect(() => {
    const savedTheme = localStorage.getItem("color-theme") || "blue";
    setSelectedTheme(savedTheme);
    applyTheme(savedTheme);
  }, []);

  const applyTheme = (themeName: string) => {
    const theme = colorThemes.find(t => t.name === themeName);
    if (!theme) return;

    // Remove all existing theme classes
    colorThemes.forEach(t => {
      document.documentElement.classList.remove(t.cssClass);
    });

    // Add the selected theme class
    document.documentElement.classList.add(theme.cssClass);

    // Store in localStorage
    localStorage.setItem("color-theme", themeName);
  };

  const handleThemeChange = (themeName: string) => {
    setSelectedTheme(themeName);
    applyTheme(themeName);
  };

  // Keyboard shortcuts for color themes (1-9, 0, -, =)
  useHotkeys("1", () => handleThemeChange("zinc"), []);
  useHotkeys("2", () => handleThemeChange("slate"), []);
  useHotkeys("3", () => handleThemeChange("stone"), []);
  useHotkeys("4", () => handleThemeChange("gray"), []);
  useHotkeys("5", () => handleThemeChange("neutral"), []);
  useHotkeys("6", () => handleThemeChange("red"), []);
  useHotkeys("7", () => handleThemeChange("rose"), []);
  useHotkeys("8", () => handleThemeChange("orange"), []);
  useHotkeys("9", () => handleThemeChange("green"), []);
  useHotkeys("0", () => handleThemeChange("blue"), []);
  useHotkeys("minus", () => handleThemeChange("yellow"), []);
  useHotkeys("equal", () => handleThemeChange("violet"), []);

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button variant="outline" size="icon">
          <Palette className="h-[1.2rem] w-[1.2rem]" />
          <span className="sr-only">Select color theme</span>
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end" className="w-48">
        <div className="p-2">
          <div className="mb-2 text-sm font-medium">Color Theme</div>
          <div className="grid grid-cols-3 gap-2">
            {colorThemes.map((theme, index) => {
              const getShortcutKey = (index: number) => {
                if (index < 9) return String(index + 1);
                if (index === 9) return "0";
                if (index === 10) return "-";
                if (index === 11) return "=";
                return "";
              };

              return (
                <button
                  key={theme.name}
                  className={cn(
                    "relative h-8 w-full rounded-md border-2 border-muted bg-popover",
                    selectedTheme === theme.name && "border-ring"
                  )}
                  onClick={() => handleThemeChange(theme.name)}
                  title={`${theme.label} (${getShortcutKey(index)})`}
                >
                  <div className="flex h-full w-full items-center gap-1 rounded-sm p-1">
                    <div
                      className="h-4 w-4 rounded-full border border-foreground/20"
                      style={{ backgroundColor: theme.colors.primary }}
                    />
                    <div
                      className="h-4 w-4 rounded-full border border-foreground/20"
                      style={{ backgroundColor: theme.colors.secondary }}
                    />
                    <div
                      className="h-4 w-4 rounded-full border border-foreground/20"
                      style={{ backgroundColor: theme.colors.accent }}
                    />
                  </div>
                  {selectedTheme === theme.name && (
                    <Check className="absolute right-1 top-1 h-3 w-3" />
                  )}
                  {/* Keyboard shortcut indicator */}
                  <span className="absolute bottom-0 left-1 text-[10px] text-muted-foreground opacity-60">
                    {getShortcutKey(index)}
                  </span>
                  <span className="sr-only">{theme.label}</span>
                </button>
              );
            })}
          </div>
        </div>
      </DropdownMenuContent>
    </DropdownMenu>
  );
}