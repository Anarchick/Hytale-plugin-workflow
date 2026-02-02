# Hytale Plugin Development Setup Guide
This guide will help you set up a development environment for creating Hytale plugins, including support for hot-reload without restarting the server.

My script `hytale-downloader.bat` will update your server and assets using the official Hytale Downloader CLI.

To set up a database using Docker, I've included a `compose.yaml` file.

By following this guide, you'll be able to create, test, and manage Hytale plugins efficiently.

## Create an Hytale Plugin
**Disclaimer:** HYT-CLI is designed for developing a single plugin per project; it does not support multi-plugin projects.

Create a new folder to hold all your projects.
Example: C:\Users\username\Documents\HytaleProjects\

1. Install Node.js from https://nodejs.org/en/download/current to get npm (Node.js package manager).
2. In your terminal, go to your projects folder and run:
```bash
# https://github.com/LunnosMp4/hyt This is used to initialize the plugin project structure
# with an included server and hot-reload compilation support

# Local installation of Hytale CLI
npm install @lunnos/hyt
# Global installation of Hytale CLI
npm install -g @lunnos/hyt
```
3. Install the Java version recommended for Hytale (JDK 25 at the time of writing) from https://adoptium.net/fr/temurin/releases
4. Run `java -version` in a new terminal to verify the installation. (You may need to update your PATH.)
5. In your projects folder, run the setup and create commands as described in https://github.com/LunnosMp4/hyt. If you have installed Hytale CLI locally, prefix the command with `npx`.
6. I recommend generating reference sources to help your IDE with code completion.
7. Open the generated project folder in your favorite IDE.
8. You may have issues with `.gradle.kts` files if your IDE does not support Kotlin; you can remove the `.kts` extension to use Groovy instead.
9. Use my modified `.gitignore` file.
10. Make your first commit to your Git repository.

**Notes:**
 - HYT CLI include Junit for testing. You can create tests in the `app/src/test/java` folder.
 - Use `app/build.gradle.kts` to add dependencies to your plugin project.

## Run the Hytale Server with hot-reload
HYT-CLI will build your plugin and place the output in the `mods` folder.
MDevTools will watch for changes in your plugin's build and reload the plugin automatically without restarting the server.

1. Download and place MDevTools in the `mods` folder: https://www.curseforge.com/hytale/mods/mdevtools-development-tools
2. Open a terminal and navigate to your plugin project folder.
3. To start the server, run `hyt dev` (or `npx hyt dev` if you have installed Hytale CLI locally).
4. you can also add `--watch` if you want to build automatically at any file changed.

## Update server and assets
1. Download the Hytale Downloader CLI from https://support.hytale.com/hc/en-us/articles/45326769420827-Hytale-Server-Manual
2. Create a folder anywhere on your computer and extract the downloaded `.exe` into it.
3. Add its path to your environment variables. Example: `C:\Tools\hytale-downloader\hytale-downloader.exe`
4. Run `hytale-downloader.bat` to download the latest Hytale server and assets.

## Database setup
1. Install Docker Desktop from https://www.docker.com/products/docker-desktop/
2. Edit the `compose.yaml` if you want to change database settings.
3. Open a terminal in the folder containing `compose.yaml` and run: `docker compose up -d`
4. On your browser, go to localhost:8080 for PhpMyAdmin or localhost:8081 for Mongo Express
5. Run `docker compose down` to shut down any services