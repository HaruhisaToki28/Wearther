"use strict";
/**
 * Wearther Cloud Functions
 *
 * AIファッションアドバイス生成機能
 * 天気データを受け取り、Google Gemini APIでアドバイスを生成して返却
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.generateFashionAdvice = void 0;
const https_1 = require("firebase-functions/v2/https");
const params_1 = require("firebase-functions/params");
const generative_ai_1 = require("@google/generative-ai");
// Gemini APIキーをSecret Managerから取得
const geminiApiKey = (0, params_1.defineSecret)("GEMINI_API_KEY");
/**
 * AIファッションアドバイス生成関数
 *
 * 使用方法（iOS側）:
 * let functions = Functions.functions()
 * let result = try await functions.httpsCallable("generateFashionAdvice").call(data)
 */
exports.generateFashionAdvice = (0, https_1.onCall)({
    // Secret Managerからキーを取得
    secrets: [geminiApiKey],
    // リージョンを東京に設定（レイテンシ低減）
    region: "asia-northeast1",
    // タイムアウトを30秒に設定
    timeoutSeconds: 30,
}, async (request) => {
    // リクエストデータの検証
    const data = request.data;
    if (!data.weather) {
        throw new https_1.HttpsError("invalid-argument", "天気データが必要です");
    }
    const { weather, userPreferences } = data;
    // Gemini クライアントの初期化
    const genAI = new generative_ai_1.GoogleGenerativeAI(geminiApiKey.value());
    // gemini-2.5-flash-lite は軽量で無料枠が広い
    const model = genAI.getGenerativeModel({ model: "gemini-2.5-flash-lite" });
    // プロンプトの構築
    const prompt = buildPrompt(weather, userPreferences);
    try {
        // Gemini API呼び出し
        const result = await model.generateContent(prompt);
        const response = result.response;
        const text = response.text();
        // JSONを抽出して解析
        const jsonMatch = text.match(/\{[\s\S]*\}/);
        if (!jsonMatch) {
            console.error("JSON not found in response:", text);
            return generateFallbackAdvice(weather);
        }
        const advice = JSON.parse(jsonMatch[0]);
        // バリデーション
        if (!advice.title || !advice.description) {
            console.error("Invalid response format:", advice);
            return generateFallbackAdvice(weather);
        }
        return {
            title: advice.title,
            description: advice.description,
        };
    }
    catch (error) {
        console.error("Gemini API Error:", error);
        // フォールバック: 気温ベースのデフォルトアドバイス
        return generateFallbackAdvice(weather);
    }
});
/**
 * プロンプトを構築
 */
function buildPrompt(weather, userPreferences) {
    let prompt = `あなたはファッションアドバイザーです。
天気情報に基づいて、その日のおすすめコーディネートを提案してください。

【重要な制約】
- タイトル: 具体的なアイテム名を含め、1行（20文字以内）で簡潔に
- キャプション: アドバイスを2行（60文字以内）で具体的に

【回答フォーマット】
必ず以下のJSON形式のみで回答してください。他の文章は不要です：
{"title": "タイトル", "description": "キャプション"}

【今日の天気】
- 地域: ${weather.location}
- 天気: ${weather.condition}
- 最高気温: ${weather.temperature}°C
- 最低気温: ${weather.minTemperature}°C
- 降水確率: ${weather.precipitationChance}%`;
    if (userPreferences) {
        prompt += `\n\n【ユーザー情報】`;
        if (userPreferences.gender) {
            prompt += `\n- 性別: ${userPreferences.gender}`;
        }
        if (userPreferences.temperatureTolerance) {
            prompt += `\n- 寒暖耐性: ${userPreferences.temperatureTolerance}`;
        }
    }
    return prompt;
}
/**
 * フォールバックアドバイス（API失敗時）
 */
function generateFallbackAdvice(weather) {
    const temp = weather.temperature;
    // 気温帯によるアドバイス
    if (temp >= 30) {
        return {
            title: "涼しげなTシャツとショートパンツを",
            description: "通気性の良い素材で暑さ対策。帽子や日傘で日差しを防ぎましょう",
        };
    }
    else if (temp >= 25) {
        return {
            title: "軽やかなシャツとボトムスで快適に",
            description: "薄手のトップスがおすすめ。室内の冷房対策に薄い羽織りもあると◎",
        };
    }
    else if (temp >= 20) {
        return {
            title: "長袖シャツや薄手のカーディガンを",
            description: "朝晩の寒暖差に対応できる重ね着スタイルがおすすめです",
        };
    }
    else if (temp >= 15) {
        return {
            title: "ライトアウターで季節の変わり目に対応",
            description: "ジャケットやパーカーを羽織って調節しやすいコーデを",
        };
    }
    else if (temp >= 10) {
        return {
            title: "コートやセーターを重ね着して暖かく",
            description: "風を通しにくいアウターやニットで暖かさをキープしましょう",
        };
    }
    else if (temp >= 5) {
        return {
            title: "厚手のコートとマフラーで防寒を",
            description: "ダウンジャケットやウールコートで本格的な防寒対策を",
        };
    }
    else {
        return {
            title: "しっかり防寒で真冬の寒さに備えて",
            description: "ダウン・手袋・マフラー・ニット帽でしっかり暖かく",
        };
    }
}
//# sourceMappingURL=index.js.map