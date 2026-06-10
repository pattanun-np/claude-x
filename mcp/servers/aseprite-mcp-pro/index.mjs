import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import { WebSocketServer } from "ws";
import { readFileSync } from "fs";
import { fileURLToPath } from "url";
import { dirname, join } from "path";

const __dirname = dirname(fileURLToPath(import.meta.url));
const WS_PORT = parseInt(process.env.ASEPRITE_MCP_PORT || "6515", 10);

const commands = JSON.parse(
  readFileSync(join(__dirname, "commands.json"), "utf8")
);

const CATEGORIES = {
  sprite: [
    "create_sprite", "open_sprite", "save_sprite", "close_sprite",
    "get_sprite_info", "list_open_sprites", "set_active_sprite",
    "resize_sprite", "crop_sprite", "flatten_sprite",
    "get_sprite_screenshot", "set_sprite_grid",
  ],
  layer: [
    "get_layers", "add_layer", "delete_layer", "rename_layer",
    "set_layer_visibility", "set_layer_opacity", "set_layer_blend_mode",
    "reorder_layer", "duplicate_layer", "merge_layer_down",
  ],
  frame: [
    "get_frames", "add_frame", "delete_frame", "set_frame_duration",
    "set_frame_range_duration", "set_active_frame", "duplicate_frame",
    "reverse_frames",
  ],
  cel: ["get_cel", "set_cel_position", "set_cel_opacity", "clear_cel", "link_cels"],
  drawing: [
    "put_pixel", "put_pixels", "get_pixel", "get_image_data",
    "set_image_data", "draw_line", "draw_rect", "draw_ellipse",
    "flood_fill", "draw_brush_stroke", "clear_image", "replace_color",
    "outline",
  ],
  selection: [
    "select_rect", "select_ellipse", "select_all", "deselect",
    "select_by_color", "get_selection", "invert_selection",
  ],
  palette: [
    "get_palette", "set_palette_color", "set_palette", "add_palette_color",
    "resize_palette", "load_palette", "save_palette", "set_fg_color",
    "set_bg_color", "generate_palette_from_sprite", "sort_palette",
    "import_palette_from_image",
  ],
  tag: [
    "get_tags", "create_tag", "delete_tag", "rename_tag",
    "set_tag_color", "set_tag_range",
  ],
  slice: [
    "get_slices", "create_slice", "delete_slice",
    "set_slice_9patch", "set_slice_pivot",
  ],
  tilemap: [
    "create_tilemap_layer", "get_tileset", "set_tile",
    "get_tile", "get_tilemap_info",
  ],
  export: [
    "export_png", "export_sprite_sheet", "export_gif",
    "export_tileset", "export_layers", "export_tags_as_sheets",
  ],
  godot: [
    "export_for_godot", "export_atlas_texture", "export_9patch_for_godot",
    "export_tileset_for_godot", "get_animation_data",
    "generate_spriteframes_tres", "sync_to_godot_project",
    "batch_export_for_godot",
  ],
  analysis: [
    "get_color_stats", "compare_frames", "compare_screenshots",
    "find_unused_colors", "get_sprite_bounds", "validate_animation",
  ],
  editor: ["execute_script", "undo", "redo"],
  template: ["create_character_template", "create_tileset_template"],
  advanced: [
    "interpolate_frames", "draw_symmetry", "generate_color_ramp",
    "get_animation_preview", "flip_sprite", "rotate_sprite",
    "shift_cel", "apply_dither", "load_reference_image",
    "generate_animation_player_tres", "define_autotile_rules",
    "set_lospec_palette", "copy_between_sprites",
  ],
};

function buildCommandRef() {
  const lines = [];
  for (const [cat, cmds] of Object.entries(CATEGORIES)) {
    lines.push(`\n## ${cat.toUpperCase()}`);
    for (const cmd of cmds) {
      const info = commands[cmd];
      if (!info) continue;
      const paramParts = info.params.map((p) => {
        const req = p.required ? "REQUIRED" : `default=${p.default}`;
        return `${p.name}(${p.type}, ${req})`;
      });
      lines.push(`- ${cmd}${paramParts.length ? ": " + paramParts.join(", ") : ""}`);
    }
  }
  return lines.join("\n");
}

const COMMAND_REF = buildCommandRef();
const ALL_COMMANDS = Object.keys(commands);

let asepriteWs = null;
let pendingRequests = new Map();
let nextId = 1;

function startWebSocketServer() {
  const wss = new WebSocketServer({ port: WS_PORT, host: "127.0.0.1" });

  wss.on("listening", () => {
    process.stderr.write(`[aseprite-mcp] WebSocket server listening on ws://127.0.0.1:${WS_PORT}\n`);
  });

  wss.on("connection", (ws) => {
    process.stderr.write("[aseprite-mcp] Aseprite connected\n");
    asepriteWs = ws;

    ws.on("message", (data) => {
      try {
        const msg = JSON.parse(data.toString());
        if (msg.id != null && pendingRequests.has(msg.id)) {
          const { resolve } = pendingRequests.get(msg.id);
          pendingRequests.delete(msg.id);
          resolve(msg);
        }
      } catch (e) {
        process.stderr.write(`[aseprite-mcp] Parse error: ${e.message}\n`);
      }
    });

    ws.on("close", () => {
      process.stderr.write("[aseprite-mcp] Aseprite disconnected\n");
      if (asepriteWs === ws) asepriteWs = null;
      for (const [id, { reject }] of pendingRequests) {
        reject(new Error("Aseprite disconnected"));
        pendingRequests.delete(id);
      }
    });

    ws.on("error", (err) => {
      process.stderr.write(`[aseprite-mcp] WebSocket error: ${err.message}\n`);
    });
  });

  wss.on("error", (err) => {
    process.stderr.write(`[aseprite-mcp] Server error: ${err.message}\n`);
  });

  return wss;
}

function sendCommand(method, params = {}, timeoutMs = 30000) {
  return new Promise((resolve, reject) => {
    if (!asepriteWs || asepriteWs.readyState !== 1) {
      reject(new Error("Aseprite is not connected. Open Aseprite with the MCP Pro extension installed."));
      return;
    }

    const id = nextId++;
    const msg = { jsonrpc: "2.0", id, method, params };

    pendingRequests.set(id, { resolve, reject });

    const timer = setTimeout(() => {
      pendingRequests.delete(id);
      reject(new Error(`Command '${method}' timed out after ${timeoutMs}ms`));
    }, timeoutMs);

    const origResolve = resolve;
    pendingRequests.set(id, {
      resolve: (val) => { clearTimeout(timer); origResolve(val); },
      reject: (err) => { clearTimeout(timer); reject(err); },
    });

    asepriteWs.send(JSON.stringify(msg));
  });
}

function isoTileScript(x, y, size, layerName) {
  return `
local sprite = app.activeSprite
if not sprite then return { error = "No sprite open" } end
local cel = app.activeCel
if not cel then return { error = "No active cel" } end

local sx, sy, sz = ${x}, ${y}, ${size}
local lname = "${layerName}"

local srcImg = Image(sprite.width, sprite.height)
srcImg:drawSprite(sprite, cel.frameNumber)

local isoW, isoH = sz * 4, sz * 2
local isoImg = Image(isoW, isoH)

for iy = 0, sz - 1 do
  for ix = 0, sz - 1 do
    local pv = srcImg:getPixel(sx + ix, sy + iy)
    local nx = (isoW / 2 - 2) + ix * 2 - iy * 2
    local ny = ix + iy + 1
    for dx = 0, 3 do
      if nx + dx >= 0 and nx + dx < isoW and ny >= 0 and ny < isoH then
        isoImg:putPixel(nx + dx, ny, pv)
      end
    end
  end
end

isoImg:resize{ width = sz * 2, height = sz }

local finalImg = Image(sz * 2, sz)
for fy = 0, sz - 1 do
  for fx = 0, sz * 2 - 1 do
    local pv = isoImg:getPixel(fx, fy)
    finalImg:putPixel(fx, fy, pv)
  end
end

local outLayer = sprite:newLayer()
outLayer.name = lname
local outCel = sprite:newCel(outLayer, cel.frameNumber)
local canvas = Image(sprite.width, sprite.height)
canvas:drawImage(finalImg, Point(sx, sy))
outCel.image = canvas

return {
  layer = lname,
  output_width = sz * 2,
  output_height = sz,
  source = { x = sx, y = sy, size = sz }
}
`;
}

function isoFrontScript(x, y, w, h, layerName) {
  return `
local sprite = app.activeSprite
if not sprite then return { error = "No sprite open" } end
local cel = app.activeCel
if not cel then return { error = "No active cel" } end

local sx, sy, sw, sh = ${x}, ${y}, ${w}, ${h}
local lname = "${layerName}"

local srcImg = Image(sprite.width, sprite.height)
srcImg:drawSprite(sprite, cel.frameNumber)

local outH = sh + math.floor(sw / 2)
local outImg = Image(sw, outH)
local yStartOff = math.floor(sw / 2)

for iy = 0, sh - 1 do
  local yOff = yStartOff
  for ix = 0, sw - 1 do
    if ix > 0 and ix % 2 == 0 then yOff = yOff - 1 end
    if ix == 0 then yOff = yStartOff end
    local pv = srcImg:getPixel(sx + ix, sy + iy)
    local ny = iy + yOff
    if ny >= 0 and ny < outH then
      outImg:putPixel(ix, ny, pv)
    end
  end
end

local outLayer = sprite:newLayer()
outLayer.name = lname
local outCel = sprite:newCel(outLayer, cel.frameNumber)
local canvas = Image(sprite.width, sprite.height)
canvas:drawImage(outImg, Point(sx, sy))
outCel.image = canvas

return {
  layer = lname,
  output_width = sw,
  output_height = outH,
  source = { x = sx, y = sy, width = sw, height = sh }
}
`;
}

function isoSideScript(x, y, w, h, layerName) {
  return `
local sprite = app.activeSprite
if not sprite then return { error = "No sprite open" } end
local cel = app.activeCel
if not cel then return { error = "No active cel" } end

local sx, sy, sw, sh = ${x}, ${y}, ${w}, ${h}
local lname = "${layerName}"

local srcImg = Image(sprite.width, sprite.height)
srcImg:drawSprite(sprite, cel.frameNumber)

local outH = sh + math.floor(sw / 2)
local outImg = Image(sw, outH)

for iy = 0, sh - 1 do
  local yOff = 0
  for ix = 0, sw - 1 do
    if ix > 0 and ix % 2 == 0 then yOff = yOff + 1 end
    if ix == 0 then yOff = 0 end
    local pv = srcImg:getPixel(sx + ix, sy + iy)
    local ny = iy + yOff
    if ny >= 0 and ny < outH then
      outImg:putPixel(ix, ny, pv)
    end
  end
end

local outLayer = sprite:newLayer()
outLayer.name = lname
local outCel = sprite:newCel(outLayer, cel.frameNumber)
local canvas = Image(sprite.width, sprite.height)
canvas:drawImage(outImg, Point(sx, sy))
outCel.image = canvas

return {
  layer = lname,
  output_width = sw,
  output_height = outH,
  source = { x = sx, y = sy, width = sw, height = sh }
}
`;
}

const server = new Server(
  { name: "aseprite-mcp-pro", version: "1.0.0" },
  { capabilities: { tools: {} } }
);

server.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools: [
    {
      name: "aseprite",
      description: `Execute a command on the connected Aseprite editor via the MCP Pro extension.
Aseprite must be running with the MCP Pro extension installed and connected.

Available commands by category:
${COMMAND_REF}

Colors use hex format: "#FF0000", "#00FF0080" (with alpha).
Coordinates are 0-based (top-left origin).
Layer/tag operations use names (strings).
Frame numbers are 1-based.`,
      inputSchema: {
        type: "object",
        properties: {
          command: {
            type: "string",
            description: "The Aseprite command to execute",
            enum: ALL_COMMANDS,
          },
          params: {
            type: "object",
            description: "Command parameters (varies by command — see command reference above)",
            additionalProperties: true,
          },
        },
        required: ["command"],
      },
    },
    {
      name: "aseprite_status",
      description: "Check the connection status to Aseprite and get version info",
      inputSchema: { type: "object", properties: {} },
    },
    {
      name: "iso_convert",
      description: `Convert flat pixel art to isometric perspective in Aseprite.
Three modes:
- "tile": Square source → diamond floor tile (2:1 ratio). Source MUST be square with even dimensions.
- "front": Rectangle → right-facing wall (pixels shift UP diagonally). Width must be even.
- "side": Rectangle → left-facing wall (pixels shift DOWN diagonally). Width must be even.

The result is placed on a new layer. Combine tile + front + side to build isometric structures.
Typical workflow: draw flat art → convert tile for floor → convert front for right wall → convert side for left wall → assemble.`,
      inputSchema: {
        type: "object",
        properties: {
          mode: {
            type: "string",
            enum: ["tile", "front", "side"],
            description: "Conversion type: 'tile' (floor), 'front' (right wall), 'side' (left wall)",
          },
          x: { type: "number", description: "Source region X (0-based, default 0)", default: 0 },
          y: { type: "number", description: "Source region Y (0-based, default 0)", default: 0 },
          width: { type: "number", description: "Source region width (must be even). For 'tile' mode, must equal height." },
          height: { type: "number", description: "Source region height. For 'tile' mode, must equal width." },
          layer_name: { type: "string", description: "Name for output layer (default: IsometricTile/Front/Side)" },
        },
        required: ["mode", "width", "height"],
      },
    },
  ],
}));

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  if (name === "aseprite_status") {
    const connected = asepriteWs && asepriteWs.readyState === 1;
    if (!connected) {
      return {
        content: [{
          type: "text",
          text: JSON.stringify({
            connected: false,
            message: "Aseprite is not connected. Make sure Aseprite is running with the MCP Pro extension installed.",
            ws_port: WS_PORT,
          }, null, 2),
        }],
      };
    }
    try {
      const result = await sendCommand("get_version");
      return {
        content: [{
          type: "text",
          text: JSON.stringify({ connected: true, ...result.result }, null, 2),
        }],
      };
    } catch (e) {
      return {
        content: [{ type: "text", text: JSON.stringify({ connected: false, error: e.message }, null, 2) }],
      };
    }
  }

  if (name === "aseprite") {
    const { command, params = {} } = args;

    if (!command) {
      return {
        content: [{ type: "text", text: "Error: 'command' parameter is required" }],
        isError: true,
      };
    }

    if (!ALL_COMMANDS.includes(command)) {
      return {
        content: [{
          type: "text",
          text: `Error: Unknown command '${command}'. Use aseprite_status to check connection, or see the tool description for available commands.`,
        }],
        isError: true,
      };
    }

    try {
      const result = await sendCommand(command, params);

      if (result.error) {
        return {
          content: [{
            type: "text",
            text: JSON.stringify({ error: result.error }, null, 2),
          }],
          isError: true,
        };
      }

      return {
        content: [{
          type: "text",
          text: JSON.stringify(result.result ?? result, null, 2),
        }],
      };
    } catch (e) {
      return {
        content: [{ type: "text", text: `Error: ${e.message}` }],
        isError: true,
      };
    }
  }

  if (name === "iso_convert") {
    const { mode, x = 0, y = 0, width, height, layer_name } = args;

    if (!mode || !["tile", "front", "side"].includes(mode)) {
      return { content: [{ type: "text", text: "Error: mode must be 'tile', 'front', or 'side'" }], isError: true };
    }
    if (!width || !height) {
      return { content: [{ type: "text", text: "Error: width and height are required" }], isError: true };
    }
    if (width % 2 !== 0) {
      return { content: [{ type: "text", text: "Error: width must be even" }], isError: true };
    }
    if (mode === "tile" && width !== height) {
      return { content: [{ type: "text", text: "Error: tile mode requires square source (width must equal height)" }], isError: true };
    }

    const defaultNames = { tile: "IsometricTile", front: "IsometricFront", side: "IsometricSide" };
    const lname = layer_name || defaultNames[mode];

    let script;
    if (mode === "tile") {
      script = isoTileScript(x, y, width, lname);
    } else if (mode === "front") {
      script = isoFrontScript(x, y, width, height, lname);
    } else {
      script = isoSideScript(x, y, width, height, lname);
    }

    try {
      const result = await sendCommand("execute_script", { code: script });
      if (result.error) {
        return { content: [{ type: "text", text: JSON.stringify({ error: result.error }, null, 2) }], isError: true };
      }
      return { content: [{ type: "text", text: JSON.stringify(result.result ?? result, null, 2) }] };
    } catch (e) {
      return { content: [{ type: "text", text: `Error: ${e.message}` }], isError: true };
    }
  }

  return {
    content: [{ type: "text", text: `Unknown tool: ${name}` }],
    isError: true,
  };
});

async function main() {
  startWebSocketServer();

  const transport = new StdioServerTransport();
  await server.connect(transport);
  process.stderr.write("[aseprite-mcp] MCP server started on stdio\n");
}

main().catch((e) => {
  process.stderr.write(`[aseprite-mcp] Fatal: ${e.message}\n`);
  process.exit(1);
});
