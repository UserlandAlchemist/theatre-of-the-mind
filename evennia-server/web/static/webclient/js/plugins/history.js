/*
 * history.js (project override, modernized)
 * - Plain Up/Down: recall input history
 * - Shift+Up/Down: normal caret movement
 * - localStorage persistence (per-path)
 * - Larger buffer (default 300)
 */
(() => {
    "use strict";

    // ---- config ----
    const HISTORY_MAX = 300;
    const STORAGE_KEY = `evennia_cmd_history:${location.pathname || "/"}`;

    // ---- state ----
    let buf = [""/* scratch */]; // last slot is scratch for in-progress typing
    let pos = 0;                 // 0 = scratch, grows as you go back

    // ---- persistence ----
    const load = () => {
        try {
            const raw = localStorage.getItem(STORAGE_KEY);
            if (!raw) return;
            const arr = JSON.parse(raw);
            if (Array.isArray(arr)) {
                const trimmed = arr.slice(-Math.max(1, HISTORY_MAX - 1));
                buf = [...trimmed, ""];
                pos = 0;
            }
        } catch { /* ignore */ }
    };
    const save = () => {
        try {
            localStorage.setItem(STORAGE_KEY, JSON.stringify(buf.slice(0, -1)));
        } catch { /* ignore quota */ }
    };
    load();

    // ---- helpers ----
    const back = () => {
        pos = Math.min(pos + 1, buf.length - 1);
        return buf[buf.length - 1 - pos];
    };
    const fwd = () => {
        pos = Math.max(pos - 1, 0);
        return buf[buf.length - 1 - pos];
    };
    const add = (input) => {
        const t = (input ?? "").trim();
        if (!t) return;
        const lastReal = buf.length >= 2 ? buf[buf.length - 2] : null;
        if (t === lastReal) return;          // no consecutive duplicates
        if (buf.length >= HISTORY_MAX) buf.shift();
        buf[buf.length - 1] = t;             // replace scratch
        buf.push("");                        // new scratch
        save();
    };

    const findInput = () => {
        // Try common Evennia selectors; fall back to last text input/textarea
        const selectors = [
            ".inputfield:focus",
 ".inputfield:last-of-type",
 "#inputfield",
 "#input",
 'input[type="text"][name="input"]',
 "textarea"
        ];
        for (const sel of selectors) {
            const el = document.querySelector(sel);
            if (el) return el;
        }
        // loose fallback
        const any = document.querySelector("input[type='text'], textarea");
        return any || null;
    };

    const setValue = (el, val) => {
        el.value = "";
        // blur→focus for reliable caret placement across browsers
        el.blur(); el.focus();
        el.value = val;
        const end = el.value.length;
        if (typeof el.setSelectionRange === "function") el.setSelectionRange(end, end);
    };

        // ---- plugin API ----
        const plugin = (() => {
            // optional: bind nothing here; we only react to onKeydown/onSend
            const init = () => {};
            const postInit = () => {};

            // Modern key handling: event.key
            const onKeydown = (event) => {
                let entry = null;
                const startPos = pos;

                if (event.key === "ArrowUp" && !event.shiftKey) {
                    entry = back();
                } else if (event.key === "ArrowDown" && !event.shiftKey) {
                    entry = fwd();
                } else {
                    return false; // let browser or other handlers proceed
                }

                const input = findInput();
                if (!input) return false;

                // if user had typed something and we're at scratch, stash it
                const current = input.value;
                if (current !== "" && startPos === 0) add(current);

                setValue(input, entry);
                event.preventDefault();
                return true;
            };

            // Accept both legacy onSend(line) and router onSend(cmd, args, kwargs)
            const onSend = (...args) => {
                let line = null;
                if (args.length === 1 && typeof args[0] === "string") {
                    line = args[0];
                } else if (args.length >= 2) {
                    const [cmd, a] = args;
                    if (cmd === "text" && Array.isArray(a) && typeof a[0] === "string") line = a[0];
                }
                if (line !== null) {
                    add(line);
                    pos = 0; // reset traversal after send
                }
                return null;
            };

            // Optional: simple toggle in Options panel
            const onOptionsUI = (parentDiv) => {
                try {
                    const wrap = document.createElement("div");
                    wrap.style.margin = "6px 0";
                    const title = document.createElement("div");
                    title.style.fontWeight = "600";
                    title.textContent = "Command History";
                    const label = document.createElement("label");
                    label.style.display = "block";
                    const chk = document.createElement("input");
                    chk.type = "checkbox";
                    chk.checked = true; // persistence enabled by default
                    chk.addEventListener("change", () => {
                        if (chk.checked) {
                            save();
                        } else {
                            try { localStorage.removeItem(STORAGE_KEY); } catch {}
                        }
                    });
                    label.append(chk, document.createTextNode(" Persist across reloads"));
                    wrap.append(title, label);
                    // parentDiv may be a jQuery object in Evennia; handle both
                    if (parentDiv && typeof parentDiv.append === "function") {
                        // jQuery-like
                        parentDiv.append(wrap);
                    } else if (parentDiv instanceof Element) {
                        parentDiv.appendChild(wrap);
                    }
                } catch { /* best effort */ }
            };

            return { init, postInit, onKeydown, onSend, onOptionsUI };
        })();

        // Register with Evennia’s plugin handler
        window.plugin_handler.add("history", plugin);
})();
