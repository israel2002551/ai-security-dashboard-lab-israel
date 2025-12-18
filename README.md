<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SECURE-AI | Real-Time Monitor</title>
    
    <script src="https://cdn.tailwindcss.com"></script>
    <script src="https://unpkg.com/lucide@latest/dist/umd/lucide.js"></script>
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"/>
    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
    
    <style>
        body { background-color: #0f172a; color: #e2e8f0; font-family: 'Segoe UI', sans-serif; overflow: hidden; }
        .glass { background: rgba(30, 41, 59, 0.6); backdrop-filter: blur(12px); border: 1px solid rgba(148, 163, 184, 0.1); }
        .scroller::-webkit-scrollbar { width: 4px; }
        .scroller::-webkit-scrollbar-thumb { background: #334155; border-radius: 2px; }
        #map { height: 100%; width: 100%; border-radius: 0.5rem; z-index: 0; }
    </style>
</head>
<body class="h-screen flex flex-col p-4 gap-4">

    <header class="h-16 glass rounded-xl flex items-center justify-between px-6 shrink-0">
        <div class="flex items-center gap-3">
            <div class="bg-blue-600 p-2 rounded-lg shadow-lg shadow-blue-500/30">
                <i data-lucide="shield-check" class="text-white w-6 h-6"></i>
            </div>
            <div>
                <h1 class="font-bold text-lg tracking-widest text-white">SECURE-AI</h1>
                <p class="text-[10px] text-blue-400 font-mono tracking-widest">CLOUD SURVEILLANCE v3.0</p>
            </div>
        </div>
        <div class="flex items-center gap-3 bg-slate-900 px-3 py-1.5 rounded-lg border border-slate-700">
            <div id="connection-dot" class="w-2 h-2 bg-red-500 rounded-full animate-pulse"></div>
            <span id="connection-text" class="text-xs font-mono text-red-400">DISCONNECTED</span>
        </div>
    </header>

    <main class="flex-1 grid grid-cols-12 gap-4 min-h-0">
        
        <div class="col-span-12 lg:col-span-7 flex flex-col gap-4">
            <div class="flex-1 bg-black rounded-xl border border-slate-700 shadow-2xl relative overflow-hidden group">
                <div class="absolute top-4 left-4 z-10 bg-red-600 text-white text-[10px] font-bold px-3 py-1 rounded shadow animate-pulse">LIVE FEED</div>
                
                <img id="video-stream" src="" class="w-full h-full object-contain" alt="Connecting to Cloud Stream...">
                
                <div id="unlock-overlay" class="absolute inset-0 bg-emerald-900/40 backdrop-blur-sm flex items-center justify-center hidden transition-all duration-300">
                    <div class="bg-black/80 border border-emerald-500 p-6 rounded-2xl text-center transform scale-110 shadow-2xl shadow-emerald-500/20">
                        <i data-lucide="lock-open" class="w-16 h-16 text-emerald-400 mx-auto mb-2"></i>
                        <h2 class="text-2xl font-bold text-white">ACCESS GRANTED</h2>
                        <p class="text-emerald-400 font-mono text-xs mt-1">IDENTITY VERIFIED</p>
                    </div>
                </div>
            </div>

            <div class="h-20 glass rounded-xl flex items-center justify-between px-6 shrink-0">
                <div class="flex items-center gap-6">
                    <div id="status-display" class="flex items-center gap-3 text-red-500 transition-colors duration-300">
                        <div class="p-2 bg-slate-800 rounded-lg border border-slate-700">
                            <i id="lock-icon" data-lucide="lock" class="w-6 h-6"></i>
                        </div>
                        <div>
                            <div class="text-[10px] text-slate-500 font-bold uppercase">Security State</div>
                            <div id="lock-text" class="text-xl font-bold">LOCKED</div>
                        </div>
                    </div>
                    <div class="h-10 w-px bg-slate-700"></div>
                    <div>
                        <div class="text-[10px] text-slate-500 font-bold uppercase">Users</div>
                        <div class="text-xl font-bold text-white" id="user-count">0</div>
                    </div>
                </div>

                <button onclick="toggleModal()" class="bg-blue-600 hover:bg-blue-500 text-white px-6 py-2.5 rounded-lg font-bold text-sm shadow-lg shadow-blue-600/20 transition flex items-center gap-2">
                    <i data-lucide="user-plus" class="w-4 h-4"></i> REGISTER ID
                </button>
            </div>
        </div>

        <div class="col-span-12 lg:col-span-5 flex flex-col gap-4">
            
            <div class="h-1/2 glass rounded-xl p-1 relative border border-slate-700 shadow-xl">
                <div id="map"></div>
                <div class="absolute top-3 right-3 bg-slate-900/90 backdrop-blur border border-slate-600 px-3 py-2 rounded text-[10px] font-mono text-white z-[400] shadow-lg">
                    <div class="text-slate-400 font-bold mb-1">GPS TELEMETRY</div>
                    <div class="flex gap-4">
                        <span>LAT: <span id="gps-lat" class="text-blue-400">--.----</span></span>
                        <span>LNG: <span id="gps-lng" class="text-blue-400">--.----</span></span>
                    </div>
                </div>
            </div>

            <div class="h-1/2 glass rounded-xl border border-slate-700 flex flex-col overflow-hidden shadow-xl">
                <div class="p-3 bg-slate-800/50 border-b border-slate-700 flex justify-between items-center">
                    <h3 class="text-xs font-bold text-slate-300 uppercase flex items-center gap-2">
                        <i data-lucide="terminal" class="w-4 h-4 text-blue-400"></i> System Logs
                    </h3>
                    <div class="flex gap-2">
                        <input id="chat-msg" type="text" placeholder="Command (e.g. status)..." class="bg-slate-900 border border-slate-600 rounded px-2 py-1 text-xs text-white w-32 focus:border-blue-500 outline-none">
                        <button onclick="sendChat()" class="p-1 bg-blue-600 hover:bg-blue-500 rounded text-white"><i data-lucide="send" class="w-3 h-3"></i></button>
                    </div>
                </div>
                <div id="log-container" class="flex-1 overflow-y-auto p-3 space-y-2 scroller font-mono text-[11px]">
                    </div>
            </div>
        </div>
    </main>

    <div id="reg-modal" class="fixed inset-0 bg-black/80 backdrop-blur-sm z-[1000] hidden flex items-center justify-center">
        <div class="bg-slate-900 border border-slate-600 rounded-xl w-80 p-6 shadow-2xl transform transition-all scale-100">
            <h2 class="text-lg font-bold text-white mb-4 flex items-center gap-2"><i data-lucide="scan-face" class="text-blue-400"></i> New Registration</h2>
            <input id="reg-name" type="text" placeholder="Enter Full Name" class="w-full bg-slate-800 border border-slate-600 rounded p-2 text-sm text-white mb-4 focus:border-blue-500 outline-none">
            <div class="flex gap-2">
                <button onclick="submitReg()" class="flex-1 bg-blue-600 hover:bg-blue-500 text-white py-2 rounded text-xs font-bold">SAVE IDENTITY</button>
                <button onclick="toggleModal()" class="flex-1 bg-slate-700 hover:bg-slate-600 text-white py-2 rounded text-xs">CANCEL</button>
            </div>
        </div>
    </div>

    <script>
        lucide.createIcons();
        
        // --- MAP INIT ---
        const map = L.map('map', { zoomControl: false }).setView([9.0765, 7.3986], 15);
        L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', { attribution: '&copy; CARTO' }).addTo(map);
        const marker = L.marker([9.0765, 7.3986]).addTo(map);

        // --- BACKEND CONNECTION ---
        const API_URL = "http://localhost:8080/api";

        // --- VIDEO STREAM REFRESHER ---
        // We add a timestamp (?t=...) to force the browser to re-download the image
        setInterval(() => {
            const img = document.getElementById('video-stream');
            img.src = `${API_URL}/stream?t=${Date.now()}`;
        }, 500); // 500ms = 2 FPS (Stable for Cloud MQTT)

        // --- DATA POLLING LOOP ---
        setInterval(async () => {
            try {
                // Fetch REAL Data from Java Backend
                const res = await fetch(`${API_URL}/dashboard-data`);
                if(!res.ok) throw new Error("Offline");
                
                const data = await res.json();
                updateUI(data);
                setOnlineStatus(true);

            } catch(e) {
                setOnlineStatus(false);
            }
        }, 1000);

        function updateUI(data) {
            // 1. Logs
            const logCont = document.getElementById('log-container');
            logCont.innerHTML = data.logs.map(l => {
                let color = "text-slate-400 border-slate-700";
                if(l.includes("ALERT") || l.includes("LOCKED")) color = "text-red-400 border-red-900 bg-red-900/10";
                if(l.includes("UNLOCKED") || l.includes("Success")) color = "text-emerald-400 border-emerald-900 bg-emerald-900/10";
                return `<div class="p-1.5 rounded border-l-2 ${color} mb-1 truncate">${l}</div>`;
            }).join('');

            // 2. Lock Status
            const statusDiv = document.getElementById('status-display');
            const lockText = document.getElementById('lock-text');
            const lockIcon = document.getElementById('lock-icon');
            const overlay = document.getElementById('unlock-overlay');

            if (!data.locked) {
                statusDiv.classList.replace('text-red-500', 'text-emerald-500');
                lockText.innerText = "UNLOCKED";
                lockIcon.setAttribute('data-lucide', 'lock-open');
                overlay.classList.remove('hidden');
            } else {
                statusDiv.classList.replace('text-emerald-500', 'text-red-500');
                lockText.innerText = "LOCKED";
                lockIcon.setAttribute('data-lucide', 'lock');
                overlay.classList.add('hidden');
            }

            // 3. Stats & Map
            document.getElementById('user-count').innerText = data.users;
            document.getElementById('gps-lat').innerText = data.lat.toFixed(5);
            document.getElementById('gps-lng').innerText = data.lng.toFixed(5);
            
            marker.setLatLng([data.lat, data.lng]);
            map.panTo([data.lat, data.lng]);

            lucide.createIcons();
        }

        function setOnlineStatus(isOnline) {
            const dot = document.getElementById('connection-dot');
            const text = document.getElementById('connection-text');
            if(isOnline) {
                dot.classList.replace('bg-red-500', 'bg-emerald-500');
                text.innerText = "SYSTEM ONLINE";
                text.classList.replace('text-red-400', 'text-emerald-400');
            } else {
                dot.classList.replace('bg-emerald-500', 'bg-red-500');
                text.innerText = "DISCONNECTED";
                text.classList.replace('text-emerald-400', 'text-red-400');
            }
        }

        // --- ACTIONS ---
        function toggleModal() { document.getElementById('reg-modal').classList.toggle('hidden'); }

        async function submitReg() {
            const name = document.getElementById('reg-name').value;
            if(!name) return;
            // Send REAL POST request to Java
            try {
                await fetch(`${API_URL}/register`, {
                    method: 'POST', headers: {'Content-Type': 'application/json'},
                    body: JSON.stringify({name: name})
                });
                toggleModal();
                alert("Identity Registered in Cloud Database");
            } catch(e) { alert("Registration Failed"); }
        }

        async function sendChat() {
            const msg = document.getElementById('chat-msg').value;
            if(!msg) return;
            // Send REAL POST request to Java
            try {
                await fetch(`${API_URL}/chat`, {
                    method: 'POST', headers: {'Content-Type': 'application/json'},
                    body: JSON.stringify({message: msg})
                });
                document.getElementById('chat-msg').value = "";
            } catch(e) { alert("Message Failed"); }
        }
    </script>
</body>
</html>
