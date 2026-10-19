"""Roblox Studio'nun yerleşik MCP sunucusuna komut satırından bağlanan küçük istemci (Claude oturumunda Roblox_Studio araçları yüklü değilse).
Önkoşul: Studio açık, yer açık, Assistant > ... > Ayarlar > MCP Sunucuları > 'Studio'yu MCP sunucusu olarak etkinleştir' AÇIK.
Kullanım (Bash'ten; PowerShell 5 JSON tırnaklarını bozar):
  py -I tools/studio_mcp.py list
  py -I tools/studio_mcp.py call start_stop_play '{"is_start":true}'
  py -I tools/studio_mcp.py call get_console_output
  py -I tools/studio_mcp.py call screen_capture '{"capture_id":"x"}' [klasör]   -> PNG kaydeder
  py -I tools/studio_mcp.py lua Client dosya.lua     (Client | Server | Edit; execute_luau)
studio_id verilmezse ilk bağlı Studio seçilir. NOT: execute_luau oyunun modül önbelleğini PAYLAŞMAZ (require yeni kopya verir);
oyun durumunu değiştirmek için istemciden RemoteEvent ateşle (ör. ReplicatedStorage.DevCommand:FireServer('RestartTutorial')).
"""
import base64, json, os, subprocess, sys, time

BAT = os.path.expandvars(r"%LOCALAPPDATA%\Roblox\mcp.bat")


def main():
    proc = subprocess.Popen(["cmd.exe", "/c", BAT], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                            stderr=subprocess.DEVNULL, text=True, encoding="utf-8")
    nid = [0]

    def send(method, params=None, notify=False):
        msg = {"jsonrpc": "2.0", "method": method}
        if params is not None:
            msg["params"] = params
        if not notify:
            nid[0] += 1
            msg["id"] = nid[0]
        proc.stdin.write(json.dumps(msg) + "\n")
        proc.stdin.flush()
        if notify:
            return None
        while True:
            line = proc.stdout.readline()
            if not line:
                raise SystemExit("server closed")
            data = json.loads(line)
            if data.get("id") == nid[0]:
                return data

    send("initialize", {"protocolVersion": "2025-06-18", "capabilities": {}, "clientInfo": {"name": "claude-script", "version": "1"}})
    send("notifications/initialized", notify=True)
    try:
        if sys.argv[1] == "list":
            res = send("tools/list", {})
            for t in res["result"]["tools"]:
                print("==", t["name"], "::", (t.get("description") or "")[:300].replace("\n", " "))
                print("   args:", json.dumps(t.get("inputSchema", {}).get("properties", {}))[:600])
        else:
            if sys.argv[1] == "lua":
                tool = "execute_luau"
                with open(sys.argv[3], encoding="utf-8") as f:
                    args = {"datamodel_type": sys.argv[2], "code": f.read()}
            else:
                tool = sys.argv[2]
                raw = sys.argv[3] if len(sys.argv) > 3 else "{}"
                if raw.startswith("@"):
                    with open(raw[1:], encoding="utf-8") as f:
                        raw = f.read()
                args = json.loads(raw)
            if tool != "list_roblox_studios" and "studio_id" not in args:
                studios = []
                for _ in range(15):  # yeni proxy Studio'yu birkaç saniyede bulur
                    studios = json.loads(send("tools/call", {"name": "list_roblox_studios", "arguments": {}})["result"]["content"][0]["text"])["studios"]
                    if studios:
                        break
                    time.sleep(1)
                if studios:
                    args["studio_id"] = studios[0]["id"]
            outdir = sys.argv[4] if sys.argv[1] == "call" and len(sys.argv) > 4 else os.environ.get("TEMP", ".")
            res = send("tools/call", {"name": tool, "arguments": args})
            if "error" in res:
                print("ERROR", json.dumps(res["error"])[:2000])
            for i, c in enumerate(res.get("result", {}).get("content", [])):
                if c.get("type") == "image":
                    path = os.path.join(outdir, f"{tool}_{int(time.time())}_{i}.png")
                    with open(path, "wb") as f:
                        f.write(base64.b64decode(c["data"]))
                    print("IMAGE", path)
                else:
                    print(c.get("text", json.dumps(c))[:20000])
    finally:
        proc.kill()


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    main()
