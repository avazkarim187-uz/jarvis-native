package com.example.jarvis_app;

import android.Manifest;
import android.app.Activity;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.graphics.Typeface;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.speech.RecognitionListener;
import android.speech.RecognizerIntent;
import android.speech.SpeechRecognizer;
import android.speech.tts.TextToSpeech;
import android.view.Gravity;
import android.view.View;
import android.view.inputmethod.InputMethodManager;
import android.content.Context;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import android.widget.Toast;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Locale;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class MainActivity extends Activity {
    private static final int REQ_AUDIO = 1001;
    private static final String MODEL_URL =
            "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=";

    private final Handler main = new Handler(Looper.getMainLooper());
    private final ExecutorService io = Executors.newSingleThreadExecutor();

    private LinearLayout messages;
    private ScrollView scroll;
    private TextView status;
    private EditText input;
    private TextToSpeech tts;
    private SpeechRecognizer recognizer;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        buildUi();
        setupSpeech();
        setupTts();
        requestAudioIfNeeded();
    }

    private void buildUi() {
        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(dp(18), dp(16), dp(18), dp(12));
        root.setBackgroundColor(Color.rgb(5, 10, 15));

        TextView title = new TextView(this);
        title.setText("JARVIS");
        title.setTextColor(Color.rgb(0, 212, 255));
        title.setTextSize(24);
        title.setTypeface(Typeface.DEFAULT_BOLD);
        title.setGravity(Gravity.CENTER);
        title.setLetterSpacing(0.22f);
        root.addView(title, new LinearLayout.LayoutParams(-1, dp(42)));

        status = new TextView(this);
        status.setText("Ready");
        status.setTextColor(Color.rgb(140, 210, 225));
        status.setTextSize(14);
        status.setGravity(Gravity.CENTER);
        root.addView(status, new LinearLayout.LayoutParams(-1, dp(28)));

        scroll = new ScrollView(this);
        messages = new LinearLayout(this);
        messages.setOrientation(LinearLayout.VERTICAL);
        scroll.addView(messages);
        root.addView(scroll, new LinearLayout.LayoutParams(-1, 0, 1));

        LinearLayout controls = new LinearLayout(this);
        controls.setOrientation(LinearLayout.HORIZONTAL);
        controls.setGravity(Gravity.CENTER_VERTICAL);

        input = new EditText(this);
        input.setHint("Savol yozing...");
        input.setSingleLine(false);
        input.setMinLines(1);
        input.setMaxLines(4);
        input.setTextColor(Color.WHITE);
        input.setHintTextColor(Color.rgb(120, 130, 140));
        input.setTextSize(15);
        input.setBackgroundColor(Color.rgb(14, 25, 35));
        input.setPadding(dp(12), dp(8), dp(12), dp(8));
        controls.addView(input, new LinearLayout.LayoutParams(0, -2, 1));

        Button mic = button("Mic");
        mic.setOnClickListener(v -> listen());
        controls.addView(mic, new LinearLayout.LayoutParams(dp(70), dp(52)));

        Button send = button("Send");
        send.setOnClickListener(v -> sendFromInput());
        controls.addView(send, new LinearLayout.LayoutParams(dp(78), dp(52)));

        root.addView(controls, new LinearLayout.LayoutParams(-1, -2));
        setContentView(root);

        addMessage("Jarvis", "Jarvis tayyor. Savol yozing yoki Mic bosing.");
    }

    private Button button(String text) {
        Button b = new Button(this);
        b.setText(text);
        b.setTextColor(Color.rgb(0, 212, 255));
        b.setAllCaps(false);
        return b;
    }

    private void setupTts() {
        tts = new TextToSpeech(this, result -> {
            if (result == TextToSpeech.SUCCESS) {
                tts.setLanguage(new Locale("uz"));
            }
        });
    }

    private void setupSpeech() {
        if (!SpeechRecognizer.isRecognitionAvailable(this)) {
            status.setText("Speech unavailable");
            return;
        }
        recognizer = SpeechRecognizer.createSpeechRecognizer(this);
        recognizer.setRecognitionListener(new RecognitionListener() {
            @Override public void onReadyForSpeech(Bundle params) { status.setText("Listening..."); }
            @Override public void onBeginningOfSpeech() { }
            @Override public void onRmsChanged(float rmsdB) { }
            @Override public void onBufferReceived(byte[] buffer) { }
            @Override public void onEndOfSpeech() { status.setText("Processing..."); }
            @Override public void onError(int error) { status.setText("Ready"); }
            @Override public void onPartialResults(Bundle partialResults) { }
            @Override public void onEvent(int eventType, Bundle params) { }
            @Override public void onResults(Bundle results) {
                ArrayList<String> texts = results.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION);
                if (texts != null && !texts.isEmpty()) {
                    input.setText(texts.get(0));
                    sendFromInput();
                } else {
                    status.setText("Ready");
                }
            }
        });
    }

    private void requestAudioIfNeeded() {
        if (checkSelfPermission(Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            requestPermissions(new String[]{Manifest.permission.RECORD_AUDIO}, REQ_AUDIO);
        }
    }

    private void listen() {
        requestAudioIfNeeded();
        if (recognizer == null) {
            Toast.makeText(this, "Mikrofon ishlamadi", Toast.LENGTH_SHORT).show();
            return;
        }
        Intent intent = new Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH);
        intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM);
        intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE, Locale.getDefault());
        intent.putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, false);
        recognizer.startListening(intent);
    }

    private void sendFromInput() {
        String text = input.getText().toString().trim();
        if (text.isEmpty()) return;
        input.setText("");
        hideKeyboard();
        addMessage("Siz", text);
        askGemini(text);
    }

    private void askGemini(String text) {
        if (BuildConfig.GEMINI_API_KEY == null || BuildConfig.GEMINI_API_KEY.trim().isEmpty()) {
            addMessage("Jarvis", "Gemini API key sozlanmagan. GitHub Secrets ichiga GEMINI_API_KEY qo'shing.");
            return;
        }
        status.setText("Thinking...");
        io.execute(() -> {
            String answer;
            try {
                answer = callGemini(text);
            } catch (Exception e) {
                answer = "Xatolik: " + e.getMessage();
            }
            String finalAnswer = answer;
            main.post(() -> {
                status.setText("Ready");
                addMessage("Jarvis", finalAnswer);
                speak(finalAnswer);
            });
        });
    }

    private String callGemini(String userText) throws Exception {
        JSONObject root = new JSONObject();
        JSONArray contents = new JSONArray();
        JSONObject content = new JSONObject();
        JSONArray parts = new JSONArray();

        String prompt = "Sen JARVIS shaxsiy AI yordamchisan. Qisqa, aniq va foydali javob ber. "
                + "Foydalanuvchi qaysi tilda yozsa, shu tilda javob ber.\n\nSavol: " + userText;
        parts.put(new JSONObject().put("text", prompt));
        content.put("parts", parts);
        contents.put(content);
        root.put("contents", contents);

        URL url = new URL(MODEL_URL + BuildConfig.GEMINI_API_KEY);
        HttpURLConnection conn = (HttpURLConnection) url.openConnection();
        conn.setRequestMethod("POST");
        conn.setConnectTimeout(20000);
        conn.setReadTimeout(30000);
        conn.setDoOutput(true);
        conn.setRequestProperty("Content-Type", "application/json; charset=UTF-8");

        try (OutputStream os = conn.getOutputStream()) {
            os.write(root.toString().getBytes(StandardCharsets.UTF_8));
        }

        int code = conn.getResponseCode();
        InputStream stream = code >= 200 && code < 300 ? conn.getInputStream() : conn.getErrorStream();
        String body = readAll(stream);
        if (code < 200 || code >= 300) {
            return "Gemini javob bermadi (" + code + "): " + body;
        }

        JSONObject json = new JSONObject(body);
        JSONArray candidates = json.optJSONArray("candidates");
        if (candidates == null || candidates.length() == 0) return "Javob topilmadi.";
        JSONObject first = candidates.getJSONObject(0).getJSONObject("content");
        JSONArray resultParts = first.getJSONArray("parts");
        return resultParts.getJSONObject(0).optString("text", "Javob bo'sh keldi.");
    }

    private String readAll(InputStream stream) throws Exception {
        if (stream == null) return "";
        StringBuilder sb = new StringBuilder();
        try (BufferedReader br = new BufferedReader(new InputStreamReader(stream, StandardCharsets.UTF_8))) {
            String line;
            while ((line = br.readLine()) != null) sb.append(line);
        }
        return sb.toString();
    }

    private void addMessage(String who, String text) {
        TextView view = new TextView(this);
        view.setText(who + ": " + text);
        view.setTextColor("Siz".equals(who) ? Color.WHITE : Color.rgb(0, 212, 255));
        view.setTextSize(15);
        view.setPadding(dp(12), dp(10), dp(12), dp(10));
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(-1, -2);
        lp.setMargins(0, dp(6), 0, dp(6));
        messages.addView(view, lp);
        scroll.post(() -> scroll.fullScroll(View.FOCUS_DOWN));
    }

    private void speak(String text) {
        if (tts != null) {
            tts.speak(text, TextToSpeech.QUEUE_FLUSH, null, "jarvis-answer");
        }
    }

    private void hideKeyboard() {
        InputMethodManager imm = (InputMethodManager) getSystemService(Context.INPUT_METHOD_SERVICE);
        if (imm != null) imm.hideSoftInputFromWindow(input.getWindowToken(), 0);
    }

    private int dp(int value) {
        return (int) (value * getResources().getDisplayMetrics().density + 0.5f);
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (recognizer != null) recognizer.destroy();
        if (tts != null) {
            tts.stop();
            tts.shutdown();
        }
        io.shutdownNow();
    }
}
