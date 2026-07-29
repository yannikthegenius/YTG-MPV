# YTG-MPV

> [!NOTE]
Meine Configs für [mpv](https://github.com/mpv-player/mpv) based on [ModernZ](https://github.com/Samillion/ModernZ).

<img width="1920" height="1080" alt="Screenshot_2026-07-28_15-09-55" src="https://github.com/user-attachments/assets/0c9b20b9-580f-408a-87e4-78a84a6b8ea3" />


---

## ▶️ Notable Changes

- Viele sinnvolle User Scripts.
- Viele sinnvolle, customized Keyboard Shortcuts.
- MPV OSCs (GUIs) anzeigen über ALT+SHIFT:
  - z. B. ALT+SHIFT+A für Audio
  - ALT+SHIFT+P für Playlist
  - oder ALT+SHIFT+S für Subtitles. <br>
  Man muss nicht zwischen den Options cyclen, sondern man kann die Options per Tastatureingabe filtern.


<img width="60%" height="60%" alt="Screenshot_2026-07-29_03-37-19" src="https://github.com/user-attachments/assets/131b043f-15cc-4d61-9d95-44c231c8590b" />

<img width="60%" height="60%" alt="Screenshot_2026-07-29_03-38-02" src="https://github.com/user-attachments/assets/88a1ee0b-3b6a-4f77-bb36-a1f42af7ff73" />


- F1 bis F4 für Subtitle Customization.
- H für [File History](https://github.com/Eisa01/mpv-scripts#simplehistory).
- TAB to [Skip Intro](https://github.com/rui-ddc/skip-intro).
- Öffne die Directory der derzeit geladenen File über SHIFT+B. Default OS File Manager wird dann geöffnet.
- Auto Resume Video by default: MPV wird sich immer die Position der letzten Wiedergabe merken und man kann MPV immer einfach schließen (auto save).

<img width="60%" height="60%" alt="Screenshot_2026-07-28_15-35-28" src="https://github.com/user-attachments/assets/92778d13-246a-4cec-9c1d-bf136689178a" />


- CTRL+Z to Resume: Wenn man ausversehen an eine andere Stelle gesprungen ist, kann man das revidieren und mit CTRL+Z einfach wieder zurückspringen.
- Playlist by default: Wenn man eine File in einem Ordner öffnet, in dem auch andere Files sind, wird automatisch eine Playlist erstellt. So kann man einfach per SHIFT+LEFT und SHIFT+RIGHT zwischen den verschiedenen Files wechseln, ohne im File Manager gucken zu müssen.
- Sehr viele andere useful Scripts wie [Sharpening Shader](https://gist.github.com/igv/8a77e4eb8276753b54bb94c1c50c317e), [File Browser](https://github.com/CogentRedTester/mpv-file-browser/tree/master), [Audio Visualizer](https://github.com/DonCanjas/mpv-visualizer/tree/master) oder [Pause Indicator](https://github.com/Keith94/ModernZ/blob/pause-indicator-animated/extras/pause-indicator-lite/pause_indicator_lite.lua). Danke an die Arbeit von all den Script-Developern; habe nicht alle selber gemacht.

---

## 🚀 Installation
1. ``git clone https://github.com/yannikthegenius/YTG-MPV.git``
2. Files von `YTG-MPV Directory` in `MPV Config Directory` kopieren.
3. Default MPV Config Directory Location: ``/home/$USER/.config/mpv`` <br>
   or <br>
   Default MPV Flatpak Config Directory Location: `/home/$USER/.var/app/io.mpv.Mpv/config/mpv`
