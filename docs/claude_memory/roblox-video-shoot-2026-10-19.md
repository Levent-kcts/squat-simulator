---
name: roblox-video-shoot-2026-10-19
description: Promo shoot done 2026-10-20 (4 thumbnails + 15 s video in assets/marketing/2026-10-20); StudioReadOnly back to false; how shoots are done
metadata:
  node_type: memory
  type: project
  originSessionId: 344cd710-ea0c-4a77-8827-843b2486537d
  modified: 2026-10-19T23:43:29.773Z
---

The promo shoot that started on 2026-10-19 finished on 2026-10-20.

- Output: assets/marketing/2026-10-20 holds 4 in-game thumbnails (1920x1080), a 15 s 1080p video and the scripts that made them.
- The 9:16 Shorts version was NOT made. Nothing has been uploaded to Roblox yet.
- Config.Save.StudioReadOnly is back to false (commit 851b1cb). Set it to true again before any shoot that uses DEV resets.

How shoots work now:
- Camera: cam.lua is run through the Studio MCP (`py -I tools/studio_mcp.py lua Client`).
- Stills: the MCP `screen_capture` gives 1913x744 with no UI.
- Video: ffmpeg gdigrab of the game area at offset 4,187, size 1912x742.
  - Prepare first: collapse the ribbon and close the right-side panels.
  - Hide the game UI with H.
  - Move the mouse out of the frame, otherwise the in-game cursor shows.
- Egg hatch: press E with the MCP `user_keyboard_input` (datamodel_type Client).

Related: [[roblox-dev-tooling-2026-10-20]].

Upload (2026-10-20): the 4 thumbnails replaced the 3 real screenshots on the Experience Detail page; the video is uploaded (asset 124112593803350, in review). The Home Page pool (separate list, max 5 active) was also switched: 5 active = 2 AI + smash, lvl1-vs-200, pets; the giant image is in the pool but inactive. A new thumbnail test started 2026-10-20, so leave it alone for 7 days.

How the Creator Hub upload works:
- Clicking a page's own hidden file input does nothing.
- The working path:
  1. Put the file into a helper `<input type=file>` with Claude-in-Chrome `file_upload`.
  2. Call the "Upload thumbnail" button's React `onClick` (it picks the uploader).
  3. Call the real input's React `onChange`.
- To reorder, PATCH `apis.roblox.com/assets/user-auth/v1/assets/<placeId>?updateMask=previews` with a multipart `request` field. On a 403, retry with the `x-csrf-token` it returns.
- Chrome screenshots time out on this page, so read it with JavaScript instead.
