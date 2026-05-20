/**
 * The Engine configuration object.
 *
 * An object used to configure the Engine instance based on godot export options,
 * and to override those in custom HTML templates if needed.
 */
export declare interface EngineConfig {
  /**
   * Whether the unload the engine automatically after the instance is initialized.
   * @default true
   */
  unloadAfterInit?: boolean;

  /**
   * The HTML DOM Canvas object to use.
   *
   * By default, the first canvas element in the document will be used if none is specified.
   * @default null
   */
  canvas?: HTMLCanvasElement | null;

  /**
   * The name of the WASM file without the extension. (Set by Godot Editor export process).
   * @default ""
   */
  executable?: string;

  /**
   * An alternative name for the game pck to load. The executable name is used otherwise.
   * @default null
   */
  mainPack?: string | null;

  /**
   * Specify a language code to select the proper localization for the game.
   *
   * The browser locale will be used if none is specified.
   * @default null
   */
  locale?: string | null;

  /**
   * The canvas resize policy determines how the canvas should be resized by Godot.
   *
   * - `0` means Godot won't do any resizing. This is useful if you want to control the canvas size from javascript code in your template.
   * - `1` means Godot will resize the canvas on start, and when changing window size via engine functions.
   * - `2` means Godot will adapt the canvas size to match the whole browser window.
   *
   * @default 2
   */
  canvasResizePolicy?: number;

  /**
   * The arguments to be passed as command line arguments on startup.
   *
   * Note: `startGame()` will always add the `--main-pack` argument.
   * @default []
   */
  args?: string[];

  /**
   * NOTE: This is not in the docs, but is present in the generated code.
   */
  emscriptenPoolSize?: number;

  /**
   * NOTE: This is not in the docs, but is present in the generated code.
   */
  ensureCrossOriginIsolationHeaders?: boolean;

  /**
   * NOTE: This is not in the docs, but is present in the generated code.
   */
  experimentalVK?: boolean;

  /**
   * NOTE: This is not in the docs, but is present in the generated code.
   */
  fileSizes?: Record<string, number>;

  /**
   * NOTE: This is not in the docs, but is present in the generated code.
   */
  focusCanvas?: boolean;

  /**
   * NOTE: This is not in the docs, but is present in the generated code.
   */
  gdextensionLibs?: string[];

  /**
   * NOTE: This is not in the docs, but is present in the generated code.
   */
  godotPoolSize?: number;

  /**
   * NOTE: This is not in the docs, but is present in the generated code.
   */
  serviceWorker?: boolean;

  /**
   * A callback function for handling Godot's `OS.execute` calls.
   *
   * This is for example used in the Web Editor template to switch between Project Manager and editor, and for running the game.
   * @param path The path that Godot's wants executed.
   * @param args The arguments of the "command" to execute.
   */
  onExecute?: (path: string, args: string[]) => void;

  /**
   * A callback function for being notified when the Godot instance quits.
   *
   * Note: This function will not be called if the engine crashes or become unresponsive.
   * @param statusCode The status code returned by Godot on exit.
   */
  onExit?: (statusCode: number) => void;

  /**
   * A callback function for displaying download progress.
   *
   * The function is called once per frame while downloading files, so the usage of `requestAnimationFrame()` is not necessary.
   *
   * If the callback function receives a total amount of bytes as 0, this means that it is impossible to calculate.
   * Possible reasons include:
   * - Files are delivered with server-side chunked compression
   * - Files are delivered with server-side compression on Chromium
   * - Not all file downloads have started yet (usually on servers without multi-threading)
   *
   * @param current The current amount of downloaded bytes so far.
   * @param total The total amount of bytes to be downloaded.
   */
  onProgress?: (current: number, total: number) => void;

  /**
   * A callback function for handling the standard output stream. This method should usually only be used in debug pages.
   *
   * By default, `console.log()` is used.
   * @param varArgs A variadic number of arguments to be printed.
   */
  onPrint?: (...varArgs: unknown[]) => void;

  /**
   * A callback function for handling the standard error stream. This method should usually only be used in debug pages.
   *
   * By default, `console.error()` is used.
   * @param varArgs A variadic number of arguments to be printed as errors.
   */
  onPrintError?: (...varArgs: unknown[]) => void;

  /**
   * Paths that are supposed to be persisted between sessions
   */
  persistentPaths?: string[];
}

/**
 * The Engine class provides methods for loading and starting exported projects on the Web.
 *
 * For default export settings, this is already part of the exported HTML page.
 * This API is built in an asynchronous manner and requires basic understanding of Promises.
 */
export declare class Engine {
  /**
   * Create a new Engine instance with the given configuration.
   * @param initConfig The initial config for this instance.
   */
  constructor(initConfig: EngineConfig);

  /**
   * Load the engine from the specified base path.
   * @param basePath Base path of the engine to load.
   * @returns A Promise that resolves once the engine is loaded.
   */
  static load(basePath: string): Promise<void>;

  /**
   * Unload the engine to free memory.
   *
   * This method will be called automatically depending on the configuration. See `unloadAfterInit`.
   */
  static unload(): void;

  /**
   * Check whether WebGL is available. Optionally, specify a particular version of WebGL to check for.
   * @param majorVersion The major WebGL version to check for.
   * @returns If the given major version of WebGL is available.
   */
  static isWebGLAvailable(majorVersion?: number): boolean;

  /**
   * NOTE: This is not in the docs, but is present in the generated code.
   */
  static getMissingFeatures(features: Record<string, boolean>): string[];

  /**
   * Initialize the engine instance. Optionally, pass the base path to the engine to load it,
   * if it hasn't been loaded yet. See `Engine.load`.
   *
   * @param basePath Base path of the engine to load.
   * @returns A Promise that resolves once the engine is loaded and initialized.
   */
  init(basePath?: string): Promise<void>;

  /**
   * Load a file so it is available in the instance's file system once it runs. Must be called **before** starting the instance.
   *
   * If not provided, the `path` is derived from the URL of the loaded file.
   * @param file The file to preload.
   *    If a string the file will be loaded from that path.
   *    If an ArrayBuffer or a view on one, the buffer will used as the content of the file.
   * @param path Path by which the file will be accessible. Required, if `file` is not a string.
   * @returns A Promise that resolves once the file is loaded.
   */
  preloadFile(file: string | ArrayBuffer, path?: string): Promise<void>;

  /**
   * Start the engine instance using the given override configuration (if any).
   * `startGame()` can be used in typical cases instead.
   *
   * This will initialize the instance if it is not initialized. For manual initialization, see `init()`.
   * The engine must be loaded beforehand.
   *
   * Fails if a canvas cannot be found on the page, or not specified in the configuration.
   *
   * @param override An optional configuration override.
   * @returns Promise that resolves once the engine started.
   */
  start(override?: EngineConfig): Promise<void>;

  /**
   * Start the game instance using the given configuration override (if any).
   *
   * This will initialize the instance if it is not initialized. For manual initialization, see `init()`.
   * This will load the engine if it is not loaded, and preload the main pck.
   *
   * This method expects the initial config (or the override) to have both the `executable` and `mainPack`
   * properties set (normally done by the editor during export).
   *
   * @param override An optional configuration override.
   * @returns Promise that resolves once the game started.
   */
  startGame(override?: EngineConfig): Promise<void>;

  /**
   * Create a file at the specified `path` with the passed as `buffer` in the instance's file system.
   * @param path The location where the file will be created.
   * @param buffer The content of the file.
   */
  copyToFS(path: string, buffer: ArrayBuffer): void;

  /**
   * Request that the current instance quit.
   *
   * This is akin the user pressing the close button in the window manager, and will
   * have no effect if the engine has crashed, or is stuck in a loop.
   */
  requestQuit(): void;

  /**
   * NOTE: This is not in the docs, but is present in the generated code.
   */
  installServiceWorker(): void;
}
