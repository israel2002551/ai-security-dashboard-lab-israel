package com.secureai;

import org.eclipse.paho.client.mqttv3.*;
import org.eclipse.paho.client.mqttv3.persist.MemoryPersistence;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.*;
import org.springframework.http.ResponseEntity;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArrayList;

@SpringBootApplication
@RestController
@RequestMapping("/api")
@CrossOrigin(origins = "*") // Allows HTML file to connect without errors
public class SecureSystem implements CommandLineRunner {

    public static void main(String[] args) {
        SpringApplication.run(SecureSystem.class, args);
        System.out.println("==================================================");
        System.out.println("   [JAVA] SECURE-AI CLOUD BRIDGE ONLINE");
        System.out.println("   DASHBOARD API: http://localhost:8080");
        System.out.println("==================================================");
    }

    // --- CLOUD CONFIGURATION (Must match ESP32 & Python) ---
    private static final String BROKER_URL = "tcp://broker.emqx.io:1883";
    private static final String CLIENT_ID = "Java_Dashboard_Bridge_" + System.currentTimeMillis();
    private static final String TOPIC_PREFIX = "secureai_v3_user123"; 
    
    // Topics
    private static final String TOPIC_VIDEO_FRAME = TOPIC_PREFIX + "/camera/frame";
    private static final String TOPIC_GPS_DATA    = TOPIC_PREFIX + "/gps/data";
    private static final String TOPIC_THREAT_LEVEL= TOPIC_PREFIX + "/threat/level";
    private static final String TOPIC_CHAT_IN     = TOPIC_PREFIX + "/chat/in";
    private static final String TOPIC_CHAT_OUT    = TOPIC_PREFIX + "/chat/out";
    private static final String TOPIC_DOOR_CMD    = TOPIC_PREFIX + "/door/command";

    private MqttClient mqttClient;

    // --- SYSTEM STATE ---
    // Buffer for the latest video frame received from Cloud
    private static volatile byte[] currentFrame = new byte[0]; 
    private static final List<String> logs = new CopyOnWriteArrayList<>();
    private static double lat = 9.0765;
    private static double lng = 7.3986;
    private static boolean isLocked = true;
    private static int registeredUsers = 0;

    // --- 1. MQTT CONNECTION ---
    @Override
    public void run(String... args) {
        try {
            mqttClient = new MqttClient(BROKER_URL, CLIENT_ID, new MemoryPersistence());
            MqttConnectOptions opts = new MqttConnectOptions();
            opts.setCleanSession(true);
            opts.setAutomaticReconnect(true);
            
            System.out.println("[MQTT] Connecting Java to Cloud Broker...");
            mqttClient.connect(opts);
            
            // Subscribe to all relevant topics
            mqttClient.subscribe(new String[]{
                TOPIC_VIDEO_FRAME, TOPIC_GPS_DATA, TOPIC_THREAT_LEVEL, TOPIC_CHAT_OUT, TOPIC_DOOR_CMD
            }, new int[]{0, 0, 0, 0, 0});
            
            mqttClient.setCallback(new MqttCallback() {
                public void connectionLost(Throwable cause) { System.out.println("[MQTT] Connection Lost."); }
                public void deliveryComplete(IMqttDeliveryToken token) {}

                public void messageArrived(String topic, MqttMessage message) {
                    processIncomingMessage(topic, message);
                }
            });
            
            System.out.println("[MQTT] Connected! Bridge Active.");
            addLog("System bridged to Cloud Broker.");

        } catch (MqttException e) {
            System.err.println("[FATAL] MQTT Connection failed: " + e.getMessage());
        }
    }

    private void processIncomingMessage(String topic, MqttMessage msg) {
        // 1. Video Frame (Binary)
        if (topic.equals(TOPIC_VIDEO_FRAME)) {
            currentFrame = msg.getPayload();
        } 
        // 2. GPS Data (JSON)
        else if (topic.equals(TOPIC_GPS_DATA)) {
            String payload = new String(msg.getPayload()); 
            try {
                if(payload.contains("lat")) {
                    String clean = payload.replaceAll("[{}\" ]", "");
                    String[] parts = clean.split(",");
                    for(String p : parts) {
                        String[] kv = p.split(":");
                        if(kv[0].equals("lat")) lat = Double.parseDouble(kv[1]);
                        if(kv[0].equals("lng")) lng = Double.parseDouble(kv[1]);
                    }
                }
            } catch(Exception e) {}
        }
        // 3. Door Commands (LOCK/UNLOCK)
        else if (topic.equals(TOPIC_DOOR_CMD)) {
            String cmd = new String(msg.getPayload());
            if(cmd.contains("UNLOCK")) {
                isLocked = false;
                addLog("DOOR STATUS: UNLOCKED");
                // Reset lock state after 5s locally
                new Timer().schedule(new TimerTask() { @Override public void run() { isLocked = true; } }, 5000);
            } else if (cmd.contains("LOCK")) {
                isLocked = true;
                addLog("DOOR STATUS: LOCKED (Security Alert)");
            }
        }
        // 4. Chat/AI Responses
        else if (topic.equals(TOPIC_CHAT_OUT)) {
            addLog("AI: " + new String(msg.getPayload()));
        }
    }

    // --- 2. WEB API ENDPOINTS ---

    // A. Video Stream (Accessed by HTML via <img> tag)
    @GetMapping(value = "/stream", produces = "image/jpeg")
    public byte[] getVideoStream() {
        return currentFrame;
    }

    // B. Dashboard Data (Polls status, logs, GPS)
    @GetMapping("/dashboard-data")
    public Map<String, Object> getDashboardData() {
        Map<String, Object> data = new HashMap<>();
        data.put("lat", lat);
        data.put("lng", lng);
        data.put("locked", isLocked);
        data.put("users", registeredUsers);
        
        List<String> recentLogs = new ArrayList<>(logs);
        Collections.reverse(recentLogs);
        data.put("logs", recentLogs.subList(0, Math.min(recentLogs.size(), 15)));
        
        return data;
    }

    // C. Register User Action
    @PostMapping("/register")
    public ResponseEntity<String> register(@RequestBody Map<String, String> body) {
        String name = body.get("name");
        registeredUsers++;
        addLog("Database: Identity Registered (" + name + ")");
        return ResponseEntity.ok("Success");
    }
    
    // D. Send Chat Command
    @PostMapping("/chat")
    public ResponseEntity<String> sendChat(@RequestBody Map<String, String> body) {
        String msg = body.get("message");
        addLog("User: " + msg);
        
        // Forward command to Python AI via MQTT
        try {
            if(mqttClient != null && mqttClient.isConnected()) {
                String json = "{\"message\": \"" + msg + "\"}";
                mqttClient.publish(TOPIC_CHAT_IN, new MqttMessage(json.getBytes()));
            }
        } catch(Exception e) {}
        
        return ResponseEntity.ok("Sent");
    }

    // Helper: Logging with Timestamp
    private void addLog(String msg) {
        String time = LocalDateTime.now().format(DateTimeFormatter.ofPattern("HH:mm:ss"));
        logs.add("[" + time + "] " + msg);
        if(logs.size() > 100) logs.remove(0);
    }
}
